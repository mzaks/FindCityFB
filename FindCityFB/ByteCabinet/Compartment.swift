//
//  Compartment.swift
//  ByteCabinetPackageDescription
//
//  Created by Maxim Zaks on 03.09.17.
//

import Foundation

public enum CompartmentType: UInt8 {
    case unknown,
    i8, i16, i32, i64,
    u8, u16, u32, u64,
    f32, f64,
    bool,
    string,
    data
    // fsdata, keys,
    // 2bit, 4bit, vli, vlu, vlf
}

public enum CompartmentError: Error {
    case addingUnsupportedType, full, unattached, fileTooSmall, badCursor
}

public protocol Compartment: class {}

internal protocol _Compartment: Compartment {
    var capacity: UInt32 {get}
    var dataSize: UInt32 {get}
    var indexBufferSize: UInt32 {get}
    var indexCountSize: UInt32 {get}
    var dataBufferSize: UInt32 {get}
    var type: CompartmentType {get}
    var compactedDataAndSizes: (Data, UInt32, UInt32) {get}
}

internal protocol InMemoryCompartment {
    func assignMemoryReaders(_ pointer: UnsafeRawPointer)
}

internal protocol InFileCompartment {
    func assignFileReaders(_ fileHandle: FileHandle, _ offset: UInt32) throws
}


public final class NumericCompartment<T: Numeric>: _Compartment, InMemoryCompartment, InFileCompartment {
    
    let numberType: T.Type
    let capacity: UInt32
    
    var indexStore: NumberStore?
    
    public init(capacity: UInt32, type: T.Type) {
        self.capacity = capacity
        numberType = type
    }
    
    var dataSize: UInt32 {return 0}
    
    var indexBufferSize: UInt32 {
        let size = capacity * UInt32(MemoryLayout<T>.alignment) + indexCountSize
        let padding = align(cursor: size, additionalBytes: 8)
        return size + padding
    }
    
    var indexCountSize: UInt32 {
        return 4 + UInt32(align(cursor: 4, additionalBytes: MemoryLayout<T>.alignment))
    }
    
    var dataBufferSize: UInt32 = 0
    
    func assignMemoryReaders(_ pointer: UnsafeRawPointer) {
        let countPointer = UnsafeMutablePointer(mutating: pointer.assumingMemoryBound(to: UInt32.self))
        let dataStartPointer = pointer.advanced(by: Int(indexCountSize)).assumingMemoryBound(to: T.self)
        let dataBuffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(mutating:dataStartPointer), count: Int(capacity))
        indexStore = NumberMemoryStore(data: dataBuffer, countPointer: countPointer)
    }
    
    func assignFileReaders(_ fileHandle: FileHandle, _ offset: UInt32) throws {
        indexStore = try NumberFileStore(fileHandle: fileHandle, offset: offset, compartmentSize: indexBufferSize, type: numberType)
    }
    
    var type: CompartmentType {
        if T.self == UInt8.self {
            return .u8
        } else if T.self == UInt16.self {
            return .u16
        } else if T.self == UInt32.self {
            return .u32
        } else if T.self == UInt64.self {
            return .u64
        } else if T.self == Int8.self {
            return .i8
        } else if T.self == Int16.self {
            return .i16
        } else if T.self == Int32.self {
            return .i32
        } else if T.self == Int64.self {
            return .i64
        } else if T.self == Float32.self {
            return .f32
        } else if T.self == Float64.self {
            return .f64
        }
        return .unknown
    }
    var compactedDataAndSizes: (Data, UInt32, UInt32) {
        let data = indexStore?.compactedData ?? Data()
        return (data, UInt32(data.count), 0)
    }
}

extension NumericCompartment: Collection {
    public func index(after i: UInt32) -> UInt32 {
        return i + 1
    }
    
    public var startIndex: UInt32 {
        return 0
    }
    
    public var endIndex: UInt32 {
        return indexStore?.count ?? 0
    }
    
    public subscript(i: UInt32) -> T? {
        return indexStore?.read(i)
    }
    
    @discardableResult
    public func add(_ n: T) throws -> UInt32 {
        guard let indexStore = indexStore else {
            throw CompartmentError.unattached
        }
        return try indexStore.add(n)
    }
}

public final class BoolCompartment: _Compartment, InMemoryCompartment, InFileCompartment {
    let capacity: UInt32
    
    var bitsetStore: BitSetStore?
    
    public init(capacity: UInt32) {
        self.capacity = capacity
    }
    
    var dataSize: UInt32 {return 0}
    
    var indexBufferSize: UInt32 {
        let size = ((capacity / 32) + 1 ) * 4 + 4
        let padding = align(cursor: size, additionalBytes: 8)
        return size + padding
    }
    
    var indexCountSize: UInt32 {
        return 4
    }
    
    var dataBufferSize: UInt32 = 0
    
    func assignMemoryReaders(_ pointer: UnsafeRawPointer) {
        let countPointer = UnsafeMutablePointer(mutating: pointer.assumingMemoryBound(to: UInt32.self))
        let dataStartPointer = pointer.advanced(by: Int(indexCountSize)).assumingMemoryBound(to: UInt8.self)
        let dataBuffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(mutating:dataStartPointer), count: Int((capacity / 32) + 1))
        bitsetStore = BitSetMemoryStore(words: dataBuffer, countPointer: countPointer)
    }
    
    func assignFileReaders(_ fileHandle: FileHandle, _ offset: UInt32) throws {
        bitsetStore = try BitSetFileStore(fileHandle: fileHandle, offset: offset, sizeInBytes: indexBufferSize)
    }
    
    var type = CompartmentType.bool
    
    var compactedDataAndSizes: (Data, UInt32, UInt32) {
        return (Data(), 0, 0) // TODO: implement
    }
}

extension BoolCompartment: Collection {
    public func index(after i: UInt32) -> UInt32 {
        return i + 1
    }
    
    public var startIndex: UInt32 {
        return 0
    }
    
    public var endIndex: UInt32 {
        return bitsetStore?.count ?? 0
    }
    
    public subscript(i: UInt32) -> Bool? {
        return bitsetStore?.isSet(i)
    }
    
    @discardableResult
    public func add(_ n: Bool) throws -> UInt32 {
        guard let bitsetStore = bitsetStore else {
            throw CompartmentError.unattached
        }
        return try bitsetStore.add(n)
    }
}

public final class StringCompartment: _Compartment, InMemoryCompartment, InFileCompartment {
    let capacity: UInt32
    let dataSize: UInt32
    
    var indexStore: NumberStore?
    var stringStore: StringStore?
    
    public init(capacity: UInt32, dataSize: UInt32) {
        self.capacity = capacity
        self.dataSize = dataSize
    }
    
    var indexBufferSize: UInt32 {
        let size = capacity * 4 + indexCountSize
        let padding = align(cursor: size, additionalBytes: 8)
        return size + padding
    }
    
    var indexCountSize: UInt32 {
        return 4
    }
    
    var dataBufferSize: UInt32 {
        let dataSize = self.dataSize + 4
        let padding = align(cursor: dataSize, additionalBytes: 8)
        return dataSize + padding
    }
    
    func assignMemoryReaders(_ pointer: UnsafeRawPointer) {
        let countPointer = UnsafeMutablePointer(mutating: pointer.assumingMemoryBound(to: UInt32.self))
        let indexStartPointer = pointer.advanced(by: Int(indexCountSize)).assumingMemoryBound(to: UInt32.self)
        let indexBuffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(mutating:indexStartPointer), count: Int(capacity))
        indexStore = NumberMemoryStore(data: indexBuffer, countPointer: countPointer)
        let cursorPointer = UnsafeMutablePointer(mutating: pointer.advanced(by: Int(indexBufferSize)).assumingMemoryBound(to: UInt32.self))
        let dataStartPointer = UnsafeMutablePointer(mutating: pointer.advanced(by: Int(indexBufferSize + 4)).assumingMemoryBound(to: UInt8.self))
        let dataBuffer = UnsafeMutableBufferPointer(start: dataStartPointer, count: Int(dataSize))
        stringStore = StringMemoryStore(buffer: dataBuffer, countPointer: cursorPointer)
    }
    
    func assignFileReaders(_ fileHandle: FileHandle, _ offset: UInt32) throws {
        indexStore = try NumberFileStore(fileHandle: fileHandle, offset: offset, compartmentSize: indexBufferSize, type: UInt32.self)
        stringStore = try StringFileStore(fileHandle: fileHandle, offset: offset + indexBufferSize, size: dataBufferSize)
    }
    
    var type = CompartmentType.string
    
    var compactedDataAndSizes: (Data, UInt32, UInt32) {
        var d1 = indexStore?.compactedData ?? Data()
        let s1 = UInt32(d1.count)
        var s2 = UInt32(0)
        if let d2 = stringStore?.compactedData {
            s2 = UInt32(d2.count)
            d1.append(d2)
        }
        return (d1, s1, s2)
    }
    
    public var count: Int {
        guard let count = indexStore?.count else {
            return 0
        }
        return Int(count)
    }
}
extension StringCompartment: Collection {
    public func index(after i: UInt32) -> UInt32 {
        return i + 1
    }
    
    public var startIndex: UInt32 {
        return 0
    }
    
    public var endIndex: UInt32 {
        return indexStore?.count ?? 0
    }
    
    public subscript(i: UInt32) -> String? {
        guard let index: UInt32 = indexStore?.read(i) else {
            return nil
        }
        return stringStore?.read(index)
    }
    
    @discardableResult
    public func add(_ s: String) throws -> UInt32 {
        guard let indexStore = indexStore,
            let stringStore = stringStore else {
            throw CompartmentError.unattached
        }
        if indexStore.availableSlots > 0 {
            let cursor = try stringStore.add(s)
            return try indexStore.add(cursor)
        } else {
            throw CompartmentError.full
        }
    }
}

public final class DataCompartment: _Compartment, InMemoryCompartment, InFileCompartment {
    let capacity: UInt32
    let dataSize: UInt32
    
    var indexStore: NumberStore?
    var dataStore: DataStore?
    
    public init(capacity: UInt32, dataSize: UInt32) {
        self.capacity = capacity
        self.dataSize = dataSize
    }
    
    var indexBufferSize: UInt32 {
        let size = capacity * 8 + indexCountSize
        let padding = align(cursor: size, additionalBytes: 8)
        return size + padding
    }
    
    var indexCountSize: UInt32 {
        return 4
    }
    
    var dataBufferSize: UInt32 {
        let dataSize = self.dataSize + 4
        let padding = align(cursor: dataSize, additionalBytes: 8)
        return dataSize + padding
    }
    func assignMemoryReaders(_ pointer: UnsafeRawPointer) {
        let countPointer = UnsafeMutablePointer(mutating: pointer.assumingMemoryBound(to: UInt32.self))
        let indexStartPointer = pointer.advanced(by: Int(indexCountSize)).assumingMemoryBound(to: UInt32.self)
        let indexBuffer = UnsafeMutableBufferPointer(start: UnsafeMutablePointer(mutating:indexStartPointer), count: Int(capacity * 2))
        indexStore = NumberMemoryStore(data: indexBuffer, countPointer: countPointer)
        let cursorPointer = UnsafeMutablePointer(mutating: pointer.advanced(by: Int(indexBufferSize)).assumingMemoryBound(to: UInt32.self))
        let dataStartPointer = UnsafeMutableRawPointer(mutating: pointer.advanced(by: Int(indexBufferSize + 4)))
        let dataBuffer = UnsafeMutableRawBufferPointer(start: dataStartPointer, count: Int(dataSize))
        dataStore = DataMemoryStore(buffer: dataBuffer, cursorPointer: cursorPointer)
    }
    func assignFileReaders(_ fileHandle: FileHandle, _ offset: UInt32) throws {
        indexStore = try NumberFileStore(fileHandle: fileHandle, offset: offset, compartmentSize: indexBufferSize, type: UInt32.self)
        dataStore = try DataFileStore(fileHandle: fileHandle, offset: offset + indexBufferSize, size: dataBufferSize)
    }
    var type = CompartmentType.data
    
    var compactedDataAndSizes: (Data, UInt32, UInt32) {
        return (Data(), 0, 0) // TODO: implement
    }
}
extension DataCompartment: Collection {
    
    public func index(after i: UInt32) -> UInt32 {
        return i + 1
    }
    
    public var startIndex: UInt32 {
        return 0
    }
    
    public var endIndex: UInt32 {
        return (indexStore?.count ?? 0) / 2
    }
    
    public subscript(i: UInt32) -> Data? {
        guard let index: UInt32 = indexStore?.read(i * 2),
            let length: UInt32 = indexStore?.read(i * 2 + 1) else {
            return nil
        }
        if index == 0 && length == 0 {
            return nil
        }
        return dataStore?.read(index, length: length)
    }
    public func valueIsNil(_ i: UInt32) -> Bool {
        guard let index: UInt32 = indexStore?.read(i * 2),
            let length: UInt32 = indexStore?.read(i * 2 + 1) else {
                return false
        }
        return index == 0 && length == 0
    }
    
    @discardableResult
    public func add(_ d: Data?) throws -> UInt32 {
        guard let indexStore = indexStore,
            let dataStore = dataStore else {
                throw CompartmentError.unattached
        }
        guard let d = d else {
            let result = try indexStore.add(UInt32(0))
            try indexStore.add(UInt32(0))
            return result
        }
        guard d.count < UInt32.max else {
            throw CompartmentError.addingUnsupportedType
        }
        if indexStore.availableSlots > 0 {
            let cursor = try dataStore.add(d)
            let result = try indexStore.add(cursor)
            try indexStore.add(UInt32(d.count))
            return result
        } else {
            throw CompartmentError.full
        }
    }
}
