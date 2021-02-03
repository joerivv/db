//
//  DbImport.swift
//  db
//
//  Created by Joeri van Veen on 09/01/2021.
//

import Foundation

struct DbImport {
    
    static func fromJson  (file path: String) throws {
        let fileContents = try String(contentsOfFile: path)
        try fromJson(string: fileContents)
    }
    
    static func fromJson (string: String) throws {
        let records = try JsonParser.read(fromString: string)
        for var record in records {
            Db.add(&record)
        }
    }
    
    static func fromCsv (file path: String, forceInterpretCommas: Bool = false) throws {
        let fileContents = try String(contentsOfFile: path)
        try fromCsv(string: fileContents, forceDelimiter: forceInterpretCommas ? "," : nil)
    }
    
    static func fromCsv (string: String, forceDelimiter: Character? = nil) throws {
        let records = Csv.read(fromString: string, forceDelimiter: forceDelimiter)
        for var record in records {
            Db.add(&record)
        }
    }
    
    static func fromTsv (file path: String) throws {
        let fileContents = try String(contentsOfFile: path)
        try fromCsv(string: fileContents, forceDelimiter: "\t")
    }
    
    static func fromTsv (string: String) throws {
        try fromCsv(string: string, forceDelimiter: "\t")
    }
    
    static func fromXlsx (file path: String) throws {
        let records = try ExcelParser.read(fromFile: path)
        for var record in records {
            Db.add(&record)
        }
    }
    
    static func fromValue (string: String) {
        var record = ["field": string]
        Db.add(&record)
    }
    
    static func fromXml (file path: String) throws {
        try XmlParser.read(fromFile: path, into: &Db.records, fields: &Db.fields)
    }
    
    static func fromXml (string: String) {
        XmlParser.read(fromString: string, into: &Db.records, fields: &Db.fields)
    }
    
    static func fromList (_ data: String) {
        data.split(separator: "\n").forEach { row in
            var record = ["field": "\(row)"]
            Db.add(&record)
        }
    }
    
}
