//
//  DataReader.swift
//  ByteCabinet
//
//  Created by Maxim Zaks on 06.09.17.
//

import Foundation

protocol DataStore: class {
    func read(_ cursor: UInt32, length: UInt32) -> Data?
    func add(_ d: Data) throws -> UInt32
    var cursor: UInt32 {get}
}

final class DataMemoryStore: DataStore {
    let queue = DispatchQueue(label: UUID().uuidString)
    let buffer: UnsafeMutableRawBufferPointer
    var cursorPointer: UnsafeMutablePointer<UInt32>
    
    init(buffer: UnsafeMutableRawBufferPointer, cursorPointer: UnsafeMutablePointer<UInt32>) {
        self.buffer = buffer
        self.cursorPointer = cursorPointer
    }
    
    var cursor: UInt32 {
        return cursorPointer.pointee
    }
    
    func read(_ cursor: UInt32, length: UInt32) -> Data? {
        let cursor = Int(cursor)
        guard buffer.count > cursor else {
            return nil
        }
        guard Int(cursorPointer.pointee) > cursor else {
            return nil
        }
        
        guard let p = buffer.baseAddress?.advanced(by: cursor) else {
            return nil
        }
        return Data(bytes: p, count: Int(length))
    }
    
    func add(_ d: Data) throws -> UInt32 {
        return try queue.sync {
            let cursor = cursorPointer.pointee
            let cursorInt = Int(cursor)
            guard cursorInt + d.count < buffer.count else {
                throw CompartmentError.full
            }
            
            guard let p = buffer.baseAddress?.advanced(by: cursorInt).assumingMemoryBound(to: UInt8.self) else {
                throw CompartmentError.addingUnsupportedType
            }
            
            d.copyBytes(to: p, count: d.count)
            
            var newCursor = cursor + UInt32(d.count)
            withUnsafePointer(to: &newCursor) { (p) in
                cursorPointer.assign(from: p, count: 1)
            }
            return cursor
        }
    }
}

extension DataMemoryStore: CustomDebugStringConvertible {
    var debugDescription: String {
        return "[\(cursorPointer.pointee)] \(buffer.map{$0.description})"
    }
}

final class DataFileStore: DataStore {
    
    private(set) var cursor: UInt32
    
    let queue = DispatchQueue(label: UUID().uuidString)
    let fileHandle: FileHandle
    let offset: UInt64
    let compartmentSize: UInt64
    let headerSize: UInt64
    
    init(fileHandle: FileHandle, offset: UInt32, size: UInt32) throws {
        self.fileHandle = fileHandle
        self.offset = UInt64(offset)
        self.compartmentSize = UInt64(size)
        headerSize = 4
        
        guard fileHandle.seekToEndOfFile() >= self.offset + self.compartmentSize else {
            throw CompartmentError.fileTooSmall
        }
        fileHandle.seek(toFileOffset: 0)
        let data = fileHandle.readData(ofLength: 4)
        cursor = data.withUnsafeBytes({ (p: UnsafePointer<UInt32>) -> UInt32 in
            return p.pointee
        })
    }
    
    func read(_ cursor: UInt32, length: UInt32) -> Data? {
        let cursor = UInt64(cursor)
        guard cursor < self.cursor else {
            return nil
        }
        let destination = UInt64(cursor) + offset + headerSize
        guard destination - offset <= compartmentSize else {
            return nil
        }
        fileHandle.seek(toFileOffset: destination)
        return fileHandle.readData(ofLength: Int(length))
    }
    
    func add(_ d: Data) throws -> UInt32 {
        return try queue.sync {
            
            let pos = offset + headerSize + UInt64(cursor)
            
            guard UInt64(cursor) + UInt64(d.count) <= compartmentSize else {
                throw CompartmentError.full
            }
            
            fileHandle.seek(toFileOffset: pos)
            fileHandle.write(d)
            
            let result = cursor
            cursor += UInt32(d.count)
            withUnsafeBytes(of: &cursor) { (p) -> Void in
                fileHandle.seek(toFileOffset: offset)
                let data = Data(p)
                fileHandle.write(data)
            }
            return result
        }
    }
    
    deinit {
        close()
    }
    
    func close() {
        fileHandle.closeFile()
    }
}
