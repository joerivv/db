
import Foundation
import ArgumentParser
import Swifter

struct DbCommandLine: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "db",
        abstract: "A simple tool for managing local XML databases.",
        subcommands: [
            Stats.self,
            Import.self,
            As.self,
            Rename.self,
            Compress.self,
            Decompress.self,
            Serve.self,
            Delete.self,
            Run.self
        ])
    
    @Argument(help: "Name of the database")
    private var database: String
}

if CommandLine.arguments.count > 1 {
    Db.createIfNotExists()
}

if CommandLine.arguments.count > 2 {
    DbCommandLine.main()
} else {
    try? Import(usingDefaults: true).run()
}
