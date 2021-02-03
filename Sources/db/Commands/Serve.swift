//
//  Serve.swift
//  db
//
//  Created by Joeri van Veen on 14/01/2021.
//

import Foundation
import ArgumentParser
import Dispatch
import HttpSwift

struct Serve: ParsableCommand {
    
    public static let configuration = CommandConfiguration(abstract: "Start small server to allow external requests.")
    
    @Option(name: .shortAndLong, help: "Address (default: localhost)")
    private var address: String = "localhost"
    
    @Option(name: .shortAndLong, help: "Port (default: 7777)")
    private var port: UInt16 = 7777
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run () throws {
        
        do {
            
            let semaphore = DispatchSemaphore(value: 0)
            try Http.run(address: address, port: port)
            print("Serving \(Db.name) on http://\(address):\(port)/")
            semaphore.wait()
            
        } catch Cannot.runServer {
            ErrorMessage.show(Cannot.runServer, includeVerboseMessage: !verbose)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
}
