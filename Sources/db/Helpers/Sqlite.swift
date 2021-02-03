//
//  Sqlite.swift
//  db
//
//  Created by Joeri van Veen on 11/01/2021.
//

import Foundation
import SQLite3

enum StatementHandling {
    case none
    case reset
    case finalize
}

struct Sqlite {
    
    static private var db: OpaquePointer?
    static private var transactionStatement: OpaquePointer? = nil
    static private var commitStatement: OpaquePointer? = nil
    static private var isRunningTransaction: Bool = false
    static private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    static func openDatabase (path: String) throws {
        if sqlite3_open(path, &db) != SQLITE_OK {
            throw SqliteFailed.toConnect
        }
    }
    
    static func createTable (name: String, fields: [String]) throws {
        try run("CREATE TABLE \"\(name)\" (\(fields.map { "\"\($0)\" TEXT" }.joined(separator: ", ")))", SqliteFailed.toCreateTable)
    }
    
    static func dropTable (name: String) throws {
        try run("DROP TABLE \"\(name)\"", SqliteFailed.toDropTable)
    }
    
    static func rename (oldTable: String, newTable: String) throws {
        try run("ALTER TABLE \"\(oldTable)\" RENAME TO \"\(newTable)\"", SqliteFailed.toRenameTable)
    }
    
    static func write (
        _ records: [[String:String]],
        to table: String,
        usingFields fields: [String],
        showProgress: Bool,
        bulk: Int = 1000) throws {
        
        let values = String(repeating: "?,", count: fields.count - 1) + "?"
        let fieldsListed = fields.map { "\"\($0)\"" }.joined(separator: ", ")
        let insertStatement = try prepare("INSERT INTO \"\(table)\" (\(fieldsListed)) VALUES (\(values))", SqliteFailed.toInsertRecords)
        var recordIndex = 0
        
        for record in records {
            
            if recordIndex % bulk == 0 && bulk != 1 {
                try commitTransaction(SqliteFailed.toInsertRecords)
                try beginTransaction(SqliteFailed.toInsertRecords)
            }
            
            fill(insertStatement, withRecord: record, usingFields: fields)
            
            try step(insertStatement, SqliteFailed.toInsertRecords, handling: .reset)
            
            if showProgress && recordIndex % 100 == 0 {
                printo("Compressing… (\(Int(round(Double(recordIndex) / Double(records.count) * 100)))%)")
            }
            
            recordIndex = recordIndex + 1
        }
        
        if bulk != 1 {
            try commitTransaction(SqliteFailed.toInsertRecords)
            sqlite3_finalize(transactionStatement)
            sqlite3_finalize(commitStatement)
        }
        
        sqlite3_finalize(insertStatement)
    }
    
    static func read (
        _ table: String,
        into records: inout [Record],
        fields: inout [String]) throws {
        
        let selection = "SELECT * FROM \"\(table)\""
        let selectionStatement = try prepare(selection, SqliteFailed.toSelectRecords)
        
        let fieldCount = sqlite3_column_count(selectionStatement)
        for index in 0..<fieldCount {
            let columnName = sqlite3_column_name(selectionStatement, index)!
            fields.append(String(cString: columnName))
        }
        
        var record: Record
        
        while fetch(selectionStatement) {
            record = [:]
            for index in 0..<fields.count {
                guard let value = sqlite3_column_text(selectionStatement, Int32(index)) else { continue }
                record[fields[index]] = String(cString: value)
            }
            records.append(record)
        }
        
        sqlite3_finalize(selectionStatement)
    }
    
    static var lastError: String {
        return String(cString: sqlite3_errmsg(db))
    }
    
    static private func beginTransaction (_ error: Error) throws {
        if isRunningTransaction {
            return
        }
        
        let transactionQuery = "BEGIN EXCLUSIVE TRANSACTION"
        transactionStatement = try prepare(transactionQuery, error)
        
        try step(transactionStatement, error, handling: .reset)
        
        isRunningTransaction = true
    }
    
    static private func commitTransaction (_ error: Error) throws {
        if !isRunningTransaction {
            return
        }
        
        let commitQuery = "COMMIT TRANSACTION"
        commitStatement = try prepare(commitQuery, error)
        
        try step(commitStatement, error, handling: .reset)
        
        isRunningTransaction = false
    }
    
    static private func prepare (_ script: String, _ error: Error) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, script, -1, &statement, nil) != SQLITE_OK {
            throw error
        }
        
        return statement
    }
    
    static private func run (_ script: String, _ error: Error) throws {
        let statement = try prepare(script, error)
        try step(statement, error, handling: .finalize)
    }
    
    static private func step (
        _ statement: OpaquePointer?,
        _ error: Error,
        handling: StatementHandling) throws {
        
        if sqlite3_step(statement) != SQLITE_DONE {
            throw error
        }
        
        if handling == .finalize {
            sqlite3_finalize(statement)
        }
        
        if handling == .reset {
            sqlite3_reset(statement)
        }
    }
    
    static private func fetch (_ statement: OpaquePointer?) -> Bool {
        return sqlite3_step(statement) == SQLITE_ROW
    }
    
    static private func fill (
        _ statement: OpaquePointer?,
        withRecord record: [String:String],
        usingFields fields: [String]) {
        
        var fieldCount: Int32 = 0
        
        for field in fields {
            fieldCount += 1
            if let value = record[field] {
                sqlite3_bind_text(statement, fieldCount, value, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, fieldCount)
            }
        }
    }
}
