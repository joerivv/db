//
//  Parse.swift
//  db
//
//  Created by Joeri van Veen on 11/01/2021.
//

import Foundation
import ArgumentParser

struct Decompress: ParsableCommand {
    
    public static let configuration = CommandConfiguration(abstract: "Make it a plain xml database.")
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run () throws {
        
        do {
            
            let fm = FileManager.default
            
            try Db.read()
            
            fm.createFile(
                atPath: fm.currentDirectoryPath + "/" + Db.name + ".xml",
                contents: Db.initialSchema(Db.name),
                attributes: nil)
            
            try Db.writeUncompressed()
            try fm.removeItem(atPath: Db.path)
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
            
        } catch Cannot.saveDatabase {
            ErrorMessage.show(Cannot.saveDatabase, includeVerboseMessage: !verbose)
        
        } catch {
            Db.internalError = error
            ErrorMessage.showInternalError()
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
}
