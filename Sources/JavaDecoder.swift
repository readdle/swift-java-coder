//
//  JavaDecoder.swift
//  jniBridge
//
//  Created by Andrew on 10/19/17.
//

import Foundation
import java_swift
import AnyCodable

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
            let value = try unbox(type: type, javaObject: javaObject)
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
            return KeyedDecodingContainer(JavaObjectContainer(decoder: self, jniStorage: storageObject))
        case .anyCodable:
            return KeyedDecodingContainer(JavaAnyCodableContainer(decoder: self, jniStorage: storageObject))
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
                NSLog("Ignore error: \(error)")
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
            let classname: String
            if type == AnyCodable.self {
                var locals = [jobject]()
                let cls = JNI.api.GetObjectClass(JNI.env, javaObject)!
                let javaTypename = key.stringValue.localJavaObject(&locals)
                let field = JNI.CallObjectMethod(cls, methodID: ClassGetFieldMethod, args: [jvalue(l: javaTypename)])!
                let fieldClass = JNI.CallObjectMethod(field, methodID: FieldGetTypedMethod, args: [])!
                let javaClassName = JNI.api.CallObjectMethodA(JNI.env, fieldClass, ClassGetNameMethod, nil)!
                classname = String(javaObject: javaClassName).replacingOccurrences(of: ".", with: "/")
                JNI.DeleteLocalRef(cls)
                JNI.DeleteLocalRef(field)
                JNI.DeleteLocalRef(fieldClass)
                JNI.DeleteLocalRef(javaClassName)
                _ = JNI.check(Void.self, &locals)
            }
            else {
                classname = self.decoder.getJavaClassname(forType: type)
            }

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
        self.decoder.storage.append(self.jniStorage)
        return self.decoder
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
    let javaIterator: jobject
    
    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.jniStorage = jniStorage
        self.count = Int(JNI.CallIntMethod(jniStorage.javaObject, methodID: CollectionSizeMethod))
        self.javaIterator = JNI.CallObjectMethod(jniStorage.javaObject, methodID: CollectionIteratorMethod)!
    }

    deinit {
        JNI.DeleteLocalRef(javaIterator)
    }
    
    func decodeNil() throws -> Bool {
        throw JavaCodingError.notSupported("JavaUnkeyedDecodingContainer.decodeNil")
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard let object = JNI.CallObjectMethod(self.javaIterator, methodID: IteratorNextMethod) else {
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

fileprivate class JavaAnyCodableContainer<K : CodingKey> : KeyedDecodingContainerProtocol {
    typealias Key = K

    var codingPath = [CodingKey]()
    var allKeys = [K]()

    let decoder: JavaDecoder
    let jniStorage: JNIStorageObject
    let jniCodableType: JNIStorageType

    fileprivate init(decoder: JavaDecoder, jniStorage: JNIStorageObject) {
        self.decoder = decoder
        self.jniStorage = jniStorage
        switch jniStorage.type {
            case let .anyCodable(codable):
                self.jniCodableType = codable
            default:
                fatalError("Only .anyCodable supported here")
        }
    }

    func contains(_ key: K) -> Bool {
        return true
    }

    func decodeNil(forKey key: K) throws -> Bool {
        throw JavaCodingError.notSupported("JavaObjectContainer.decodeNil(forKey: \(key)")
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T : Decodable {
        if key.stringValue == "typeName" {
            switch jniCodableType {
            case let .object(className):
                let typeName: String
                // Check if classname registered in JavaCoderConfig
                if let defaultTypeName = JavaCoderConfig.typeName(from: className) {
                    typeName = defaultTypeName
                }
                // if not use ClassName as Swift type name
                else {
                    typeName = String(className.split(separator: "/").last!)
                }
                return typeName as! T
            case .array:
                return  AnyCodable.ArrayTypeName as! T
            case .dictionary:
                return  AnyCodable.DictionaryTypeName as! T
            default:
                fatalError("Unsupported type here")
            }
        }
        else if key.stringValue == "value" {
            return try self.decoder.unbox(type: type, javaObject: self.jniStorage.javaObject)
        }
        else {
            fatalError("Unknown key: \(key.stringValue)")
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw JavaCodingError.notSupported("JavaAnyCodableContainer.nestedContainer(keyedBy: \(type), forKey: \(key))")
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        switch jniCodableType {
        case .array:
            return JavaArrayContainer(decoder: self.decoder, jniStorage: self.jniStorage)
        case .dictionary:
            return try JavaHashMapUnkeyedContainer(decoder: self.decoder, jniStorage: self.jniStorage)
        default:
            fatalError("Unsupported type here")
        }
    }

    func superDecoder() throws -> Decoder {
        throw JavaCodingError.notSupported("JavaAnyCodableContainer.superDecoder")
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        throw JavaCodingError.notSupported("JavaAnyCodableContainer.superDecoder(forKey: \(key)")
    }
}

extension JavaDecoder {
    
    fileprivate func unbox<T: Decodable>(type: T.Type, javaObject: jobject) throws -> T {
        let typeName = String(describing: type)
        if let decodableClosure = JavaCoderConfig.decodableClosures[typeName] {
            return try decodableClosure(javaObject) as! T
        }
        else if type == AnyCodable.self {
            let cls = JNI.api.GetObjectClass(JNI.env, javaObject)
            let javaClassName = JNI.api.CallObjectMethodA(JNI.env, cls, ClassGetNameMethod, nil)
            let className = String(javaObject: javaClassName).replacingOccurrences(of: ".", with: "/")
            JNI.DeleteLocalRef(cls)
            JNI.DeleteLocalRef(javaClassName)
            let codableType: JNIStorageType
            if className == ArrayListClassname {
                codableType = .array(className: ArrayListClassname)
            }
            else if className == HashSetClassname {
                codableType = .array(className: HashSetClassname)
            }
            else if className == HashMapClassname {
                codableType = .dictionary
            }
            else {
                codableType = .object(className: className)
            }
            let obj = JNI.api.NewLocalRef(JNI.env, javaObject)!
            let storageObject = JNIStorageObject(type: .anyCodable(codable: codableType), javaObject: obj)
            self.storage.append(storageObject)
            return try T.init(from: self)
        }
        else {
            let stringType = "\(type)"
            let storageObject: JNIStorageObject
            let obj = JNI.api.NewLocalRef(JNI.env, javaObject)!
            switch stringType {
            case _ where stringType.starts(with: "Array<"):
                storageObject = JNIStorageObject(type: .array(className: ArrayListClassname), javaObject: obj)
            case _ where stringType.starts(with: "Set<"):
                storageObject = JNIStorageObject(type: .array(className: HashSetClassname), javaObject: obj)
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
        let typeName = String(describing: forType)
        if let className = JavaCoderConfig.codableClassNames[typeName] {
            return className
        }
        else if "\(forType)".starts(with: "Array<") {
            return ArrayListClassname
        }
        else if "\(forType)".starts(with: "Set<") {
            return HashSetClassname
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
            return .array(className: ArrayListClassname)
        case HashSetClassname:
            return .array(className: HashSetClassname)
        case HashMapClassname:
            return .dictionary
        default:
            return .object(className: className)
        }
    }
    
}
