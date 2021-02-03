//
//  View.swift
//  db
//
//  Created by Joeri van Veen on 04/01/2021.
//

import Foundation
import ArgumentParser

struct As: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Export data into various formats.")
    
    @Argument(help: "Output format", completion: .list(["xml", "json", "csv", "txt"]))
    private var format: String
    
    @Flag(help: "Tab delimited (csv)")
    private var tabs: Bool = false
    
    @Flag(help: "Shortened array syntax (php)")
    private var short: Bool = false
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run() throws {
        
        do {
            
            try Db.read()
            let output = try Db.export(as: format, useTabs: tabs, useShortSyntax: short)
            
            print(output)
            
        } catch Cannot.readDatabase {
            ErrorMessage.show(Cannot.readDatabase, includeVerboseMessage: !verbose)
            
        } catch Unsupported.outputFormat(let type) {
            ErrorMessage.show(Unsupported.outputFormat(type))
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
}
