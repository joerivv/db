//
//  Server.swift
//  db
//
//  Created by Joeri van Veen on 19/01/2021.
//

import Foundation
import HttpSwift

struct Http {
    static func run (address: String, port: UInt16) throws {
        let server = Server()
        
        server.get("/", handler: allRecords)
        server.get("/coffee") { _ in Http.imATeapot() }
        server.get("/as/{format}", handler: allRecords)
        server.post("/") { try addRecords($0, replacing: false) }
        server.put("/") { try addRecords($0, replacing: true) }
        server.options("/") { _ in Http.ok() }
        server.delete("/", handler: deleteRecords)
        
        do {
            try server.run(port: port, address: address, certifiatePath: .none)
        } catch {
            throw Cannot.runServer
        }
    }
    
    static func allRecords (_ request: Request) throws -> Response {
        
        do {
            
            try Db.read()
            
            let format = request.routeParams["format"] ?? "json"
            let response = try Db.export(as: format, useTabs: false, useShortSyntax: false)
            
            return Http.ok(response, contentType: format)
            
        } catch Cannot.readDatabase {
            return Http.internalServerError()
            
        } catch Unsupported.outputFormat(let format) {
            return Http.badRequest("Format \(format) is not supported.")
        }
        
    }
    
    static func deleteRecords (_ request: Request) throws -> Response {
        
        do {
            
            try Db.read()
            DbDelete.where(request.queryParams)
            try Db.write()
            
            return Http.ok()
            
        } catch {
            return Http.internalServerError()
        }
        
    }
    
    static func addRecords (_ request: Request, replacing: Bool = false) throws -> Response {
        
        do {
            
            try Db.read()
            
            let data = String(bytes: request.body, encoding: .utf8)!
            let type = request.routeParams["type"] ?? StringParser.figureOutDataType(data)
            
            try Db.import(fromString: data, ofType: type)
            try Db.write()
            
            return Http.ok()
            
        } catch Cannot.importData {
            
            do {
                throw Db.internalError ?? Cannot.importData
            } catch Unsupported.inputFormat(let format) {
                return Http.badRequest("Format \(format) is not supported.")
            } catch {
                return Http.internalServerError()
            }
            
        } catch {
            return Http.internalServerError()
        }
        
        
    }
    
    static func getHeaders (contentType: String = "json") -> [String : String] {
        return [
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "*",
            "Content-Type": contentType == "json" ? "application/json" : "text/plain"
        ]
    }
    
    static func ok (_ message: String = "", contentType: String = "json") -> Response {
        return .ok(message, headers: getHeaders(contentType: contentType))
    }
    
    static func badRequest (_ message: String? = nil) -> Response {
        return Response(.custom(400, message ?? ""), headers: getHeaders())
    }
    
    static func internalServerError () -> Response {
        return Response(.internalServerError, headers: getHeaders())
    }
    
    static func imATeapot () -> Response {
        return Response(.custom(418, "I'm a teapot"), headers: getHeaders())
    }
}
