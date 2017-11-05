//
//  StringReader.swift
//  ByteCabinet
//
//  Created by Maxim Zaks on 04.09.17.
//

import Foundation

protocol StringStore: class {
    func read(_ index: UInt32) -> String?
    @discardableResult
    func add(_ s: String) throws -> UInt32
    var count: UInt32 {get}
    var compactedData: Data {get}
}

final class StringMemoryStore: StringStore {
    let queue = DispatchQueue(label: UUID().uuidString)
    let buffer: UnsafeMutableBufferPointer<UInt8>
    var countPointer: UnsafeMutablePointer<UInt32>
    
    init(buffer: UnsafeMutableBufferPointer<UInt8>, countPointer: UnsafeMutablePointer<UInt32>) {
        self.buffer = buffer
        self.countPointer = countPointer
    }
    
    var count: UInt32 {
        return countPointer.pointee
    }
    
    func read(_ index: UInt32) -> String? {
        let index = Int(index)
        guard buffer.count > index else {
            return nil
        }
        guard Int(countPointer.pointee) > index else {
            return nil
        }
        guard let p = buffer.baseAddress?.advanced(by: index) else {
            return nil
        }
        return String(cString: p)
    }
    
    @discardableResult
    func add(_ s: String) throws -> UInt32 {
//        return try queue.sync {
            let countInt = Int(countPointer.pointee)
            let sCount = s.utf8.count
            guard countInt + sCount + 1 < buffer.count else {
                throw CompartmentError.full
            }
            for (i, c) in s.utf8.enumerated() {
                buffer[countInt+i] = c
            }
            buffer[countInt+sCount] = 0
            
            var newCount = countPointer.pointee + 1 + UInt32(sCount)
            withUnsafePointer(to: &newCount) { (p) in
                countPointer.assign(from: p, count: 1)
            }
            return UInt32(countInt)
//        }
    }
    
    var compactedData: Data {
        var d1 = Data(bytesNoCopy: UnsafeMutableRawPointer(countPointer), count: 4, deallocator: .none)
        if let p = buffer.baseAddress {
            let alignedSize = count + align(cursor: count + 4, additionalBytes: 8)
            d1.append(Data(bytesNoCopy: UnsafeMutableRawPointer(p), count: Int(alignedSize), deallocator: .none))
        }
        return d1
    }
}

extension StringMemoryStore: CustomDebugStringConvertible {
    var debugDescription: String {
        return "[\(countPointer.pointee)] \(buffer.map{$0.description})"
    }
}

final class StringFileStore: StringStore {
    
    private(set) var count: UInt32
    
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
        count = data.withUnsafeBytes({ (p: UnsafePointer<UInt32>) -> UInt32 in
            return p.pointee
        })
    }
    
    deinit {
        close()
    }
    
    func close() {
        fileHandle.closeFile()
    }
    
    func read(_ index: UInt32) -> String? {
        let pos = offset + headerSize + UInt64(index)
        guard pos - offset < compartmentSize else {
            return nil
        }
        fileHandle.seek(toFileOffset: pos)
        var d = Data()
        repeat {
            let data = fileHandle.readData(ofLength: 1)
            guard data.isEmpty == false else {
                break
            }
            let c = data[0]
            guard c != 0 else {
                break
            }
            d.append(c)
        } while fileHandle.offsetInFile < offset + compartmentSize
        
        return String(data: d, encoding: .utf8)
    }
    
    @discardableResult
    func add(_ s: String) throws -> UInt32 {
        return try queue.sync {
            
            guard let d = s.data(using: .utf8) else {
                throw CompartmentError.addingUnsupportedType
            }
            
            let pos = offset + headerSize + UInt64(count)
            
            guard pos + UInt64(d.count) + 1 <= compartmentSize else {
                throw CompartmentError.full
            }
            
            fileHandle.seek(toFileOffset: pos)
            fileHandle.write(d)
            fileHandle.write(Data(bytes: [0]))
            let result = count
            count += UInt32(d.count + 1)
            withUnsafeBytes(of: &count) { (p) -> Void in
                fileHandle.seek(toFileOffset: offset)
                let data = Data(p)
                fileHandle.write(data)
            }
            return result
        }
    }
    
    var compactedData: Data {
        fileHandle.seek(toFileOffset: offset)
        let length = Int((UInt64(count)) + headerSize)
        let alignedLength = length + align(cursor: length, additionalBytes: 8)
        return fileHandle.readData(ofLength: alignedLength)
    }
}

