//
//  Delete.swift
//  db
//
//  Created by Joeri van Veen on 19/01/2021.
//

import Foundation
import ArgumentParser
import HttpSwift

struct Delete: ParsableCommand {
    
    public static let configuration = CommandConfiguration(abstract: "Delete fields and records.")
    
    @Flag(name: .shortAndLong, help: "Delete everything.")
    private var all: Bool = false
    
    @Flag(name: .shortAndLong, help: "Delete duplicates.")
    private var duplicates: Bool = false
    
    @Option(name: .shortAndLong, help: "Delete records conditionally.")
    private var `where`: String = ""
    
    @Option(name: .shortAndLong, help: "Delete a field from every record that has it.")
    private var field: String = ""
    
    @Flag(name: .long, help: "Provide to skip question")
    private var sure: Bool = false
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run () throws {
        
        do {
            
            if all {
                if DbDelete.all(askToConfirm: !sure) {
                    try Db.write()
                }
            }
            
            try Db.read()
            
            if duplicates {
                if DbDelete.duplicates(askToConfirm: !sure) {
                    try Db.write()
                }
            }
            
            if `where` != "" {
                DbDelete.where(Url.decode(`where`))
                try Db.write()
            }
            
            if field != "" {
                DbDelete.field(field)
                try Db.write()
            }
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
            
        } catch Cannot.saveDatabase {
            ErrorMessage.show(Cannot.saveDatabase, includeVerboseMessage: !verbose)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
    
}
