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
    
    public init(forPackage package: String) {
        self.package = package
    }
    
    public func decode<T : Decodable>(_ type: T.Type, from javaObject: jobject) throws -> T {
        do {
            let rootStorageType = try getJavaClassname(from: javaObject)
            self.storage.append(JNIStorageObject(type: rootStorageType, javaObject: javaObject))
            let value = try T(from: self)
            assert(self.storage.count == 0, "Missing decoding for \(self.storage.count) objects")
            return value
        }
        catch {
            // clean all reference if failed
            for storageObject in self.storage {
                JNI.api.DeleteLocalRef(JNI.env, storageObject.javaObject)
            }
            self.storage.removeAll()
            throw error
        }
    }
    
    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let storageObject = self.popInstance()
        switch storageObject.type {
        case .dictionary:
            let container = try JavaHashMapContainer<Key>(decoder: self, jniStorage: storageObject)
            return KeyedDecodingContainer(container)
        case .object:
            return KeyedDecodingContainer.init(JavaObjectContainer(decoder: self, jniStorage: storageObject))
        default:
            fatalError("Only keyed container supported here")
        }
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let storageObject = self.popInstance()
        switch storageObject.type {
        case .array:
            return JavaUnkeyedDecodingContainer(decoder: self, jniStorage: storageObject)
        default:
            fatalError("Only unkeyed container supported here")
        }
        
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return JavaSingleValueDecodingContainer()
    }
    
}

fileprivate class JavaObjectContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
        typealias Key = K
    
    var codingPath = [CodingKey]()
    var allKeys = [K]()
    
    let decoder: JavaDecoder
    let javaObject: jobject
    let javaClass: String
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.javaObject = jniStorage.javaObject
        switch jniStorage.type {
        case let .object(className):
            self.javaClass = className
        default:
            fatalError("Wrong container type")
        }
    }
    
    deinit {
        JNI.api.DeleteLocalRef(JNI.env, self.javaObject)
    }
    
    func contains(_ key: K) -> Bool {
        return true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        throw JavaCodingError.notSupported
    }
    
    func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "Z")
        return JNI.api.GetBooleanField(JNI.env, javaObject, fieldID) == JNI_TRUE
    }
    
    func decode(_ type: Int.Type, forKey key: K) throws -> Int {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "J")
        return Int(JNI.api.GetLongField(JNI.env, javaObject, fieldID))
    }
    
    func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "B")
        return JNI.api.GetByteField(JNI.env, javaObject, fieldID)
    }
    
    func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "S")
        return JNI.api.GetShortField(JNI.env, javaObject, fieldID)
    }
    
    func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "I")
        return Int32(JNI.api.GetIntField(JNI.env, javaObject, fieldID))
    }
    
    func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "J")
        return JNI.api.GetLongField(JNI.env, javaObject, fieldID)
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        guard let result = try decodeIfPresent(type, forKey: key) else {
            throw JavaCodingError.nilNotSupported("\(javaClass).\(key.stringValue)")
        }
        return result
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        guard let result = try decodeIfPresent(type, forKey: key) else {
            throw JavaCodingError.nilNotSupported("\(javaClass).\(key.stringValue)")
        }
        return result
    }
    
    public func decodeIfPresent(_ type: String.Type, forKey key: K) throws -> String? {
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "L\(JavaStringClassname);")
        let object = JNI.api.GetObjectField(JNI.env, javaObject, fieldID)
        let str = String(javaObject: object)
        JNI.api.DeleteLocalRef(JNI.env, object)
        return str
    }
    
    public func decodeIfPresent<T>(_ type: T.Type, forKey key: K) throws -> T? where T : Decodable {
        let sig = self.decoder.getSig(forType: type)
        let fieldID = try getJavaField(forClass: javaClass, field: key.stringValue, sig: sig)
        guard let object = JNI.api.GetObjectField(JNI.env, javaObject, fieldID) else {
            throw JavaCodingError.cantFindObject("\(javaClass).\(key.stringValue)")
        }
        self.decoder.pushObject(object, forType: type)
        return try T(from: self.decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        throw JavaCodingError.notSupported
    }
}

fileprivate class JavaHashMapContainer<K : CodingKey>: KeyedDecodingContainerProtocol {
        typealias Key = K

    var codingPath = [CodingKey]()
    var allKeys = [K]()
    
    private let decoder: JavaDecoder
    private let javaObject: jobject
    private let javaKeys: [String: jobject]
    private let getMethod: jmethodID
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) throws {
        self.decoder = decoder
        self.javaObject = jniStorage.javaObject
        self.getMethod = try getJavaMethod(forClass: JavaHashMapClassname, method: "get", sig: "(L\(JavaObjectClassname);)L\(JavaObjectClassname);")
        
        // read all keys from HashMap
        let keySetMethodID = try getJavaMethod(forClass: JavaHashMapClassname, method: "keySet", sig: "()L\(JavaSetClassname);")
        let toArrayMethodID = try getJavaMethod(forClass: JavaSetClassname, method: "toArray", sig: "()[L\(JavaObjectClassname);")
        
        let keySet = JNI.api.CallObjectMethodA(JNI.env, javaObject, keySetMethodID, nil)
        let keyArray = JNI.api.CallObjectMethodA(JNI.env, keySet, toArrayMethodID, nil)
        
        var javaKeys = [String: jobject]()
        let size = JNI.api.GetArrayLength(JNI.env, keyArray)
        
        for i in 0 ..< size {
            guard let object = JNI.api.GetObjectArrayElement(JNI.env, keyArray, i) else {
                throw JavaCodingError.wrongArrayLength
            }
            let key = String(javaObject: object)
            javaKeys[key] = object
            allKeys.append(K(stringValue: key)!)
        }
        
        JNI.api.DeleteLocalRef(JNI.env, keySet)
        JNI.api.DeleteLocalRef(JNI.env, keyArray)
        
        self.javaKeys = javaKeys
    }
    
    deinit {
        for (_, value) in self.javaKeys {
           JNI.api.DeleteLocalRef(JNI.env, value)
        }
        JNI.api.DeleteLocalRef(JNI.env, self.javaObject)
    }
    
    func contains(_ key: K) -> Bool {
        return true
    }
    
    func decodeNil(forKey key: K) throws -> Bool {
        throw JavaCodingError.notSupported
    }
    
    func decode(_ type: String.Type, forKey key: K) throws -> String {
        var javaKeyValue = jvalue.init(l: self.javaKeys[key.stringValue])
        let object = withUnsafePointer(to: &javaKeyValue, { ptr in
            return JNI.api.CallObjectMethodA(JNI.env, self.javaObject, getMethod, ptr)
        })
        let str = String(javaObject: object)
        JNI.api.DeleteLocalRef(JNI.env, object)
        return str
    }
    
    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        if type == String.self {
            return try decode(String.self, forKey: key) as! T
        }
        var javaKeyValue = jvalue.init(l: self.javaKeys[key.stringValue])
        guard let object = withUnsafePointer(to: &javaKeyValue, { ptr in
            return JNI.api.CallObjectMethodA(JNI.env, self.javaObject, getMethod, ptr)
        }) else {
            throw JavaCodingError.cantFindObject("HashMap[\(key.stringValue)]")
        }
        self.decoder.pushObject(object, forType: type)
        return try T(from: self.decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported
    }
    
    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported
    }
    
    func superDecoder(forKey key: K) throws -> Decoder {
        throw JavaCodingError.notSupported
    }
}

fileprivate class JavaUnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    var codingPath = [CodingKey]()
    
    var count: Int?
    
    var isAtEnd: Bool {
        return self.count == self.currentIndex
    }
    
    var currentIndex: Int = 0
    
    let decoder: JavaDecoder
    let javaObject: jobject
    var unsafePointer: UnsafeMutableRawPointer? // Copied array of elements (only for primitive types)
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.javaObject = jniStorage.javaObject
        self.count = Int(JNI.api.GetArrayLength(JNI.env, jniStorage.javaObject))
    }
    
    deinit {
        JNI.api.DeleteLocalRef(JNI.env, self.javaObject)
    }
    
    func decodeNil() throws -> Bool {
        throw JavaCodingError.notSupported
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        guard let arrayElements = arrayElements(JNI.api.GetLongArrayElements) else {
            throw JavaCodingError.wrongArrayLength
        }
        let result = arrayElements.advanced(by: self.currentIndex).pointee
        currentIndex += 1
        return Int(result)
    }
    
    func decode(_ type: String.Type) throws -> String {
        let obj = JNI.api.GetObjectArrayElement(JNI.env, javaObject, jsize(self.currentIndex))
        currentIndex += 1
        defer {
            JNI.api.DeleteLocalRef(JNI.env, obj)
        }
        return String(javaObject: obj)
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        if type == String.self {
            return try decode(String.self) as! T
        }
        if type == Int.self {
            return try decode(Int.self) as! T
        }
        guard let obj = JNI.api.GetObjectArrayElement(JNI.env, javaObject, jsize(self.currentIndex)) else {
            throw JavaCodingError.cantFindObject("\(type)[\(self.currentIndex)]")
        }
        self.decoder.pushObject(obj, forType: type)
        currentIndex += 1
        return try T(from: self.decoder)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        throw JavaCodingError.notSupported
    }
    
    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported
    }
    
    fileprivate func arrayElements<T>(_ getArrayElementsBlock: (UnsafeMutablePointer<JNIEnv?>?, jobject?, UnsafeMutablePointer<jboolean>?) -> UnsafeMutablePointer<T>?) -> UnsafeMutablePointer<T>? {
        if let unsafePointer = self.unsafePointer {
            return unsafePointer.assumingMemoryBound(to: T.self)
        }
        let unsafePointer = getArrayElementsBlock(JNI.env, javaObject, nil)
        self.unsafePointer = UnsafeMutableRawPointer(unsafePointer)
        return unsafePointer
    }
}

fileprivate class JavaSingleValueDecodingContainer: SingleValueDecodingContainer {
    var codingPath: [CodingKey] = []
    
    func decodeNil() -> Bool {
        fatalError("Unsupported")
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        throw JavaCodingError.notSupported
    }
}

extension JavaDecoder {
    
    fileprivate func getSig<T>(forType: T.Type) -> String{
        if T.self == [String].self {
            return "[L\(JavaStringClassname);"
        }
        if T.self == [Int].self {
            return "[J"
        }
        if "\(forType)".starts(with: "Array<") {
            let subType = String("\(forType)".dropFirst(6)).dropLast(1)
            return "[L\(package)/\(subType);"
        }
        if "\(forType)".starts(with: "Dictionary<") {
            return "L\(JavaHashMapClassname);"
        }
        return "L\(package)/\(forType);"
    }
    
    fileprivate func parseType<Str: StringProtocol>(_ stringType: Str) -> JNIStorageType {
        switch stringType {
        case "Int":
            return .primitive(name: "J")
        case _ where stringType.starts(with: "Array<"):
            let subType = String(stringType.dropFirst(6)).dropLast(1)
            return .array(type: parseType(subType))
        case _ where stringType.starts(with: "Dictionary<"):
            return .dictionary
        default:
            return .object(className: "\(package)/\(stringType)")
        }
    }
    
    fileprivate func pushObject<T>(_ obj: jobject, forType type: T.Type) {
        self.storage.append(JNIStorageObject(type: parseType("\(type)"), javaObject: obj))
    }
    
    fileprivate func popInstance() -> JNIStorageObject {
        guard let javaObject = self.storage.popLast() else {
            preconditionFailure("No instances in stack")
        }
        return javaObject
    }
    
    fileprivate func getJavaClassname(from obj: jobject) throws -> JNIStorageType {
        let cls = JNI.api.GetObjectClass(JNI.env, obj)
        let mid = try getJavaMethod(forClass: JavaClassClassname, method: "getName", sig: "()L\(JavaStringClassname);")
        let javaClassName = JNI.api.CallObjectMethodA(JNI.env, cls, mid, nil)
        let className = String(javaObject: javaClassName).replacingOccurrences(of: ".", with: "/")
        JNI.api.DeleteLocalRef(JNI.env, javaClassName)
        if className.starts(with: "[") {
            let subClassname = String(className.dropFirst(2)).dropLast(1)
            // TODO: write parseSig func
            return JNIStorageType.array(type: JNIStorageType.object(className: String(subClassname)))
        }
        return JNIStorageType.object(className: className)
    }
    
}
