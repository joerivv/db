//
//  Run.swift
//  db
//
//  Created by Joeri van Veen on 19/01/2021.
//

import Foundation
import ArgumentParser
import JavaScriptCore

struct Run: ParsableCommand {
    
    public static let configuration = CommandConfiguration(abstract: "Run JavaScripts on the database.")
    
    @Flag(name: .customShort("s"), help: "Run JavaScript from string literal.")
    private var literal: Bool = false
    
    @Argument(help: "JavaScript file to run.")
    private var file: String
    
    @Flag(help: "View detailed logging.")
    private var verbose: Bool = false
    
    func run () throws {
        
        do {
            
            var script: String
            
            if literal {
                script = file
            } else {
                guard let fileContents = try? String(contentsOfFile: file) else {
                    throw Cannot.readScript
                }
                
                script = fileContents
            }
            
            let context = JSContext()!
            
            context.exceptionHandler = { context, exception in
                print(exception!.toString()!)
            }
            
            context.setObject(JavaScriptHooks.consoleLog, forKeyedSubscript: "__consoleLog" as NSString)
            
            let hooks: [String : Any] = [
                "consoleLog": JavaScriptHooks.consoleLog,
                "dbRead": JavaScriptHooks.dbRead,
                "dbWrite": JavaScriptHooks.dbWrite,
                "dbImport": JavaScriptHooks.dbImport,
                "dbAdd": JavaScriptHooks.dbAdd,
                "dbGetError": JavaScriptHooks.dbGetError,
                "dbGetRecords": JavaScriptHooks.dbGetRecords,
                "dbSetRecords": JavaScriptHooks.dbSetRecords,
                "fileRead": JavaScriptHooks.fileRead,
                "fileWrite": JavaScriptHooks.fileWrite,
                "itemExists": JavaScriptHooks.itemExists,
                "itemTrash": JavaScriptHooks.itemTrash,
                "itemMoveTo": JavaScriptHooks.itemMoveTo,
                "itemCopyTo": JavaScriptHooks.itemCopyTo,
                "folderMake": JavaScriptHooks.folderMake,
                "folderItems": JavaScriptHooks.folderItems,
                "folderPath": JavaScriptHooks.folderPath
            ]
            
            for (function, hook) in hooks {
                context.setObject(hook, forKeyedSubscript: "__" + function as NSString)
            }
            
            context.setObject(JavaScriptHooks.shell, forKeyedSubscript: "shell" as NSString)
            context.setObject(JavaScriptHooks.applescript, forKeyedSubscript: "applescript" as NSString)
            
            context.evaluateScript(
"""
const console = {
   log: __consoleLog
};

const db = {
    records: [],
    read () {
        if (!__dbRead()) {
            throw new Error(__dbGetError());
        } else {
            db.records = __dbGetRecords();
        }
    },
    write () {
        for (let record of db.records) {
            for (let p in record) {
                record[p] = String(record[p]);
            }
        }
        __dbSetRecords(db.records);
        if (!__dbWrite()) {
            throw new Error(__dbGetError());
        }
    },
    import (path) {
        try {
            const records = __dbImport(String(path));
            records.forEach(record => db.records.push(record));
        } catch (e) {
            throw new Error("Couldn't import file.");
        }
    },
    add (data, type) {
        try {
            const records = __dbAdd(String(data), type ? String(type) : "");
            records.forEach(record => db.records.push(record))
        } catch (e) {
            throw new Error("Data couldn't be parsed.");
        }
    }
};

const _fileHooks = {
    read () {
        return this.contents = __fileRead(this.path);
    },
    write () {
        if (arguments.length == 1) {
            this.contents = arguments[0];
        }
        __fileWrite(this.path, this.contents);
        return this;
    },
    exists () {
        return __itemExists(this.path);
    },
    trash () {
        __itemTrash(this.path);
        return this;
    },
    toString () {
        return this.path;
    },
    copyTo (destination, newName) {
        __itemCopyTo(this.path, destination.isFile
            ? destination.path
            : `${folder(destination)}/${newName || this.fullName}`);
    },
    __save () {
        this.__folder = folder(this.__folder);
        let oldPath = this.__path;
        let newPath =
            (this.__folder.path + "/") +
            (this.__hidden ? "." : "") +
            (this.__name) +
            (this.__extension ? "." + this.__extension : "");
        __itemMoveTo(oldPath, newPath);
        this.__path = newPath;
    }
};

const _folderHooks = {
    make () {
        __folderMake(this.__path);
        return this;
    },
    exists () {
        return __itemExists(this.__path);
    },
    trash () {
        __itemTrash(this.__path);
        return this;
    },
    toString () {
        return this.__path;
    },
    copyTo (destination, newName) {
        __itemCopyTo(this.path, `${folder(destination)}/${newName || this.name}`);
    },
    __save () {
        let oldPath = this.__path;
        let newPath = this.parent.path + "/" + this.name;
        __itemMoveTo(oldPath, newPath);
        this.__path = newPath;
    }
}

function _makeAbsolute (path) {
    path = path.charAt(path.length - 1) == "/" ? path.substring(0, -1) : path;
    const isRelative = path.indexOf("/") == -1;
    return isRelative ? __folderPath('current') + "/" + path : path;
}

function _makeHiddenProperties (properties) {
    let hiddenProperties = {};
    for (let p in properties) {
        hiddenProperties["__" + p] = {
            value: properties[p],
            enumerable: false,
            configurable: false,
            writable: true
        };
    }
    return hiddenProperties;
}

function _makePropertyWrappers (properties) {
    let wrappers = {};
    for (let property of properties) {
        wrappers[property] = {
            get () {
                return this["__" + property];
            },
            set (v) {
                if (property != "path") {
                    this["__" + property] = v;
                    this.__save();
                    return v;
                }
            }
        };
    }
    return wrappers;
}

function file (path) {
    if (path.isFile) return path;
    path = _makeAbsolute(path);
    let components = path.split("/");
    let fullName = components[components.length - 1];
    return Object.create(_fileHooks, {
        ..._makePropertyWrappers(["folder", "hidden", "name", "extension"]),
        ..._makeHiddenProperties({
            path: path,
            folder: folder(components.slice(0, -1).join("/")),
            hidden: fullName.charAt(0) == ".",
            name: fullName.replace(/(^\\.|\\.[^.]+$)/g, ""),
            extension: fullName.lastIndexOf(".") > 0 ? /(?:\\.([^.]+))?$/.exec(fullName)[1] : ""
        }),
        path: { get () { return this.__path; } },
        fullName: {
            get () { return this.__path.split("/").pop(); },
            set (fullName) {
                this.__hidden = fullName.charAt(0) == ".";
                this.__name = fullName.replace(/(^\\.|\\.[^.]+$)/g, "");
                this.__extension = fullName.lastIndexOf(".") > 0 ? /(?:\\.([^.]+))?$/.exec(fullName)[1] : "";
                this.__save();
                return fullName;
            }
        },
        isFile: { value: true },
        isFolder: { value: false },
        contents: { value: "", writable: true }
    });
}

function folder (path) {
    if (path.isFolder) return path;
    if (path == "") return null;
    path = _makeAbsolute(path);
    let components = path.split("/");
    return Object.create(_folderHooks, {
        ..._makePropertyWrappers(["path", "parent", "name"]),
        ..._makeHiddenProperties({
            path: path,
            parent: folder(components.slice(0, -1).join("/")),
            name: components[components.length - 1]
        }),
        isFile: { value: false },
        isFolder: { value: true },
        items: {
            get () {
                const items = __folderItems(this.path).map(item => {
                    if (item.type == "folder") {
                        return folder(item.path);
                    } else {
                        return file(item.path);
                    }
                })
                items.toString = function () {
                    return this.join("\\n");
                };
                return items;
            }
        }
    });
}

Object.defineProperties(folder, {
    home: { value: folder(__folderPath('home')) },
    desktop: { value: folder(__folderPath('desktop')) },
    documents: { value: folder(__folderPath('documents')) },
    downloads: { value: folder(__folderPath('downloads')) },
    current: { value: folder(__folderPath('current')) }
});
""")
            context.evaluateScript(script)
            
        } catch Cannot.readScript {
            ErrorMessage.show(Cannot.readScript, includeVerboseMessage: !verbose)
        }
        
        if verbose {
            ErrorMessage.showInternalError()
        }
        
    }
}
