//
//  Db.swift
//  db
//
//  Created by Joeri van Veen on 08/01/2021.
//

import Foundation

public typealias Record = [String : String]

struct Db {
    
    static private let fm = FileManager.default
    static public var name: String = ""
    static public var path: String = ""
    static public var internalError: Error?
    static public var isCompressed: Bool = false
    static public var records: [[String: String]] = []
    static public var fields: [String] = []
    static private let forbiddenFieldCharacters = try! NSRegularExpression(pattern: "(^[0-9]+|[^a-z0-9\\-])", options: [.caseInsensitive, .anchorsMatchLines])
    
    static func createIfNotExists (_ databaseName: String = CommandLine.arguments[1]) {
        
        name = databaseName
        
        let pathXml = "\(fm.currentDirectoryPath)/\(name).xml"
        let pathXmlDb = "\(fm.currentDirectoryPath)/\(name).xmldb"
        
        isCompressed = fm.fileExists(atPath: pathXmlDb)
        
        if !fm.fileExists(atPath: pathXml) && !isCompressed {
            fm.createFile(atPath: pathXml, contents: initialSchema(name), attributes: nil)
            name = databaseName
        }
        
        path = isCompressed ? pathXmlDb : pathXml
        
    }
    
    static func read () throws {
        do {
            if isCompressed {
                try readCompressed()
            } else {
                try readUncompressed()
            }
        } catch {
            Db.internalError = error
            throw Cannot.readDatabase
        }
    }
    
    static func write () throws {
        do {
            if isCompressed {
                try writeCompressed()
            } else {
                try writeUncompressed()
            }
        } catch {
            Db.internalError = error
            throw Cannot.saveDatabase
        }
    }
    
    static private func readCompressed () throws {
        try Sqlite.openDatabase(path: path)
        try Sqlite.read("data", into: &records, fields: &fields)
    }
    
    static private func readUncompressed () throws {
        try XmlParser.read(fromFile: path, into: &records, fields: &fields)
    }
    
    static func writeCompressed () throws {
        
        let path = fm.currentDirectoryPath + "/" + name + ".xmldb"
        
        Db.fields = Db.records.flatMap({ $0.keys }).unique()
        
        try Sqlite.openDatabase(path: path)
        try Sqlite.createTable(name: "new-data", fields: Db.fields)
        try Sqlite.write(Db.records, to: "new-data", usingFields: Db.fields, showProgress: false)
        try Sqlite.dropTable(name: "data")
        try Sqlite.rename(oldTable: "new-data", newTable: "data")
        
    }
    
    static func writeUncompressed () throws {
        
        do {
            try XmlParser.write(records, toFile: fm.currentDirectoryPath + "/" + name + ".xml")
        } catch {
            throw Cannot.saveDatabase
        }
        
    }
    
    static func `import` (fromFile path: String, withType type: String? = nil) throws {
        
        do {
            
            let fileType = type ?? NSString(utf8String: path)?.pathExtension ?? ""
            
            switch fileType {
                case "xml": try DbImport.fromXml(file: path)
                case "csv": try DbImport.fromCsv(file: path, forceInterpretCommas: type == "csv")
                case "tsv": try DbImport.fromTsv(file: path)
                case "json": try DbImport.fromJson(file: path)
                case "xlsx": try DbImport.fromXlsx(file: path)
                case "txt":
                    let fileContents = try String(contentsOfFile: path)
                    return try Db.import(fromString: fileContents, ofType: StringParser.figureOutDataType(fileContents))
                default: throw Unsupported.inputFileFormat(fileType)
            }
            
        } catch Unsupported.inputFileFormat(let format) {
            throw Unsupported.inputFileFormat(format)
            
        } catch {
            Db.internalError = error
            throw Cannot.importFile(path)
        }
        
    }
    
    static func `import` (fromString string: String, ofType type: String) throws {
        
        do {
            
            switch type {
                case "value": DbImport.fromValue(string: string)
                case "csv": try DbImport.fromCsv(string: string, forceDelimiter: ",")
                case "tsv": try DbImport.fromCsv(string: string, forceDelimiter: "\t")
                case "json": try DbImport.fromJson(string: string)
                case "xml": DbImport.fromXml(string: string)
                case "list": DbImport.fromList(string)
                default: throw Unsupported.inputFormat(type)
            }
            
        } catch Unsupported.inputFormat(let type) {
            throw Unsupported.inputFormat(type)
            
        }  catch {
            Db.internalError = error
            throw Cannot.importData
        }
        
    }
    
    static func export (as format: String, useTabs: Bool, useShortSyntax: Bool) throws -> String {
        switch format {
            case "xml": return DbExport.toXml()
            case "json": return DbExport.toJson()
            case "txt": return DbExport.toTxt()
            case "csv": return DbExport.toCsv(useTabs: useTabs)
            case "tsv": return DbExport.toCsv(useTabs: true)
            case "php": return DbExport.toPhp(useShortSyntax: useShortSyntax)
            case "list": return DbExport.toList()
            default: throw Unsupported.outputFormat(format)
        }
    }
    
    static func getFileSize () throws -> String {
        var bytes: UInt64 = 0
        
        do {
            bytes = try fm.attributesOfItem(atPath: path)[.size] as! UInt64
        } catch {
            throw Cannot.retrieveFileSize
        }
        
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    static var recordCount: String {
        return NumberFormatter.localizedString(from: NSNumber(value: records.count), number: .decimal)
    }
    
    static func add (_ record: inout Record) {
        
        for (field, value) in record {
            
            let transformedField = guaranteeValidField(field)
            if transformedField != field {
                record[transformedField] = value
                record[field] = nil
            }
            
        }
        
        records.append(record)
    }
    
    static func delete (_ record: Record) {
        let index = records.firstIndex(of: record)
        if index != nil {
            records.remove(at: index!)
        }
    }
    
    static func guaranteeValidField (_ field: String) -> String {
        var transformedField = field
        
        transformedField = field.replacingOccurrences(of: " ", with: "-")
        transformedField = forbiddenFieldCharacters.stringByReplacingMatches(
            in: transformedField,
            options: [],
            range: NSMakeRange(0, transformedField.count),
            withTemplate: "")
        
        if transformedField == "" {
            transformedField = inventFields(howMany: 1)[0]
        }
        
        return transformedField
    }
    
    static func verifyFieldValidity (_ field: String) throws {
        if forbiddenFieldCharacters.firstMatch(in: field, options: [], range: NSRange(location: 0, length: field.count)) != nil || field == "" {
            throw Invalid.fieldName(field)
        }
    }
    
    static func inventFields (howMany: Int) -> [String] {
        var fields: [String] = []
        
        for i in fields.count..<howMany {
            fields.append("field\(i + 1)")
        }
        
        return fields
    }
    
    static func initialSchema (_ database: String) -> Data {
        return XmlParser.write([]).data(using: .utf8)!
    }
}
