//
//  JavaDecoder.swift
//  jniBridge
//
//  Created by Andrew on 10/19/17.
//

import Foundation
import java_swift

public class JavaDecoder: Decoder {
    
    public var codingPath = [CodingKey]()
    
    public var userInfo = [CodingUserInfoKey : Any]()
    
    fileprivate var storage = [JNIStorageObject]()
    fileprivate let package: String
    fileprivate let missingFieldsStrategy: MissingFieldsStrategy
    
    public init(forPackage package: String, missingFieldsStrategy: MissingFieldsStrategy = .throw) {
        self.package = package
        self.missingFieldsStrategy = missingFieldsStrategy
    }
    
    public func decode<T : Decodable>(_ type: T.Type, from javaObject: jobject) throws -> T {
        do {
            let rootStorageType = getJavaClassname(from: javaObject)
            self.storage.append(JNIStorageObject(type: rootStorageType, javaObject: JNI.api.NewLocalRef(JNI.env, javaObject)!))
            let value = try T(from: self)
            assert(self.storage.count == 0, "Missing decoding for \(self.storage.count) objects")
            return value
        }
        catch {
            // clean all reference if failed
            self.storage.removeAll()
            throw error
        }
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        guard let storageObject = self.storage.popLast() else {
            throw JavaCodingError.notSupported("No instance in stask")
        }
        switch storageObject.type {
        case .dictionary:
            let container = try JavaHashMapKeyedContainer<Key>(decoder: self, jniStorage: storageObject)
            return KeyedDecodingContainer(container)
        case .object:
            return KeyedDecodingContainer.init(JavaObjectContainer(decoder: self, jniStorage: storageObject))
        default:
            fatalError("Only keyed container supported here")
        }
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard let storageObject = self.storage.popLast() else {
            throw JavaCodingError.notSupported("No instance in stask")
        }
        switch storageObject.type {
        case .dictionary:
            return try JavaHashMapUnkeyedContainer(decoder: self, jniStorage: storageObject)
        case .array:
            return JavaArrayContainer(decoder: self, jniStorage: storageObject)
        default:
            fatalError("Only unkeyed container supported here")
        }
        
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        guard let storageObject = self.storage.popLast() else {
            throw JavaCodingError.notSupported("No instance in stask")
        }
        switch storageObject.type {
        case .object:
            return JavaEnumContainer(decoder: self, jniStorage: storageObject)
        default:
            fatalError("Only object supported here")
        }
    }
    
}

fileprivate class JavaObjectContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
        typealias Key = K
    
    var codingPath = [CodingKey]()
    var allKeys = [K]()
    
    let decoder: JavaDecoder
    let jniStorage: JNIStorageObject
    let javaObject: jobject
    let javaClass: String
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.jniStorage = jniStorage
        self.javaObject = jniStorage.javaObject
        switch jniStorage.type {
        case let .object(className):
            self.javaClass = className
        default:
            fatalError("Wrong container type")
        }
    }
    
    func contains(_ key: K) -> Bool {
        return true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        throw JavaCodingError.notSupported("JavaObjectContainer.decodeNil(forKey: \(key)")
    }
    
    private func decodeWithMissingStrategy<T>(defaultValue: T, block: () throws -> T) throws -> T {
        do {
            return try block()
        }
        catch {
            if self.decoder.missingFieldsStrategy == .ignore {
                return defaultValue
            }
            else {
                throw error
            }
        }
    }
    
    public func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try decodeWithMissingStrategy(defaultValue: false) {
            return try decodeJava(type, forKey: key) ?? false
        }
    }
    
    // override all decodeIfPresent to prevent calling  decodeNil(forKey:)
    public func decodeIfPresent(_ type: Int.Type, forKey key: K) throws -> Int? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: Int8.Type, forKey key: K) throws -> Int8? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: Int16.Type, forKey key: K) throws -> Int16? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: Int32.Type, forKey key: K) throws -> Int32? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: Int64.Type, forKey key: K) throws -> Int64? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: UInt.Type, forKey key: K) throws -> UInt? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: UInt8.Type, forKey key: K) throws -> UInt8? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: UInt16.Type, forKey key: K) throws -> UInt16? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: UInt32.Type, forKey key: K) throws -> UInt32? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: UInt64.Type, forKey key: K) throws -> UInt64? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: Bool.Type, forKey key: K) throws -> Bool? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        return try self.decodeJava(type, forKey: key)
    }
    
    public func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T : Decodable {
        return try self.decodeJava(type, forKey: key)
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        guard let result = try self.decodeJava(type, forKey: key) else {
            throw JavaCodingError.nilNotSupported("\(javaClass).\(key.stringValue)")
        }
        return result
    }
    
    private func decodeJava<T>(_ type: T.Type, forKey key: K) throws -> T? where T : Decodable {
        return try decodeWithMissingStrategy(defaultValue: nil) {
            let classname = self.decoder.getJavaClassname(forType: type)
            let fieldID = try JNI.getJavaField(forClass: javaClass, field: key.stringValue, sig: "L\(classname);")
            guard let object = JNI.api.GetObjectField(JNI.env, javaObject, fieldID) else {
                return nil
            }
            defer {
                JNI.DeleteLocalRef(object)
            }
            return try self.decoder.unbox(type: type, javaObject: object)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported("JavaObjectContainer.nestedContainer(keyedBy: \(type), forKey: \(key))")
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported("JavaObjectContainer.nestedUnkeyedContainer(forKey: \(key))")
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported("JavaObjectContainer.superDecoder")
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        throw JavaCodingError.notSupported("JavaObjectContainer.superDecoder(forKey: \(key)")
    }
}

fileprivate class JavaHashMapKeyedContainer<K : CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K

    var codingPath = [CodingKey]()
    var allKeys = [K]()
    
    private let decoder: JavaDecoder
    private let jniStorage: JNIStorageObject
    private let javaObject: jobject
    
    private var javaKeys = [AnyHashable: jobject]()
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) throws {
        self.decoder = decoder
        self.jniStorage = jniStorage
        self.javaObject = jniStorage.javaObject
        
        let keySet = JNI.api.CallObjectMethodA(JNI.env, javaObject, HashMapKeySetMethod, nil)
        let keyArray = JNI.api.CallObjectMethodA(JNI.env, keySet, SetToArrayMethod, nil)
        defer {
            JNI.DeleteLocalRef(keySet)
            JNI.DeleteLocalRef(keyArray)
        }
        
        let size = JNI.api.GetArrayLength(JNI.env, keyArray)
        
        if size == 0 {
            return
        }
        
        var keySig: String?
        
        for i in 0 ..< size {
            guard let object = JNI.api.GetObjectArrayElement(JNI.env, keyArray, i) else {
                throw JavaCodingError.wrongArrayLength
            }
            if keySig == nil {
                keySig = self.decoder.getJavaClassname(from: object).sig
            }
            if keySig == "Ljava/lang/String;" {
                let stringKey = try self.decoder.unbox(type: String.self, javaObject: object)
                if let key = K(stringValue: stringKey) {
                    javaKeys[stringKey] = object
                    allKeys.append(key)
                }
            }
            else {
                let intKey = try self.decoder.unbox(type: Int.self, javaObject: object)
                if let key = K(intValue: intKey) {
                    javaKeys[intKey] = object
                    allKeys.append(key)
                }
            }
        }
    }
    
    deinit {
        for (_, javaKey) in self.javaKeys {
           JNI.DeleteLocalRef(javaKey)
        }
    }
    
    func contains(_ key: K) -> Bool {
        return true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        throw JavaCodingError.notSupported("JavaHashMapContainer.decodeNil(forKey: \(key))")
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        let typeKey: AnyHashable
        if let intValue = key.intValue {
            typeKey = intValue
        }
        else {
            typeKey = key.stringValue
        }
        
        let javaKey = javaKeys[typeKey]
        guard let object = JNI.CallObjectMethod(self.javaObject, methodID: HashMapGetMethod, args: [jvalue(l: javaKey)]) else {
            throw JavaCodingError.cantFindObject("HashMap[\(key.stringValue)]")
        }
        defer {
            JNI.DeleteLocalRef(object)
        }
        return try self.decoder.unbox(type: type, javaObject: object)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported("JavaHashMapContainer.nestedContainer(keyedBy: \(type), forKey: \(key))")
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported("JavaHashMapContainer.nestedUnkeyedContainer(forKey: \(key))")
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported("JavaHashMapContainer.superDecoder")
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        throw JavaCodingError.notSupported("JavaHashMapContainer.superDecoder(forKey: \(key))")
    }
}

fileprivate class JavaHashMapUnkeyedContainer: UnkeyedDecodingContainer {
    
    var codingPath = [CodingKey]()
    
    var count: Int?
    
    var isAtEnd: Bool {
        return self.count == self.currentIndex
    }
    
    var currentIndex: Int = 0
    
    private var index: jvalue {
        return jvalue(i: jint(currentIndex))
    }
    
    let decoder: JavaDecoder
    let jniStorage: JNIStorageObject
    let javaObject: jobject
    
    private var javaKeys: jarray
    private var javaCurrentKey: jobject?
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) throws {
        self.decoder = decoder
        self.jniStorage = jniStorage
        self.javaObject = jniStorage.javaObject
        self.count = Int(JNI.CallIntMethod(self.javaObject, methodID: HashMapSizeMethod)) * 2
        
        let keySet = JNI.api.CallObjectMethodA(JNI.env, javaObject, HashMapKeySetMethod, nil)
        javaKeys = JNI.api.CallObjectMethodA(JNI.env, keySet, SetToArrayMethod, nil)!
        defer {
            JNI.api.DeleteLocalRef(JNI.env, keySet)
        }
    }
    
    deinit {
        JNI.api.DeleteLocalRef(JNI.env, javaKeys)
    }
    
    func decodeNil() throws -> Bool {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.decodeNil")
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if let javaCurrentKey = javaCurrentKey {
            guard let object = JNI.CallObjectMethod(self.javaObject, methodID: HashMapGetMethod, args: [jvalue(l: javaCurrentKey)]) else {
                throw JavaCodingError.cantFindObject("HashMap[]")
            }
            currentIndex += 1
            defer {
                JNI.DeleteLocalRef(object)
                JNI.DeleteLocalRef(self.javaCurrentKey)
                self.javaCurrentKey = nil
            }
            return try self.decoder.unbox(type: type, javaObject: object)
        }
        else {
            guard let object = JNI.api.GetObjectArrayElement(JNI.env, javaKeys, jsize(self.currentIndex / 2)) else {
                throw JavaCodingError.wrongArrayLength
            }
            self.javaCurrentKey = object
            currentIndex += 1
            return try self.decoder.unbox(type: type, javaObject: object)
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.nestedContainer(keyedBy: \(type))")
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.nestedUnkeyedContainer")
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.superDecoder")
    }
}

fileprivate class JavaArrayContainer: UnkeyedDecodingContainer {
    
    var codingPath = [CodingKey]()
    
    var count: Int?
    
    var isAtEnd: Bool {
        return self.count == self.currentIndex
    }
    
    var currentIndex: Int = 0
    
    private var index: jvalue {
        return jvalue(i: jint(currentIndex))
    }
    
    let decoder: JavaDecoder
    let jniStorage: JNIStorageObject
    let javaObject: jobject
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.jniStorage = jniStorage
        self.javaObject = jniStorage.javaObject
        self.count = Int(JNI.CallIntMethod(self.javaObject, methodID: ArrayListSizeMethod))
    }
    
    func decodeNil() throws -> Bool {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.decodeNil")
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard let object = JNI.CallObjectMethod(self.javaObject, methodID: ArrayListGetMethod, args: [self.index]) else {
            throw JavaCodingError.cantFindObject("Array out of range: \(self.currentIndex)")
        }
        defer {
            JNI.DeleteLocalRef(object)
        }
        currentIndex += 1
        return try self.decoder.unbox(type: type, javaObject: object)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.nestedContainer(keyedBy: \(type))")
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.nestedUnkeyedContainer")
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.superDecoder")
    }
}

fileprivate class JavaEnumContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    let decoder: JavaDecoder
    let jniStorage: JNIStorageObject
    let javaObject: jobject
    let javaClass: String
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.jniStorage = jniStorage
        self.javaObject = jniStorage.javaObject
        switch jniStorage.type {
        case let .object(className):
            self.javaClass = className
        default:
            fatalError("Wrong container type")
        }
    }
    
    func decodeNil() -> Bool {
        fatalError("Unsupported: JavaEnumDecodingContainer.decodeNil")
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let classname = self.decoder.getJavaClassname(forType: type)
        let fieldID = try JNI.getJavaField(forClass: javaClass, field: "rawValue", sig: "L\(classname);")
        guard let object = JNI.api.GetObjectField(JNI.env, javaObject, fieldID) else {
            throw JavaCodingError.nilNotSupported("\(javaClass).rawValue")
        }
        defer {
            JNI.DeleteLocalRef(object)
        }
        return try self.decoder.unbox(type: type, javaObject: object)
    }
}

extension JavaDecoder {
    
    fileprivate func unbox<T: Decodable>(type: T.Type, javaObject: jobject) throws -> T {
        if type == Int.self {
            return Int(JNI.CallIntMethod(javaObject, methodID: NumberIntValueMethod)) as! T
        }
        else if type == Int8.self {
            return JNI.CallByteMethod(javaObject, methodID: NumberByteValueMethod) as! T
        }
        else if type == Int16.self {
            return JNI.CallShortMethod(javaObject, methodID: NumberShortValueMethod) as! T
        }
        else if type == Int32.self {
            return Int32(JNI.CallIntMethod(javaObject, methodID: NumberIntValueMethod)) as! T
        }
        else if type == Int64.self {
            return JNI.CallLongMethod(javaObject, methodID: NumberLongValueMethod) as! T
        }
        else if type == UInt.self {
            return UInt(JNI.CallLongMethod(javaObject, methodID: NumberLongValueMethod)) as! T
        }
        else if type == UInt8.self {
            return UInt8(JNI.CallShortMethod(javaObject, methodID: NumberShortValueMethod)) as! T
        }
        else if type == UInt16.self {
            return UInt16(JNI.CallIntMethod(javaObject, methodID: NumberIntValueMethod)) as! T
        }
        else if type == UInt32.self {
            return UInt32(JNI.CallLongMethod(javaObject, methodID: NumberLongValueMethod)) as! T
        }
        else if type == UInt64.self {
            let javaString = JNI.CallObjectMethod(javaObject, methodID: ObjectToStringMethod)
            defer {
                JNI.api.DeleteLocalRef(JNI.env, javaString)
            }
            let stringRepresentation = String(javaObject: javaString)
            return UInt64(stringRepresentation) as! T
        }
        else if type == Bool.self {
            return (JNI.CallBooleanMethod(javaObject, methodID: NumberBooleanValueMethod) == JNI.TRUE) as! T
        }
        else if type == String.self {
            return  String(javaObject: javaObject) as! T
        }
        else if type == Date.self {
            let timeInterval = JNI.api.CallLongMethodA(JNI.env, javaObject, DateGetTimeMethod, nil)
            // Java save TimeInterval in UInt64 milliseconds
            return Date(timeIntervalSince1970: TimeInterval(timeInterval) / 1000.0) as! T
        }
        else if type == URL.self {
            let pathString = JNI.api.CallObjectMethodA(JNI.env, javaObject, ObjectToStringMethod, nil)
            return URL(string: String(javaObject: pathString)) as! T
        }
        else {
            let stringType = "\(type)"
            let storageObject: JNIStorageObject
            let obj = JNI.api.NewLocalRef(JNI.env, javaObject)!
            switch stringType {
            case _ where stringType.starts(with: "Array<"):
                storageObject = JNIStorageObject(type: .array, javaObject: obj)
            case _ where stringType.starts(with: "Dictionary<"):
                storageObject = JNIStorageObject(type: .dictionary, javaObject: obj)
            default:
                storageObject = JNIStorageObject(type: .object(className: "\(package)/\(type)"), javaObject: obj)
            }
            self.storage.append(storageObject)
            return try T.init(from: self)
        }
    }
    
    fileprivate func getJavaClassname<T>(forType: T.Type) -> String {
        if T.self == Int.self {
            return IntegerClassname
        }
        else if T.self == Int8.self {
            return ByteClassname
        }
        else if T.self == Int16.self {
            return ShortClassname
        }
        else if T.self == Int32.self {
            return IntegerClassname
        }
        else if T.self == Int64.self {
            return LongClassname
        }
        else if T.self == UInt.self {
            return LongClassname
        }
        else if T.self == UInt8.self {
            return ShortClassname
        }
        else if T.self == UInt16.self {
            return IntegerClassname
        }
        else if T.self == UInt32.self {
            return LongClassname
        }
        else if T.self == UInt64.self {
            return BigIntegerClassname
        }
        else if T.self == Bool.self {
            return BooleanClassname
        }
        else if T.self == String.self {
            return StringClassname
        }
        else if T.self == Date.self {
            return DateClassname
        }
        else if T.self == URL.self {
            return UriClassname
        }
        else if "\(forType)".starts(with: "Array<") {
            return ArrayListClassname
        }
        else if "\(forType)".starts(with: "Dictionary<") {
            return HashMapClassname
        }
        else {
            return "\(package)/\(forType)"
        }
    }
    
    fileprivate func getJavaClassname(from obj: jobject) -> JNIStorageType {
        let cls = JNI.api.GetObjectClass(JNI.env, obj)
        let javaClassName = JNI.api.CallObjectMethodA(JNI.env, cls, ClassGetNameMethod, nil)
        let className = String(javaObject: javaClassName).replacingOccurrences(of: ".", with: "/")
        JNI.DeleteLocalRef(cls)
        JNI.DeleteLocalRef(javaClassName)
        switch className {
        case ArrayListClassname:
            return .array
        case HashMapClassname:
            return .dictionary
        default:
            return .object(className: className)
        }
    }
    
}
