//
//  IndexReader.swift
//  ByteCabinetPackageDescription
//
//  Created by Maxim Zaks on 03.09.17.
//

import Foundation

protocol NumberStore: class {
    func read<N: Numeric>(_ index: UInt32) -> N?
    @discardableResult
    func add<N: Numeric>(_ n: N) throws -> UInt32
    var count: UInt32 {get}
    var availableSlots: UInt32 {get}
    var compactedData: Data {get}
}

final class NumberMemoryStore<T: Numeric>: NumberStore {
    let queue = DispatchQueue(label: UUID().uuidString)
    var mutex = pthread_mutex_t()
    let data : UnsafeMutableBufferPointer<T>
    var countPointer: UnsafeMutablePointer<UInt32>
    
    init(data : UnsafeMutableBufferPointer<T>, countPointer: UnsafeMutablePointer<UInt32>) {
        self.data = data
        self.countPointer = countPointer
        
        var attr: pthread_mutexattr_t = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        
        let err = pthread_mutex_init(&mutex, &attr)
        pthread_mutexattr_destroy(&attr)
        
        switch err {
        case 0:
            // Success
            break
            
        case EAGAIN:
            fatalError("Could not create mutex: EAGAIN (The system temporarily lacks the resources to create another mutex.)")
            
        case EINVAL:
            fatalError("Could not create mutex: invalid attributes")
            
        case ENOMEM:
            fatalError("Could not create mutex: no memory")
            
        default:
            fatalError("Could not create mutex, unspecified error \(err)")
        }
    }
    
    func read<N: Numeric>(_ index: UInt32) -> N? {
        let index = Int(index)
        guard data.count > index else {
            return nil
        }
        guard Int(countPointer.pointee) > index else {
            return nil
        }
        guard let pos = data.baseAddress?.advanced(by: index) else {
            return nil
        }
        return pos.pointee as? N
    }
    
    @discardableResult
    func add<N: Numeric>(_ n: N) throws -> UInt32 {
//        return try queue.sync {
        guard pthread_mutex_lock(&mutex) == 0 else {
            throw CompartmentError.badCursor
        }
            let countInt = Int(countPointer.pointee)
            guard availableSlots > 0 else {
                throw CompartmentError.full
            }
            guard let t = n as? T else {
                throw CompartmentError.addingUnsupportedType
            }
            
            data[countInt] = t
            
            var newCount = countPointer.pointee + 1
            withUnsafePointer(to: &newCount) { (p) in
                countPointer.assign(from: p, count: 1)
            }
        guard pthread_mutex_unlock(&mutex) == 0 else {
            throw CompartmentError.badCursor
        }
        
            return UInt32(countInt)
//        }
        
    }
    
    var availableSlots: UInt32 {
        return UInt32(data.count) - count
    }
    
    var count: UInt32 {
        return countPointer.pointee
    }
    var compactedData: Data {
        let headerSize = MemoryLayout<T>.alignment > 4 ? 8 : 4
        var d1 = Data(bytesNoCopy: UnsafeMutableRawPointer(countPointer), count: headerSize, deallocator: .none)
        if let p = data.baseAddress {
            let size = Int(count) * MemoryLayout<T>.alignment
            let alignedSize = size + align(cursor: Int(size) + headerSize, additionalBytes: 8)
            d1.append(Data(bytesNoCopy: UnsafeMutableRawPointer(p), count: alignedSize, deallocator: .none))
        }
        return d1
    }
}

extension NumberMemoryStore: CustomDebugStringConvertible {
    var debugDescription: String {
        return "<\(T.self)>[\(countPointer.pointee)] \(data.map{$0})"
    }
}


final class NumberFileStore: NumberStore {
    
    let queue = DispatchQueue(label: UUID().uuidString)
    let fileHandle: FileHandle
    let offset: UInt64
    let entrySize: UInt64
    let compartmentSize: UInt64
    var cursor: UInt32
    let headerSize: UInt64
    
    init<T: Numeric>(fileHandle: FileHandle, offset: UInt32, compartmentSize: UInt32, type: T.Type) throws {
        self.fileHandle = fileHandle
        self.offset = UInt64(offset)
        self.compartmentSize = UInt64(compartmentSize)
        entrySize = UInt64(MemoryLayout<T>.alignment)
        headerSize = entrySize < 8 ? 4 : 8
        guard fileHandle.seekToEndOfFile() >= self.offset + self.compartmentSize else {
            throw CompartmentError.fileTooSmall
        }
        fileHandle.seek(toFileOffset: self.offset)
        let data = fileHandle.readData(ofLength: 4)
        cursor = data.withUnsafeBytes({ (p: UnsafePointer<UInt32>) -> UInt32 in
            return p.pointee
        })
        guard UInt64(cursor) * entrySize + headerSize <= self.compartmentSize else {
            throw CompartmentError.badCursor
        }
    }
    
    func read<N>(_ index: UInt32) -> N? where N : Numeric {
        let destination = self.offset + headerSize + UInt64(index) * entrySize
        guard destination + entrySize - self.offset <= compartmentSize else {
            return nil
        }
        guard index < cursor else {
            return nil
        }
        fileHandle.seek(toFileOffset: destination)
        let data = fileHandle.readData(ofLength: Int(entrySize))
        return data.withUnsafeBytes({ (p: UnsafePointer<N>) -> N in
            return p.pointee
        })
    }
    
    @discardableResult
    func add<N: Numeric>(_ n: N) throws -> UInt32 {
        return try queue.sync {
            guard availableSlots > 0 else {
                throw CompartmentError.full
            }
            guard MemoryLayout<N>.alignment == entrySize else {
                throw CompartmentError.addingUnsupportedType
            }
            var n1 = n
            
            let pos = offset + headerSize + UInt64(cursor) * entrySize
            withUnsafeBytes(of: &n1) { (p) -> Void in
                fileHandle.seek(toFileOffset: pos)
                let data = Data(p)
                fileHandle.write(data)
            }
            let result = cursor
            cursor += 1
            withUnsafeBytes(of: &cursor) { (p) -> Void in
                fileHandle.seek(toFileOffset: offset)
                let data = Data(p)
                fileHandle.write(data)
            }
            return result
        }
    }
    
    var availableSlots: UInt32 {
        return UInt32((compartmentSize - (UInt64(cursor) * entrySize) - headerSize) / entrySize)
    }
    
    var count: UInt32 {
        return cursor
    }
    
    deinit {
        close()
    }
    
    func close() {
        fileHandle.closeFile()
    }
    
    var compactedData: Data {
        fileHandle.seek(toFileOffset: offset)
        let size = Int((UInt64(cursor) * entrySize) + headerSize)
        let alignedSize = size + align(cursor: size, additionalBytes: 8)
        return fileHandle.readData(ofLength: alignedSize)
    }
}
