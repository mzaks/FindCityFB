// generated with FlatBuffersSchemaEditor https://github.com/mzaks/FlatBuffersSchemaEditor

public final class CityList {
    public var cityByCountryCode : [City?] = []
    public var cityByName : [City?] = []
    public init(){}
    public init(cityByCountryCode: [City?], cityByName: [City?]){
        self.cityByCountryCode = cityByCountryCode
        self.cityByName = cityByName
    }
}
public extension CityList {
    private static func create(reader : FlatBufferReader, objectOffset : Offset?) -> CityList? {
        guard let objectOffset = objectOffset else {
            return nil
        }
        let _result = CityList()
        let offset_cityByCountryCode : Offset? = reader.getOffset(objectOffset, propertyIndex: 0)
        let length_cityByCountryCode = reader.getVectorLength(offset_cityByCountryCode)
        if(length_cityByCountryCode > 0){
            var index = 0
            while index < length_cityByCountryCode {
                _result.cityByCountryCode.append(City.create(reader, objectOffset: reader.getVectorOffsetElement(offset_cityByCountryCode!, index: index)))
                index += 1
            }
        }
        let offset_cityByName : Offset? = reader.getOffset(objectOffset, propertyIndex: 1)
        let length_cityByName = reader.getVectorLength(offset_cityByName)
        if(length_cityByName > 0){
            var index = 0
            while index < length_cityByName {
                _result.cityByName.append(City.create(reader, objectOffset: reader.getVectorOffsetElement(offset_cityByName!, index: index)))
                index += 1
            }
        }
        return _result
    }
}
public extension CityList {
    public static func fromByteArray(data : UnsafePointer<UInt8>) -> CityList {
        let reader = FlatBufferReader(bytes: data)
        let objectOffset = reader.rootObjectOffset
        return create(reader, objectOffset : objectOffset)!
    }
}
public extension CityList {
    public var toByteArray : [UInt8] {
        let builder = FlatBufferBuilder()
        return try! builder.finish(addToByteArray(builder), fileIdentifier: nil)
    }
}
public extension CityList {
    public final class LazyAccess{
        private let _reader : FlatBufferReader!
        private let _objectOffset : Offset!
        public init(data : UnsafePointer<UInt8>){
            _reader = FlatBufferReader(bytes: data)
            _objectOffset = _reader.rootObjectOffset
        }
        private init?(reader : FlatBufferReader, objectOffset : Offset?){
            guard let objectOffset = objectOffset else {
                _reader = nil
                _objectOffset = nil
                return nil
            }
            _reader = reader
            _objectOffset = objectOffset
        }
        
        public lazy var cityByCountryCode : LazyVector<City.LazyAccess> = {
            let vectorOffset : Offset? = self._reader.getOffset(self._objectOffset, propertyIndex: 0)
            let vectorLength = self._reader.getVectorLength(vectorOffset)
            return LazyVector(count: vectorLength){
                City.LazyAccess(reader: self._reader, objectOffset : self._reader.getVectorOffsetElement(vectorOffset!, index: $0))
            }
        }()
        public lazy var cityByName : LazyVector<City.LazyAccess> = {
            let vectorOffset : Offset? = self._reader.getOffset(self._objectOffset, propertyIndex: 1)
            let vectorLength = self._reader.getVectorLength(vectorOffset)
            return LazyVector(count: vectorLength){
                City.LazyAccess(reader: self._reader, objectOffset : self._reader.getVectorOffsetElement(vectorOffset!, index: $0))
            }
        }()
        
        public lazy var createEagerVersion : CityList? = CityList.create(self._reader, objectOffset: self._objectOffset)
    }
}
public extension CityList {
    private static var cache : [ObjectIdentifier : Offset] = [:]
    private func addToByteArray(builder : FlatBufferBuilder) -> Offset {
        if let myOffset = CityList.cache[ObjectIdentifier(self)] {
            return myOffset
        }
        var offset1 = Offset(0)
        if cityByName.count > 0{
            var offsets = [Offset?](count: cityByName.count, repeatedValue: nil)
            var index = cityByName.count - 1
            while(index >= 0){
                offsets[index] = cityByName[index]?.addToByteArray(builder)
                index -= 1
            }
            try! builder.startVector(cityByName.count)
            index = cityByName.count - 1
            while(index >= 0){
                try! builder.putOffset(offsets[index])
                index -= 1
            }
            offset1 = builder.endVector()
        }
        var offset0 = Offset(0)
        if cityByCountryCode.count > 0{
            var offsets = [Offset?](count: cityByCountryCode.count, repeatedValue: nil)
            var index = cityByCountryCode.count - 1
            while(index >= 0){
                offsets[index] = cityByCountryCode[index]?.addToByteArray(builder)
                index -= 1
            }
            try! builder.startVector(cityByCountryCode.count)
            index = cityByCountryCode.count - 1
            while(index >= 0){
                try! builder.putOffset(offsets[index])
                index -= 1
            }
            offset0 = builder.endVector()
        }
        try! builder.openObject(2)
        try! builder.addPropertyOffsetToOpenObject(1, offset: offset1)
        try! builder.addPropertyOffsetToOpenObject(0, offset: offset0)
        let myOffset =  try! builder.closeObject()
        CityList.cache[ObjectIdentifier(self)] = myOffset
        return myOffset
    }
}
public final class City {
    public var countryCode : String? = nil
    public var searchName : String? = nil
    public var name : String? = nil
    public var latitude : Float32 = 0
    public var longitude : Float32 = 0
    public init(){}
    public init(countryCode: String?, searchName: String?, name: String?, latitude: Float32, longitude: Float32){
        self.countryCode = countryCode
        self.searchName = searchName
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}
public extension City {
    private static func create(reader : FlatBufferReader, objectOffset : Offset?) -> City? {
        guard let objectOffset = objectOffset else {
            return nil
        }
        let _result = City()
        _result.countryCode = reader.getString(reader.getOffset(objectOffset, propertyIndex: 0))
        _result.searchName = reader.getString(reader.getOffset(objectOffset, propertyIndex: 1))
        _result.name = reader.getString(reader.getOffset(objectOffset, propertyIndex: 2))
        _result.latitude = reader.get(objectOffset, propertyIndex: 3, defaultValue: 0)
        _result.longitude = reader.get(objectOffset, propertyIndex: 4, defaultValue: 0)
        return _result
    }
}
public extension City {
    public final class LazyAccess{
        private let _reader : FlatBufferReader!
        private let _objectOffset : Offset!
        private init?(reader : FlatBufferReader, objectOffset : Offset?){
            guard let objectOffset = objectOffset else {
                _reader = nil
                _objectOffset = nil
                return nil
            }
            _reader = reader
            _objectOffset = objectOffset
        }
        
        public lazy var countryCode : String? = self._reader.getString(self._reader.getOffset(self._objectOffset, propertyIndex: 0))
        public lazy var searchName : String? = self._reader.getString(self._reader.getOffset(self._objectOffset, propertyIndex: 1))
        public lazy var name : String? = self._reader.getString(self._reader.getOffset(self._objectOffset, propertyIndex: 2))
        public lazy var latitude : Float32 = self._reader.get(self._objectOffset, propertyIndex: 3, defaultValue:0)
        public lazy var longitude : Float32 = self._reader.get(self._objectOffset, propertyIndex: 4, defaultValue:0)
        
        public lazy var createEagerVersion : City? = City.create(self._reader, objectOffset: self._objectOffset)
    }
}
public extension City {
    private static var cache : [ObjectIdentifier : Offset] = [:]
    private func addToByteArray(builder : FlatBufferBuilder) -> Offset {
        if let myOffset = City.cache[ObjectIdentifier(self)] {
            return myOffset
        }
        let offset2 = try! builder.createString(name)
        let offset1 = try! builder.createString(searchName)
        let offset0 = try! builder.createString(countryCode)
        try! builder.openObject(5)
        try! builder.addPropertyToOpenObject(4, value : longitude, defaultValue : 0)
        try! builder.addPropertyToOpenObject(3, value : latitude, defaultValue : 0)
        try! builder.addPropertyOffsetToOpenObject(2, offset: offset2)
        try! builder.addPropertyOffsetToOpenObject(1, offset: offset1)
        try! builder.addPropertyOffsetToOpenObject(0, offset: offset0)
        let myOffset =  try! builder.closeObject()
        City.cache[ObjectIdentifier(self)] = myOffset
        return myOffset
    }
}

// MARK: FlattBuffers infrastructure

import Foundation

// MARK: Reader


private class FlatBufferReader {
    
    let buffer : UnsafePointer<UInt8>
    
    func fromByteArray<T : Scalar>(position : Int) -> T{
        return UnsafePointer<T>(buffer.advancedBy(position)).memory
    }
    
    private init(buffer : [UInt8]){
        self.buffer = UnsafePointer<UInt8>(buffer)
    }
    
    private init(bytes : UnsafePointer<UInt8>){
        self.buffer = bytes
    }
    
    private var rootObjectOffset : Offset {
        let offset : Int32 = fromByteArray(0)
        return offset
    }
    
    private func get<T : Scalar>(objectOffset : Offset, propertyIndex : Int, defaultValue : T) -> T{
        let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return defaultValue
        }
        let position = Int(objectOffset + propertyOffset)
        return fromByteArray(position)
    }
    
    private func getStructProperty<T : Scalar>(objectOffset : Offset, propertyIndex : Int, structPropertyOffset : Int, defaultValue : T) -> T {
        let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return defaultValue
        }
        let position = Int(objectOffset + propertyOffset) + structPropertyOffset
        
        return fromByteArray(position)
    }
    
    private func hasProperty(objectOffset : Offset, propertyIndex : Int) -> Bool {
        return getPropertyOffset(objectOffset, propertyIndex: propertyIndex) != 0
    }
    
    private func getOffset(objectOffset : Offset, propertyIndex : Int) -> Offset?{
        let propertyOffset = getPropertyOffset(objectOffset, propertyIndex: propertyIndex)
        if propertyOffset == 0 {
            return nil
        }
        let position = objectOffset + propertyOffset
        let localObjectOffset : Int32 = fromByteArray(Int(position))
        let offset = position + localObjectOffset
        
        if propertyOffset == 0 {
            return nil
        }
        return offset
    }
    
    var stringCache : [Offset:String] = [:]
    private func getString(stringOffset : Offset?) -> String? {
        guard let stringOffset = stringOffset else {
            return nil
        }
        if let result = stringCache[stringOffset]{
            return result
        }
        let stringPosition = Int(stringOffset)
        let stringLenght : Int32 = fromByteArray(stringPosition)
        let pointer = UnsafeMutablePointer<UInt8>(buffer).advancedBy((stringPosition + strideof(Int32)))
        let result = String.init(bytesNoCopy: pointer, length: Int(stringLenght), encoding: NSUTF8StringEncoding, freeWhenDone: false)
        stringCache[stringOffset] = result
        return result
    }
    
    private func getVectorLength(vectorOffset : Offset?) -> Int {
        guard let vectorOffset = vectorOffset else {
            return 0
        }
        let vectorPosition = Int(vectorOffset)
        let length2 : Int32 = fromByteArray(vectorPosition)
        return Int(length2)
    }
    
    private func getVectorScalarElement<T : Scalar>(vectorOffset : Offset, index : Int) -> T {
        let valueStartPosition = Int(vectorOffset + strideof(Int32) + (index * strideof(T)))
        return UnsafePointer<T>(UnsafePointer<UInt8>(buffer).advancedBy(valueStartPosition)).memory
    }
    
    private func getVectorStructElement<T : Scalar>(vectorOffset : Offset, vectorIndex : Int, structSize : Int, structElementIndex : Int) -> T {
        let valueStartPosition = Int(vectorOffset + strideof(Int32) + (vectorIndex * structSize) + structElementIndex)
        return UnsafePointer<T>(UnsafePointer<UInt8>(buffer).advancedBy(valueStartPosition)).memory
    }
    
    private func getVectorOffsetElement(vectorOffset : Offset, index : Int) -> Offset? {
        let valueStartPosition = Int(vectorOffset + strideof(Int32) + (index * strideof(Int32)))
        let localOffset : Int32 = fromByteArray(valueStartPosition)
        if(localOffset == 0){
            return nil
        }
        return localOffset + valueStartPosition
    }
    
    private func getPropertyOffset(objectOffset : Offset, propertyIndex : Int)->Int {
        let offset = Int(objectOffset)
        let localOffset : Int32 = fromByteArray(offset)
        let vTableOffset : Int = offset - Int(localOffset)
        let vTableLength : Int16 = fromByteArray(vTableOffset)
        if(vTableLength<=Int16(4 + propertyIndex * 2)) {
            return 0
        }
        let propertyStart = vTableOffset + 4 + (2 * propertyIndex)
        
        let propertyOffset : Int16 = fromByteArray(propertyStart)
        return Int(propertyOffset)
    }
}



// MARK: Builder

private enum FlatBufferBuilderError : ErrorType {
    case ObjectIsNotClosed
    case NoOpenObject
    case PropertyIndexIsInvalid
    case OffsetIsTooBig
    case BadFileIdentifier
    case UnsupportedType
}

private class FlatBufferBuilder {
    var capacity : Int
    private var _data : UnsafeMutablePointer<UInt8>
    var data : [UInt8] {
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(_data).advancedBy(leftCursor), count: cursor))
    }
    var cursor = 0
    var leftCursor : Int {
        return capacity - cursor
    }
    
    var currentVTable : [Int32] = []
    var objectStart : Int32 = -1
    var vectorNumElems : Int32 = -1;
    var vTableOffsets : [Int32] = []
    
    private init(capacity : Int = 1){ //4_194_304
        self.capacity = capacity
        _data = UnsafeMutablePointer.alloc(capacity)
    }
    
    private func increaseCapacity(size : Int){
        guard leftCursor <= size else {
            return
        }
        let _leftCursor = leftCursor
        let _capacity = capacity
        while leftCursor <= size {
            capacity = capacity << 1
        }
        
        let newData = UnsafeMutablePointer<UInt8>.alloc(capacity)
        newData.advancedBy(leftCursor).initializeFrom(_data.advancedBy(_leftCursor), count: cursor)
        _data.dealloc(_capacity)
        _data = newData
    }
    
    private func put<T : Scalar>(value : T){
        var v = value
        if UInt32(CFByteOrderGetCurrent()) == CFByteOrderBigEndian.rawValue{
            v = value.littleEndian
        }
        let c = strideofValue(v)
        increaseCapacity(c)
        withUnsafePointer(&v){
            _data.advancedBy(leftCursor-c).initializeFrom(UnsafeMutablePointer<UInt8>($0), count: c)
        }
        cursor += c
        
    }
    
    private func putOffset(offset : Offset?) throws {
        guard let offset = offset else {
            return put(Int32(0))
        }
        guard offset <= Int32(cursor) else {
            throw FlatBufferBuilderError.OffsetIsTooBig
        }
        let _offset = Int32(cursor) - offset + strideof(Int32);
        put(_offset)
    }
    
    private func put<T : Scalar>(value : T, at index : Int){
        var v = value
        if UInt32(CFByteOrderGetCurrent()) == CFByteOrderBigEndian.rawValue{
            v = value.littleEndian
        }
        let c = strideofValue(v)
        withUnsafePointer(&v){
            _data.advancedBy(index + leftCursor).initializeFrom(UnsafeMutablePointer<UInt8>($0), count: c)
        }
    }
    
    private func openObject(numOfProperties : Int) throws {
        guard objectStart == -1 && vectorNumElems == -1 else {
            throw FlatBufferBuilderError.ObjectIsNotClosed
        }
        currentVTable = Array<Int32>(count: numOfProperties, repeatedValue: 0)
        objectStart = Int32(cursor)
    }
    
    private func addPropertyOffsetToOpenObject(propertyIndex : Int, offset : Offset) throws {
        guard objectStart > -1 else {
            throw FlatBufferBuilderError.NoOpenObject
        }
        guard propertyIndex >= 0 && propertyIndex < currentVTable.count else {
            throw FlatBufferBuilderError.PropertyIndexIsInvalid
        }
        if(offset == 0){
            return
        }
        try putOffset(offset)
        currentVTable[propertyIndex] = Int32(cursor)
    }
    
    private func addPropertyToOpenObject<T : Scalar>(propertyIndex : Int, value : T, defaultValue : T) throws {
        guard objectStart > -1 else {
            throw FlatBufferBuilderError.NoOpenObject
        }
        guard propertyIndex >= 0 && propertyIndex < currentVTable.count else {
            throw FlatBufferBuilderError.PropertyIndexIsInvalid
        }
        
        if(value == defaultValue) {
            return
        }
        
        put(value)
        currentVTable[propertyIndex] = Int32(cursor)
    }
    
    private func addCurrentOffsetAsPropertyToOpenObject(propertyIndex : Int) throws {
        guard objectStart > -1 else {
            throw FlatBufferBuilderError.NoOpenObject
        }
        guard propertyIndex >= 0 && propertyIndex < currentVTable.count else {
            throw FlatBufferBuilderError.PropertyIndexIsInvalid
        }
        currentVTable[propertyIndex] = Int32(cursor)
    }
    
    private func closeObject() throws -> Offset {
        guard objectStart > -1 else {
            throw FlatBufferBuilderError.NoOpenObject
        }
        
        increaseCapacity(4)
        cursor += 4 // Will be set to vtable offset afterwards
        
        let vtableloc = cursor
        
        // vtable is stored as relative offset for object data
        for var index = currentVTable.count - 1; index >= 0; index-- {
            // Offset relative to the start of the table.
            let off = Int16(currentVTable[index] != 0 ? Int32(vtableloc) - currentVTable[index] : 0);
            put(off);
        }
        
        let numberOfstandardFields = 2
        
        put(Int16(Int32(vtableloc) - objectStart)); // standard field 1: lenght of the object data
        put(Int16((currentVTable.count + numberOfstandardFields) * strideof(Int16))); // standard field 2: length of vtable and standard fields them selves
        
        // search if we already have same vtable
        let vtableDataLength = cursor - vtableloc
        
        var foundVTableOffset = vtableDataLength
        
        for otherVTableOffset in vTableOffsets {
            let start = cursor - Int(otherVTableOffset)
            var found = true
            for i in 0 ..< vtableDataLength {
                let a = _data.advancedBy(leftCursor + i).memory
                let b = _data.advancedBy(leftCursor + i + start).memory
                if a != b {
                    found = false
                    break;
                }
            }
            if found == true {
                foundVTableOffset = Int(otherVTableOffset) - vtableloc
                break
            }
        }
        
        if foundVTableOffset != vtableDataLength {
            cursor -= vtableDataLength
        } else {
            vTableOffsets.append(Int32(cursor))
        }
        
        let indexLocation = cursor - vtableloc
        
        put(Int32(foundVTableOffset), at: indexLocation)
        
        objectStart = -1
        
        return Offset(vtableloc)
    }
    
    private func startVector(count : Int) throws{
        guard objectStart == -1 && vectorNumElems == -1 else {
            throw FlatBufferBuilderError.ObjectIsNotClosed
        }
        vectorNumElems = Int32(count)
    }
    
    private func endVector() -> Offset {
        put(vectorNumElems)
        vectorNumElems = -1
        return Int32(cursor)
    }
    
    var stringCache : [String:Offset] = [:]
    private func createString(value : String?) throws -> Offset {
        guard objectStart == -1 && vectorNumElems == -1 else {
            throw FlatBufferBuilderError.ObjectIsNotClosed
        }
        guard let value = value else {
            return 0
        }
        if let offset = stringCache[value]{
            return offset
        }
        
        let buf = [UInt8](value.utf8)
        let length = buf.count
        
        
        _data.advancedBy(leftCursor-length).initializeFrom(UnsafeMutablePointer<UInt8>(buf), count: length)
        cursor += length
        
        put(Int32(length))
        let offset = Offset(cursor)
        
        stringCache[value] = offset
        return offset
    }
    
    private func finish(offset : Offset, fileIdentifier : String?) throws -> [UInt8] {
        guard offset <= Int32(cursor) else {
            throw FlatBufferBuilderError.OffsetIsTooBig
        }
        guard objectStart == -1 && vectorNumElems == -1 else {
            throw FlatBufferBuilderError.ObjectIsNotClosed
        }
        var prefixLength = 4
        increaseCapacity(8)
        if let fileIdentifier = fileIdentifier {
            let buf = fileIdentifier.utf8
            guard buf.count == 4 else {
                throw FlatBufferBuilderError.BadFileIdentifier
            }
            
            _data.advancedBy(leftCursor-4).initializeFrom(buf)
            prefixLength += 4
        }
        
        var v = (Int32(cursor + prefixLength) - offset).littleEndian
        let c = strideofValue(v)
        withUnsafePointer(&v){
            _data.advancedBy(leftCursor - prefixLength).initializeFrom(UnsafeMutablePointer<UInt8>($0), count: c)
        }
        
        return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(_data).advancedBy(leftCursor - prefixLength), count: cursor+prefixLength))
    }
    
    private func finish2(offset : Offset, fileIdentifier : String?) throws -> UnsafeBufferPointer<UInt8> {
        guard offset <= Int32(cursor) else {
            throw FlatBufferBuilderError.OffsetIsTooBig
        }
        guard objectStart == -1 && vectorNumElems == -1 else {
            throw FlatBufferBuilderError.ObjectIsNotClosed
        }
        var prefixLength = 4
        increaseCapacity(8)
        if let fileIdentifier = fileIdentifier {
            let buf = fileIdentifier.utf8
            guard buf.count == 4 else {
                throw FlatBufferBuilderError.BadFileIdentifier
            }
            
            _data.advancedBy(leftCursor-4).initializeFrom(buf)
            prefixLength += 4
        }
        
        var v = (Int32(cursor + prefixLength) - offset).littleEndian
        let c = strideofValue(v)
        withUnsafePointer(&v){
            _data.advancedBy(leftCursor - prefixLength).initializeFrom(UnsafeMutablePointer<UInt8>($0), count: c)
        }
        
        return UnsafeBufferPointer(start: UnsafePointer<UInt8>(_data).advancedBy(leftCursor - prefixLength), count: cursor+prefixLength)
    }
}


// MARK: General stuff

private typealias Offset = Int32

private protocol Scalar : Equatable {}

private extension Scalar {
    var littleEndian : Self {
        switch self {
        case let v as Int16 : return v.littleEndian as! Self
        case let v as UInt16 : return v.littleEndian as! Self
        case let v as Int32 : return v.littleEndian as! Self
        case let v as UInt32 : return v.littleEndian as! Self
        case let v as Int64 : return v.littleEndian as! Self
        case let v as UInt64 : return v.littleEndian as! Self
        case let v as Int : return v.littleEndian as! Self
        case let v as UInt : return v.littleEndian as! Self
        default : return self
        }
    }
}

extension Bool : Scalar {}
extension Int8 : Scalar {}
extension UInt8 : Scalar {}
extension Int16 : Scalar {}
extension UInt16 : Scalar {}
extension Int32 : Scalar {}
extension UInt32 : Scalar {}
extension Int64 : Scalar {}
extension UInt64 : Scalar {}
extension Int : Scalar {}
extension UInt : Scalar {}
extension Float32 : Scalar {}
extension Float64 : Scalar {}

public final class LazyVector<T> : SequenceType {
    private let _generator : (Int)->T?
    private let _count : Int
    
    public init(count : Int, generator : (Int)->T?){
        _generator = generator
        _count = count
    }
    
    public subscript(i: Int) -> T? {
        guard i >= 0 && i < _count else {
            return nil
        }
        return _generator(i)
    }
    
    public var count : Int {return _count}
    
    public func generate() -> AnyGenerator<T> {
        var index = 0
        
        return AnyGenerator(body: {
            let value = self[index]
            index += 1
            return value
        })
    }
}