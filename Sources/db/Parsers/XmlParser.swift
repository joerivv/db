//
//  Xml.swift
//  db
//
//  Created by Joeri van Veen on 13/01/2021.
//

import Foundation

struct XmlParser {
    
    static func read (
        fromFile path: String,
        into records: inout [Record],
        fields: inout [String]) throws {
        
        do {
            let stream = try String(contentsOfFile: path)
            read(fromString: stream, into: &records, fields: &fields)
        } catch {
            throw Cannot.readDatabase
        }
    }
    
    static func read (
        fromString stream: String,
        into records: inout [Record],
        fields: inout [String]) {
        
        var inTag = false
        var inRecord = false
        var inField = false
        var inClosingTag = false
        var tagBegin = stream.startIndex
        var tagEnd = stream.startIndex
        var fieldBegin = stream.startIndex
        var fieldEnd = stream.startIndex
        var tagName: Substring
        var record: Record = [:]
        var uniqueFields: [String : Bool] = [:]
        
        for index in stream.indices {
            switch stream[index] {
                case "<":
                    inTag = true
                    tagBegin = stream.index(index, offsetBy: 1)
                    
                    if inField {
                        fieldEnd = index
                        inField = false
                    }
                case ">":
                    tagEnd = index
                    tagName = stream[tagBegin..<tagEnd]
                    
                    if tagName == "record" {
                        if inClosingTag {
                            inRecord = false
                            records.append(record)
                            record = [:]
                        } else {
                            inRecord = true
                        }
                    } else if inRecord {
                        if inClosingTag {
                            record[String(tagName)] = String(stream[fieldBegin..<fieldEnd]).xmlUnescaped()
                            uniqueFields[String(tagName)] = true
                        } else {
                            fieldBegin = stream.index(index, offsetBy: 1)
                            inField = true
                        }
                    }
                    
                    inTag = false
                    inClosingTag = false
                case "?": fallthrough
                case "/":
                    if inTag {
                        inClosingTag = true
                        tagBegin = stream.index(index, offsetBy: 1)
                    }
                default: continue
            }
        }
        
        fields = uniqueFields.keys.sorted()
    }
    
    static func write (_ records: [Record]) -> String {
        let header = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
        let recordString = records.map(wrapRecord).joined(separator: "\n")
        return "\(header)\n<database>\n\t<data>\n\(recordString)\n\t</data>\n</database>"
    }
    
    static func write (_ records: [Record], toFile path: String) throws {
        let xml = write(records)
        try xml.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
    }
    
    static private func wrapField (_ field: String, _ value: String) -> String {
        return "\t\t\t<\(field)>\(value.xmlEscaped())</\(field)>"
    }
    
    static private func wrapRecord (_ record: Record) -> String {
        return "\t\t<record>\n" + record.map(wrapField).joined(separator: "\n") + "\n\t\t</record>"
    }
}
