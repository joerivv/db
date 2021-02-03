//
//  DbDelete.swift
//  db
//
//  Created by Joeri van Veen on 24/01/2021.
//

import Foundation

struct DbDelete {
    
    static func all (askToConfirm: Bool) -> Bool {
        if askToConfirm {
            print("This will empty the database. Continue? [Y|n]:")
            if readLine() != "Y" {
                return false
            }
        }
        
        Db.records = []
        return true
    }
    
    static func duplicates (askToConfirm: Bool) -> Bool {
        let indicesToRemove = pinpointIndicesOfDuplicates(in: Db.records)
        
        if askToConfirm {
            let deleteCount = indicesToRemove.count
            print("This will delete \(deleteCount) \(deleteCount == 1 ? "record" : "records"). Continue? [Y|n]")
            if readLine() != "Y" {
                return false
            }
        }
        
        for index in indicesToRemove.reversed() {
            Db.records.remove(at: index)
        }
        
        return true
    }
    
    static func `where` (_ conditions: [String: String]) {
        for record in Db.records {
            let shouldDelete = conditions.allSatisfy({ field, value in
                return record[field] == value || record[field] != nil && value == ""
            })
            if shouldDelete {
                Db.delete(record)
            }
        }
    }
    
    static func field (_ fieldName: String) {
        for (index, record) in Db.records.enumerated().reversed() {
            if record[fieldName] != nil {
                Db.records[index][fieldName] = nil
            }
            
            if Db.records[index].keys.count == 0 {
                Db.records.remove(at: index)
            }
        }
    }
    
    static private func calculateHashes (_ records: [Record]) -> [Int] {
        return records.map { record -> Int in
            var hasher = Hasher()
            record.hash(into: &hasher)
            return hasher.finalize()
        }
    }
    
    static private func pinpointIndicesOfDuplicates (in records: [Record]) -> [Int] {
        let hashes = calculateHashes(records)
        let dupes = hashes.duplicates()
        var encounters: [Int: Int] = [:]
        var indicesToRemove: [Int] = []
        
        for (index, hash) in hashes.enumerated() {
            if dupes.contains(hash) {
                if (encounters[hash] == nil) {
                    encounters[hash] = 0
                }
                if encounters[hash]! > 0 {
                    indicesToRemove.append(index)
                }
                encounters[hash]! += 1
            }
        }
        
        return indicesToRemove
    }
    
}
