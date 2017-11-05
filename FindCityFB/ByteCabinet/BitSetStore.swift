//
//  BitReader.swift
//  ByteCabinetPackageDescription
//
//  Created by Maxim Zaks on 04.09.17.
//

import Foundation

protocol BitSetStore: class {
    func isSet(_ i: UInt32) -> Bool?
    @discardableResult
    func add(_ n: Bool) throws -> UInt32
    var count: UInt32 {get}
}

// Based on https://github.com/raywenderlich/swift-algorithm-club/blob/master/Bit%20Set/BitSet.swift
final class BitSetMemoryStore: BitSetStore {
    
    /*
     We store the bits in a list of unsigned 32-bit integers.
     The first entry, `words[0]`, is the least significant word.
     */
    static let N = MemoryLayout<Word>.alignment * 8
    typealias Word = UInt8
    
    var words: UnsafeMutableBufferPointer<Word>
    var countPointer: UnsafeMutablePointer<UInt32>
    
    let queue = DispatchQueue(label: UUID().uuidString)
    
    init(words: UnsafeMutableBufferPointer<Word>, countPointer: UnsafeMutablePointer<UInt32>) {
        self.words = words
        self.countPointer = countPointer
    }
    
    /* Sets the bit at the specified index to 1. */
    private func set(_ i: Int) {
        let (j, m) = indexOf(i)
        words[j] |= m
    }
    
    /* Sets the bit at the specified index to 0. */
    private func clear(_ i: Int) {
        let (j, m) = indexOf(i)
        words[j] &= ~m
    }
    
    /* Determines whether the bit at the specific index is 1 (true) or 0 (false). */
    public func isSet(_ i: UInt32) -> Bool? {
        guard i < countPointer.pointee else {
            return nil
        }
        let (j, m) = indexOf(Int(i))
        return (words[j] & m) != 0
    }
    
    @discardableResult
    func add(_ b: Bool) throws -> UInt32 {
        return try queue.sync {
            let countInt = Int(countPointer.pointee)
            guard countInt < words.count * BitSetMemoryStore.N else {
                throw CompartmentError.full
            }
            
            if b {
                set(countInt)
            } else {
                clear(countInt)
            }
            
            var newCount = countPointer.pointee + 1
            withUnsafePointer(to: &newCount) { (p) in
                countPointer.assign(from: p, count: 1)
            }
            return UInt32(countInt)
        }
    }
    
    var count: UInt32 {
        return countPointer.pointee
    }
}

extension BitSetMemoryStore.Word {
    /* Writes the bits in little-endian order, LSB first. */
    public func bitsToString() -> String {
        var s = ""
        var n = self
        for _ in 1...BitSetMemoryStore.N {
            s += ((n & 1 == 1) ? "1" : "0")
            n >>= 1
        }
        return s
    }
}

/* Converts a bit index into an array index and a mask inside the word. */
fileprivate func indexOf(_ i: Int) -> (Int, BitSetMemoryStore.Word) {
    let o = i / BitSetMemoryStore.N
    let m = BitSetMemoryStore.Word(i - o*BitSetMemoryStore.N)
    return (o, 1 << m)
}

extension BitSetMemoryStore: CustomDebugStringConvertible {
    public var debugDescription: String {
        var s = ""
        for x in words {
            s += x.bitsToString() + " "
        }
        return "[\(countPointer.pointee)] \(s)"
    }
}

final class BitSetFileStore: BitSetStore {
    
    let queue = DispatchQueue(label: UUID().uuidString)
    let fileHandle: FileHandle
    let offset: UInt64
    let compartmentSize: UInt64
    let headerSize: UInt64
    
    private(set) var count: UInt32
    
    init(fileHandle: FileHandle, offset: UInt32, sizeInBytes: UInt32) throws {
        self.fileHandle = fileHandle
        self.offset = UInt64(offset)
        self.compartmentSize = UInt64(sizeInBytes)
        headerSize = 4
        
        guard fileHandle.seekToEndOfFile() >= self.offset + headerSize + self.compartmentSize else {
            throw CompartmentError.fileTooSmall
        }
        fileHandle.seek(toFileOffset: self.offset)
        let data = fileHandle.readData(ofLength: 4)
        count = data.withUnsafeBytes({ (p: UnsafePointer<UInt32>) -> UInt32 in
            return p.pointee
        })
    }
    
    func isSet(_ i: UInt32) -> Bool? {
        guard i < count else {
            return nil
        }
        let byteOffest = (i / 8)
        let bitOffest = i - (byteOffest * 8)
        let pattern = UInt8(1) << bitOffest
        let pos = offset + headerSize + UInt64(byteOffest)
        fileHandle.seek(toFileOffset: pos)
        let byte = fileHandle.readData(ofLength: 1)[0]
        return byte & pattern != 0
    }
    
    @discardableResult
    func add(_ b: Bool) throws -> UInt32 {
        return try queue.sync {
            guard canAdd else {
                throw CompartmentError.full
            }
            
            let byteOffest = (count / 8)
            let bitOffest = count - (byteOffest * 8)
            let pattern = UInt8(1) << bitOffest
            let pos = offset + headerSize + UInt64(byteOffest)
            fileHandle.seek(toFileOffset: pos)
            let byte = fileHandle.readData(ofLength: 1)[0]
            
            var newValue = b ? (byte | pattern) : (byte & (~pattern))
            
            withUnsafeBytes(of: &newValue) { (p) -> Void in
                fileHandle.seek(toFileOffset: pos)
                let data = Data(p)
                fileHandle.write(data)
            }
            
            let result = count
            count += 1
            
            withUnsafeBytes(of: &count) { (p) -> Void in
                fileHandle.seek(toFileOffset: offset)
                let data = Data(p)
                fileHandle.write(data)
            }
            return result
        }
    }
    var canAdd: Bool {
        return (count / 8) < compartmentSize
    }
    
    deinit {
        close()
    }
    
    func close() {
        fileHandle.closeFile()
    }
}
