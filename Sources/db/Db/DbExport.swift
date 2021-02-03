//
//  DbConverter.swift
//  db
//
//  Created by Joeri van Veen on 09/01/2021.
//

import Foundation

struct DbExport {
    
    static func toXml () -> String {
        return XmlParser.write(Db.records)
    }
    
    static func toJson () -> String {
        return JsonParser.write(Db.records)
    }
    
    static func toTxt () -> String {
        return Db.records.map { record -> String in
            return record.map { entry -> String in
                var (field, value) = entry
                value = value.escaped([.backslashes, .lineEndings])
                return "\(field): \(value)"
            }.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
    
    static func toCsv (useTabs tabs:Bool = false) -> String {
        let separator = tabs ? "\t" : ","
        let header = Db.fields.joined(separator: separator)
        
        return header + "\n" + Db.records.map { record in
            return Db.fields.map { field in
                return (record[field] ?? "").csvEscaped(for: separator)
            }.joined(separator: separator)
        }.joined(separator: "\n")
    }
    
    static func toPhp (useShortSyntax: Bool) -> String {
        let start = useShortSyntax ? "[" : "array("
        let end = useShortSyntax ? "]" : ")"
        return start + "\n" + Db.records.map { record -> String in
            return "\t" + start + "\n" + record.map { field, value -> String in
                return "\t\t\"\(field)\" => \"\(value.escaped([.backslashes, .lineEndings, .doubleQuotes]))\""
            }.joined(separator: ",\n")
        }.joined(separator: "\n\t" + end + ",\n") + "\n\t\(end)\n\(end);"
    }
    
    static func toList () -> String {
        return Db.records.map { record -> String in
            return record.values.joined(separator: "\n")
        }.joined(separator: "\n")
    }
    
}
