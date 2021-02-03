//
//  Rename.swift
//  db
//
//  Created by Joeri van Veen on 19/01/2021.
//

import Foundation
import ArgumentParser

struct Rename: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Rename field names.")
    
    @Argument(help: "Old field")
    private var old: String
    
    @Argument(help: "New field")
    private var new: String
    
    @Flag(help: "Force rename, even if field already exists.")
    private var force: Bool = false
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run() throws {
        
        do {
            
            try Db.read()
            try Db.verifyFieldValidity(old)
            try Db.verifyFieldValidity(new)
            
            if fieldsWouldBeOverwritten() && !force {
                throw Warn.fieldsWillBeOverwritten
            }
            
            for i in Db.records.indices {
                if Db.records[i][old] != nil {
                    Db.records[i][new] = Db.records[i][old]!
                    Db.records[i][old] = nil
                }
            }
            
            try Db.write()
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
            
        } catch Invalid.fieldName(let name) {
            ErrorMessage.show(Invalid.fieldName(name))
            
        } catch Warn.fieldsWillBeOverwritten {
            ErrorMessage.show(Warn.fieldsWillBeOverwritten)
            
        } catch Cannot.saveDatabase {
            ErrorMessage.show(Cannot.saveDatabase, includeVerboseMessage: !verbose)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
    
    func fieldsWouldBeOverwritten () -> Bool {
        return Db.records.contains(where: { record in record[old] != nil && record[new] != nil })
    }
}
