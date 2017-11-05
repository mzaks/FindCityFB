import CoreFoundation
import Foundation

public enum ByteCabinetError: Error {
    case moreThan200Comaprtments, totalSizeExceeds4GB, internalError
}

public final class ByteCabinet {
    private var compartments: [_Compartment] = []
    let buffer: UnsafeMutableRawBufferPointer?
    public let size: UInt32
    var _data : Data?
    var url: URL?
    
    /// Intialise a new ByteCabinet from array of compartments
    /// A new memory region will be allocated based compartment capacities
    public init(compartments: [Compartment]) throws {
        self.compartments = compartments.flatMap { $0 as? _Compartment }
        let types = self.compartments.map{$0.type}
        guard types.contains(.unknown) == false else {
            throw CompartmentError.addingUnsupportedType
        }
        size = try computeTotalBufferSize(self.compartments)
        buffer = UnsafeMutableRawBufferPointer.allocate(count: Int(size))
        buffer?.baseAddress?.initializeMemory(as: UInt8.self, at: 0, count: Int(size), to: 0)
        var offset = 0
        var offsets = [UInt32]()
        for c in self.compartments {
            guard let p = buffer?.baseAddress?.advanced(by: offset),
                let _c = c as? InMemoryCompartment else {
                throw ByteCabinetError.internalError
            }
            _c.assignMemoryReaders(p)
            let firstOffset = UInt32(offset) + c.indexBufferSize
            offsets.append(firstOffset)
            offsets.append(firstOffset + c.dataBufferSize)
            offset += Int(c.indexBufferSize) + Int(c.dataBufferSize)
        }
        
        offsets.withUnsafeBytes { (b) in
            if let p = b.baseAddress {
                buffer?.baseAddress?.advanced(by: offset).copyBytes(from: p, count: b.count)
            }
            offset += b.count
        }
        
        types.map{$0.rawValue}.withUnsafeBytes { (b) in
            if let p = b.baseAddress {
                buffer?.baseAddress?.advanced(by: offset).copyBytes(from: p, count: b.count)
            }
            offset += b.count
        }
        if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
            buffer?.baseAddress?.advanced(by: offset).storeBytes(of: 224, as: UInt8.self)
            buffer?.baseAddress?.advanced(by: offset + 1).storeBytes(of: UInt8(compartments.count), as: UInt8.self)
        } else {
            buffer?.baseAddress?.advanced(by: offset).storeBytes(of: UInt8(compartments.count), as: UInt8.self)
            buffer?.baseAddress?.advanced(by: offset + 1).storeBytes(of: 224, as: UInt8.self)
        }
    }
    
    /// Intialise ByteCabinet from data
    /// ByteCabinet will hold a reference to the data instance.
    public init(data: Data) throws {
        size = UInt32(data.count)
        guard size < UInt32.max else {
            throw ByteCabinetError.totalSizeExceeds4GB
        }
        
        let number = try numberOfCompartments(first: data[data.count - 2], second: data[data.count - 1])
        let footerSize = 2 + number + (number * 8)
        guard data.count > footerSize else {
            throw ByteCabinetError.internalError
        }
        let footerData = data.advanced(by: data.count - footerSize)
        
        let metrics = try compartmentMetrics(data: footerData, number: number)
        
        for m in metrics {
            compartments.append(try compartmentFrom(data: data, metric: m))
        }
        self._data = data
        buffer = data.withUnsafeBytes({ (p: UnsafePointer<UInt8>) -> UnsafeMutableRawBufferPointer in
            return UnsafeMutableRawBufferPointer(UnsafeMutableBufferPointer(start: UnsafeMutablePointer(mutating: p), count: data.count))
        })
    }
    
    /// Intialise ByteCabinet from file URL
    public init(url: URL) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        fileHandle.seekToEndOfFile()
        guard fileHandle.offsetInFile < UInt64(UInt32.max) else {
            throw ByteCabinetError.totalSizeExceeds4GB
        }
        size = UInt32(fileHandle.offsetInFile)
        fileHandle.seek(toFileOffset: UInt64(size - 2))
        let checkAndSizeData = fileHandle.readData(ofLength: 2)
        let number = try numberOfCompartments(first: checkAndSizeData[0], second: checkAndSizeData[1])
        let footerSize = 2 + number + (number * 8)
        guard size > footerSize else {
            throw ByteCabinetError.internalError
        }
        fileHandle.seek(toFileOffset: UInt64(size) - UInt64(footerSize))
        let footerData = fileHandle.readData(ofLength: footerSize - 2)
        let metrics = try compartmentMetrics(data: footerData, number: number)
        for m in metrics {
            compartments.append(try compartmentFrom(url: url, metric: m))
        }
        _data = nil
        buffer = nil
        self.url = url
    }
    
    deinit {
        if data == nil {
            buffer?.deallocate()
        }
    }
    
    public func compartment<T: Compartment>(_ index: UInt8) -> T? {
        let index = Int(index)
        guard index < compartments.count else {
            return nil
        }
        return compartments[index] as? T
    }
    
    public func compartment<T: Compartment>(_ index: UInt8, _ type: T.Type) -> T? {
        let index = Int(index)
        guard index < compartments.count else {
            return nil
        }
        return compartments[index] as? T
    }
    
    public var data: Data?  {
        if let url = url {
            return try?Data(contentsOf: url)
        }
        if let p = buffer?.baseAddress, let count = buffer?.count {
            return Data(bytesNoCopy: p, count: count, deallocator: .none)
        }
        return nil
    }
    
    public var compactedData: Data {
        var result = Data()
        
        var offset = UInt32(0)
        var offsets = [UInt32]()
        for c in self.compartments {
            let (d, s1, s2) = c.compactedDataAndSizes
            result.append(d)
            offset += s1
            offsets.append(offset)
            offset += s2
            offsets.append(offset)
        }
        
        for o in offsets {
            var offset = o
            withUnsafeBytes(of: &offset, {
                result.append(contentsOf: $0)
            })
        }
        
        if let buffer = buffer, let p = buffer.baseAddress {
            let p1 = p.advanced(by: buffer.count - 2 - compartments.count)
            result.append(p1.assumingMemoryBound(to: UInt8.self), count: 2 + compartments.count)
        } else if let url = url, let handle = try?FileHandle(forReadingFrom: url) {
            handle.seekToEndOfFile()
            let fileSize = handle.offsetInFile
            handle.seek(toFileOffset: fileSize - 2 - UInt64(compartments.count))
            let d = handle.readData(ofLength: 2 + compartments.count)
            result.append(d)
        }
        
        return result
    }
}

private func computeTotalBufferSize(_ compartments: [_Compartment]) throws -> UInt32 {
    guard compartments.count <= 200 else {
        throw ByteCabinetError.moreThan200Comaprtments
    }
    
    let bytesForNumberOfCabinetsAndCheckSum = 2
    let bytesForCompartmentTypes = compartments.count
    let bytesForCompartmentOffsets = compartments.count * 2 * 4
    var result = bytesForNumberOfCabinetsAndCheckSum + bytesForCompartmentTypes + bytesForCompartmentOffsets
    let max = Int(UInt32.max)
    for c in compartments {
        result += Int(c.indexBufferSize) + Int(c.dataBufferSize)
        if result > max {
            throw ByteCabinetError.totalSizeExceeds4GB
        }
    }
    return UInt32(result)
}

private func numberOfCompartments(first: UInt8, second: UInt8) throws -> Int {
    let number: Int
    if CFByteOrderGetCurrent() == Int(CFByteOrderLittleEndian.rawValue) {
        guard first == 224 else {
            throw ByteCabinetError.internalError
        }
        number = Int(second)
    } else {
        guard second == 224 else {
            throw ByteCabinetError.internalError
        }
        number = Int(first)
    }
    return number
}

struct CompartmentMetric {
    let offset1: UInt32
    let length1: UInt32
    let offest2: UInt32
    let length2: UInt32
    let type: CompartmentType
}

extension CompartmentMetric {
    var compartment: _Compartment? {
        let comp: _Compartment?
        switch self.type {
        case .bool:
            comp = BoolCompartment(capacity: (self.length1 - 4) * 8)
        case .string:
            comp = StringCompartment(capacity: (self.length1 - 4) / 4, dataSize: self.length2 - 4)
        case .data:
            comp = DataCompartment(capacity: (self.length1 - 8) / 8, dataSize: self.length2 - 4)
        case .f32:
            comp = NumericCompartment(capacity: (self.length1 - 4) / 4, type: Float32.self)
        case .f64:
            comp = NumericCompartment(capacity: (self.length1 - 8) / 8, type: Float64.self)
        case .i8:
            comp = NumericCompartment(capacity: (self.length1 - 4), type: Int8.self)
        case .i16:
            comp = NumericCompartment(capacity: (self.length1 - 4) / 2, type: Int16.self)
        case .i32:
            comp = NumericCompartment(capacity: (self.length1 - 4) / 4, type: Int32.self)
        case .i64:
            comp = NumericCompartment(capacity: (self.length1 - 8) / 8, type: Int64.self)
        case .u8:
            comp = NumericCompartment(capacity: (self.length1 - 4), type: UInt8.self)
        case .u16:
            comp = NumericCompartment(capacity: (self.length1 - 4) / 2, type: UInt16.self)
        case .u32:
            comp = NumericCompartment(capacity: (self.length1 - 4) / 4, type: UInt32.self)
        case .u64:
            comp = NumericCompartment(capacity: (self.length1 - 8) / 8, type: UInt64.self)
        default:
            comp = nil
        }
        return comp
    }
}

private func compartmentMetrics(data: Data, number: Int) throws -> [CompartmentMetric] {
    var result = [CompartmentMetric]()
    var offset1 : UInt32 = 0
    try data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
        for i in 0..<number {
            let end1 = p.advanced(by: (i*2) * 4).withMemoryRebound(to: UInt32.self, capacity: 1, {
                return $0.pointee
            })
            let end2 = p.advanced(by: (i*2+1) * 4).withMemoryRebound(to: UInt32.self, capacity: 1, {
                return $0.pointee
            })
            let type = p.advanced(by: number * 8 + i).pointee
            guard let cType = CompartmentType(rawValue: type) else {
                throw ByteCabinetError.internalError
            }
            let metric = CompartmentMetric(offset1: offset1, length1: end1 - offset1, offest2: end1, length2: end2-end1, type: cType)
            offset1 = end2
            result.append(metric)
        }
    }
    return result
}

private func compartmentFrom(data: Data, metric: CompartmentMetric) throws -> _Compartment {
    
    guard let compartment = metric.compartment as? InMemoryCompartment else {
        throw ByteCabinetError.internalError
    }
    data.withUnsafeBytes({ (p: UnsafePointer<UInt8>) in
        compartment.assignMemoryReaders(UnsafeRawPointer(p.advanced(by: Int(metric.offset1))))
    })
    guard let result = compartment as? _Compartment else {
        throw ByteCabinetError.internalError
    }
    return result
}

private func compartmentFrom(url: URL, metric: CompartmentMetric) throws -> _Compartment {
    
    guard let compartment = metric.compartment as? InFileCompartment else {
        throw ByteCabinetError.internalError
    }
    let handle = try FileHandle(forReadingFrom: url)
    try compartment.assignFileReaders(handle, metric.offset1)
    guard let result = compartment as? _Compartment else {
        throw ByteCabinetError.internalError
    }
    return result
}
