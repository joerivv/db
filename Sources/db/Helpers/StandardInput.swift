//
//  StandardInput.swift
//  db
//
//  Created by Joeri van Veen on 27/01/2021.
//

import Foundation

struct StandardInput {
    
    private enum FileStatModeType: Int {
        case S_IFMT   = 61440 /* [XSI] type of file mask */
        case S_IFIFO  = 4096  /* [XSI] named pipe (fifo) */
        case S_IFCHR  = 8192  /* [XSI] character special */
        case S_IFDIR  = 16384 /* [XSI] directory */
        case S_IFBLK  = 24576 /* [XSI] block special */
        case S_IFREG  = 32768 /* [XSI] regular */
        case S_IFLNK  = 40960 /* [XSI] symbolic link */
        case S_IFSOCK = 49152 /* [XSI] socket */
    }
    
    static func isAvailable () -> Bool {
        guard let inputStream = InputStream(fileAtPath: "/dev/stdin") else {
            return false
        }
        
        inputStream.open()
        
        defer { inputStream.close() }
        return inputStream.hasBytesAvailable
    }
    
    static private func isType (_ type: FileStatModeType) -> Bool {
        
        var statPointer = stat()
        
        fstat(STDIN_FILENO, &statPointer)
        
        let mode = Int(statPointer.st_mode)
        let desiredMode = type.rawValue
        
        return mode & desiredMode == desiredMode
        
    }
    
    static func isPipedString () -> Bool {
        return self.isType(FileStatModeType.S_IFIFO)
    }
    
    static func isRedirectedFile () -> Bool {
        return self.isType(FileStatModeType.S_IFREG)
    }
    
    static func read () -> String {
        var data = ""
        while let line = readLine() {
            data += line + "\n"
        }
        return String(data.dropLast())
        
    }
}
