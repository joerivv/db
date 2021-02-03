//
//  Generate.swift
//  db
//
//  Created by Joeri van Veen on 04/01/2021.
//

import Foundation
import ArgumentParser

struct Stats: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "View database statistics.")
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run () throws {
        
        do {
            
            let m = try measure {
                try Db.read()
            }
            
            let fileSize = try? Db.getFileSize()
            
            print("Name:       \(Db.name)")
            print("Path:       \(Db.path)")
            print("State:      \(Db.isCompressed ? "Compressed" : "Uncompressed")")
            print("File size:  \(fileSize ?? "Couldn't retrieve file size.")")
            print("Records:    \(Db.recordCount)")
            print("Read time:  \(m.elapsedTime)")
            print("Fields:     \(Db.fields.joined(separator: ", ")) (\(Db.fields.count))")
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }

}
