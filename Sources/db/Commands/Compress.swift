//
//  Compress.swift
//  db
//
//  Created by Joeri van Veen on 09/01/2021.
//

import Foundation
import ArgumentParser
import SQLite3

struct Compress: ParsableCommand {
    
    public static let configuration = CommandConfiguration(abstract: "More efficient for large databases.")
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    @Option(name: .shortAndLong, help: "Records per bulk insert (defaults to 1,000)")
    private var bulk: Int = 1000
    
    func run () throws {
        
        var pathXmlDb = ""
        
        do {
            print("Reading database…")
            
            try Db.read()
            
            if Db.isCompressed {
                throw Warn.alreadyCompressed
            }
            
            print("Compressing…")
            
            pathXmlDb = Db.path.replacingOccurrences(of: ".xml", with: ".xmldb")
            
            try Sqlite.openDatabase(path: pathXmlDb)
            try Sqlite.createTable(name: "data", fields: Db.fields)
            try Sqlite.write(Db.records, to: "data", usingFields: Db.fields, showProgress: true, bulk: bulk)
            
            printo("Compressing…")
            
            try? FileManager.default.removeItem(atPath: Db.path)
            
            print("Done!")
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
            
        } catch Warn.alreadyCompressed {
            ErrorMessage.show(Warn.alreadyCompressed)
            
        } catch {
            Db.internalError = error
            ErrorMessage.show(Cannot.compressDatabase, includeVerboseMessage: !verbose)
            try? FileManager.default.removeItem(atPath: pathXmlDb)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
    
}
