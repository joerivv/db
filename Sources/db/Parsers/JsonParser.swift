//
//  JsonParser.swift
//  db
//
//  Created by Joeri van Veen on 18/01/2021.
//

import Foundation

struct JsonParser {
    
    static func read (fromString data: String) throws -> [Record] {
        let isArray = data.first == "["
        var records: [Record] = []
        if let json = try? JSONSerialization.jsonObject(with: Data(data.utf8), options: [.allowFragments]) {
            if isArray {
                if let recordsArray = json as? [Any] {
                    for case let record as [String : Any] in recordsArray {
                        records.append(sanitiseRecord(record))
                    }
                } else {
                    throw Invalid.json
                }
            } else {
                if let recordObject = json as? [String : Any] {
                    records.append(sanitiseRecord(recordObject))
                } else {
                    throw Invalid.json
                }
            }
        } else {
            throw Invalid.json
        }
        return records
    }
    
    static func write (_ records: [Record]) -> String {
        let json = try! JSONSerialization.data(withJSONObject: records, options: .prettyPrinted)
        return String(data: json, encoding: .utf8)!
    }
    
    static private func sanitiseRecord(_ record: [String : Any]) -> Record {
        var sanitisedRecord: Record = [:]
        for (field, value) in record {
            sanitisedRecord[field] = "\(value)"
        }
        return sanitisedRecord
    }
}
