//
//  JavaEncoder.swift
//  jniBridge
//
//  Created by Andrew on 10/14/17.
//

import Foundation
import CoreFoundation
import java_swift

public enum MissingFieldsStrategy: Error {
    case `throw`
    case ignore
}

public enum JavaCodingError: Error {
    case notSupported(String)
    case cantCreateObject(String)
    case cantFindObject(String)
    case nilNotSupported(String)
    case wrongArrayLength
}

indirect enum JNIStorageType {
    case primitive(name: String)
    case object(className: String)
    case array(type: JNIStorageType)
    case dictionary
    
    var sig: String {
        switch self {
        case .primitive(let name):
            return name
        case .array(let type):
            return "[\(type.sig)"
        case .object(let className):
            return "L\(className);"
        case .dictionary:
            return "L\(JavaHashMapClassname);"
        }
    }
}

class JNIStorageObject {
    let type: JNIStorageType
    let javaObject: jobject
    
    init(type: JNIStorageType, javaObject: jobject) {
        self.type = type
        self.javaObject = javaObject
    }
    
    deinit {
        JNI.api.DeleteLocalRef(JNI.env, javaObject)
    }
}

/// `JavaEncoder` facilitates the encoding of `Encodable` values into JSON.
open class JavaEncoder: Encoder {

    // MARK: Properties
    
    /// The path to the current point in encoding.
    public var codingPath: [CodingKey]
    
    /// Contextual user-provided information for use during encoding.
    public var userInfo: [CodingUserInfoKey : Any] {
        return [:]
    }
    
    fileprivate let package: String
    fileprivate var javaObjects: [JNIStorageObject]
    fileprivate let missingFieldsStrategy: MissingFieldsStrategy
    
    // MARK: - Constructing a JSON Encoder
    /// Initializes `self` with default strategies.
    public init(forPackage: String, missingFieldsStrategy: MissingFieldsStrategy = .throw) {
        self.codingPath = [CodingKey]()
        self.package = forPackage
        self.javaObjects = [JNIStorageObject]()
        self.missingFieldsStrategy = missingFieldsStrategy
    }
    
    // MARK: - Encoding Values
    /// Encodes the given top-level value and returns its JSON representation.
    ///
    /// - parameter value: The value to encode.
    /// - returns: A new `Data` value containing the encoded JSON data.
    /// - throws: `EncodingError.invalidValue` if a non-conforming floating-point value is encountered during encoding, and the encoding strategy is `.throw`.
    /// - throws: An error if any value throws an error during encoding.
    open func encode<T : Encodable>(_ value: T) throws -> jobject {
        do {
            let storage = try self.box(value)
            assert(self.javaObjects.count == 0, "Missing encoding for \(self.javaObjects.count) objects")
            return JNI.api.NewLocalRef(JNI.env, storage.javaObject)!
        }
        catch {
            // clean all reference if failed
            self.javaObjects.removeAll()
            throw error
        }

    }
    
    // MARK: - Encoder Methods
    public func container<Key>(keyedBy: Key.Type) -> KeyedEncodingContainer<Key> {
        let storage = self.popInstance()
        switch storage.type {
        case .dictionary:
            let container = JavaHashMapContainer<Key>(referencing: self, codingPath: self.codingPath, jniStorage: storage)
            return KeyedEncodingContainer(container)
        case let .object(className):
            let container = JavaObjectContainer<Key>(referencing: self, codingPath: self.codingPath, javaClass: className, jniStorage: storage)
            return KeyedEncodingContainer(container)
        default:
            fatalError("Only keyed containers")
        }
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        let storage = self.popInstance()
        return JavaArrayContainer(referencing: self, codingPath: self.codingPath, jniStorage: storage)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        let storage = self.popInstance()
        switch storage.type {
        case let .object(className):
            return JavaEnumValueEncodingContainer(encoder: self, javaClass: className, jniStorage: storage)
        default:
            fatalError("Only object type supported here")
        }
        
    }
}

// MARK: - Encoding Containers
fileprivate class JavaObjectContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: JavaEncoder
    
    private let javaClass: String
    private let jniStorage: JNIStorageObject
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JavaEncoder, codingPath: [CodingKey], javaClass: String, jniStorage: JNIStorageObject) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.javaClass = javaClass
        self.jniStorage = jniStorage
    }
    
    private var javaObject: jobject {
        return jniStorage.javaObject
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    public func encodeNil(forKey key: Key) throws {
        throw JavaCodingError.notSupported("JavaObjectContainer.encodeNil(forKey: \(key)")
    }
    
    public func encode(_ value: Bool, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "Z")
        JNI.api.SetBooleanField(JNI.env, javaObject, filed, jboolean(value ? JNI_TRUE : JNI_FALSE))
    }
    
    public func encode(_ value: Int, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "J")
        JNI.api.SetLongField(JNI.env, javaObject, filed, Int64(value))
    }
    public func encode(_ value: Int8, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "B")
        JNI.api.SetByteField(JNI.env, javaObject, filed, value)
    }
    public func encode(_ value: Int16, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "S")
        JNI.api.SetShortField(JNI.env, javaObject, filed, value)
    }
    public func encode(_ value: Int32, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "I")
        JNI.api.SetIntField(JNI.env, javaObject, filed, jint(value))
    }
    public func encode(_ value: Int64, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "J")
        JNI.api.SetLongField(JNI.env, javaObject, filed, value)
    }
    
    public func encode(_ value: UInt, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "J")
        JNI.api.SetLongField(JNI.env, javaObject, filed, jlong(bitPattern: UInt64(value)))
    }
    
    public func encode(_ value: String, forKey key: Key) throws {
        let filed = try getJavaField(forClass: javaClass, field: key.stringValue, sig: "Ljava/lang/String;")
        var locals = [jobject]()
        JNI.check(JNI.api.SetObjectField(JNI.env, javaObject, filed, value.localJavaObject(&locals)), &locals)
    }
    
    public func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        do {
            let object = try self.encoder.box(value)
            let filed = try getJavaField(forClass: self.javaClass, field: key.stringValue, sig: object.type.sig)
            JNI.api.SetObjectField(JNI.env, self.javaObject, filed, object.javaObject)
        }
        catch {
            if self.encoder.missingFieldsStrategy == .ignore {
                // Ignore
            }
            else {
                throw error
            }
        }
    }
    
    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        preconditionFailure("Not implemented: nestedContainer")
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        preconditionFailure("Not implemented: nestedUnkeyedContainer")
    }
    
    public func superEncoder() -> Encoder {
        preconditionFailure("Not implemented: superEncoder")
    }
    
    public func superEncoder(forKey key: Key) -> Encoder {
        preconditionFailure("Not implemented: superEncoder")
    }
}

// MARK: - Encoding Containers
fileprivate class JavaHashMapContainer<K : CodingKey> : KeyedEncodingContainerProtocol {
    
    typealias Key = K
    
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: JavaEncoder
    
    private let jniStorage: JNIStorageObject
    private var javaPutMethod = try! getJavaMethod(forClass: JavaHashMapClassname, method: "put", sig: "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;")
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JavaEncoder, codingPath: [CodingKey], jniStorage: JNIStorageObject) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.jniStorage = jniStorage
    }
    
    private var javaObject: jobject {
        return jniStorage.javaObject
    }
    
    // MARK: - KeyedEncodingContainerProtocol Methods
    public func encodeNil(forKey key: Key) throws {
        throw JavaCodingError.notSupported("JavaHashMapContainer.encodeNil(forKey: \(key))")
    }
    
    public func encode(_ value: String, forKey key: Key) throws {
        var locals = [jobject]()
        var args = [jvalue]()
        args.append(jvalue(l: key.stringValue.localJavaObject(&locals)))
        args.append(jvalue(l: value.localJavaObject(&locals)))
        withUnsafePointer(to: &args[0]) { argsPtr in
            let result = JNI.check(JNI.api.CallObjectMethodA(JNI.env, javaObject, javaPutMethod, argsPtr), &locals)
            assert(result == nil, "Rewrite for key \(key.stringValue)")
        }
    }
    
    public func encode<T : Encodable>(_ value: T, forKey key: Key) throws {
        if value is String {
            try self.encode(value as! String, forKey: key)
            return
        }

        let object = try self.encoder.box(value)
        var locals = [jobject]()
        var args = [jvalue]()
        args.append(jvalue(l: key.stringValue.localJavaObject(&locals)))
        args.append(jvalue(l: object.javaObject))
        
        withUnsafePointer(to: &args[0]) { argsPtr in
            let result = JNI.check(JNI.api.CallObjectMethodA(JNI.env, javaObject, javaPutMethod, argsPtr), &locals)
            assert(result == nil, "Rewrite for key \(key.stringValue)")
        }
    }
    
    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        preconditionFailure("Not implemented: nestedContainer")
    }
    
    public func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        preconditionFailure("Not implemented: nestedUnkeyedContainer")
    }
    
    public func superEncoder() -> Encoder {
        preconditionFailure("Not implemented: superEncoder")
    }
    
    public func superEncoder(forKey key: Key) -> Encoder {
        preconditionFailure("Not implemented: superEncoder")
    }
}

fileprivate class JavaArrayContainer : UnkeyedEncodingContainer {
    // MARK: Properties
    /// A reference to the encoder we're writing to.
    private let encoder: JavaEncoder
    
    /// The path of coding keys taken to get to this point in encoding.
    private(set) public var codingPath: [CodingKey]
    
    /// The number of elements encoded into the container.
    public private(set) var count: Int = 0
    
    private let jniStorage: JNIStorageObject
    
    // MARK: - Initialization
    /// Initializes `self` with the given references.
    fileprivate init(referencing encoder: JavaEncoder, codingPath: [CodingKey], jniStorage: JNIStorageObject) {
        self.encoder = encoder
        self.codingPath = codingPath
        self.jniStorage = jniStorage
    }
    
    private var javaObject: jobject {
        return jniStorage.javaObject
    }
    
    // MARK: - UnkeyedEncodingContainer Methods
    public func encodeNil() throws {
        throw JavaCodingError.notSupported("JavaArrayContainer.encodeNil")
    }
    
    public func encode(_ value: Int) throws {
        var value = jlong(value)
        JNI.api.SetLongArrayRegion(JNI.env, self.javaObject, jsize(count), 1, &value)
        count += 1
    }
    
    public func encode(_ value: String) throws {
        var locals = [jobject]()
        JNI.check(JNI.api.SetObjectArrayElement(JNI.env,
                                      self.javaObject,
                                      jsize(self.count),
                                      value.localJavaObject(&locals)), &locals)
        count += 1
    }
    
    public func encode<T : Encodable>(_ value: T) throws {
        if value is String {
            try self.encode(value as! String)
            return
        }
        if value is Int {
            try self.encode(value as! Int)
            return
        }

        let storeObject = try self.encoder.box(value)
        JNI.api.SetObjectArrayElement(JNI.env,
                                      self.javaObject,
                                      jsize(self.count),
                                      storeObject.javaObject)
        
        count += 1
    }
    
    public func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        preconditionFailure("Not implemented: nestedContainer")
    }
    
    public func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        preconditionFailure("Not implemented: nestedUnkeyedContainer")
    }
    
    public func superEncoder() -> Encoder {
        preconditionFailure("Not implemented: superEncoder")
    }
}

class JavaEnumValueEncodingContainer: SingleValueEncodingContainer {
    
    var codingPath: [CodingKey]
    let encoder: JavaEncoder
    
    private var javaClass: String
    private var jniStorage: JNIStorageObject
    
    init(encoder: JavaEncoder, javaClass: String, jniStorage: JNIStorageObject) {
        self.codingPath = [CodingKey]()
        self.encoder = encoder
        self.javaClass = javaClass
        self.jniStorage = jniStorage
    }
    
    private var javaObject: jobject {
        return jniStorage.javaObject
    }
    
    public func encodeNil() throws {
        throw JavaCodingError.notSupported("JavaSingleValueEncodingContainer.encodeNil")
    }
    
    public func encode<T : Encodable>(_ value: T) throws {
        if value is Int {
            let fieldID = try getJavaField(forClass: javaClass, field: "rawValue", sig: "J")
            JNI.api.SetLongField(JNI.env, javaObject, fieldID, jlong(value as! Int))
            return
        }
        if value is UInt {
            let filed = try getJavaField(forClass: javaClass, field: "rawValue", sig: "J")
            JNI.api.SetLongField(JNI.env, javaObject, filed, jlong(bitPattern: UInt64(value as! UInt)))
            return
        }
        if value is UInt32 {
            let filed = try getJavaField(forClass: javaClass, field: "rawValue", sig: "J")
            JNI.api.SetLongField(JNI.env, javaObject, filed, jlong(value as! UInt32))
            return
        }
        throw JavaCodingError.notSupported("JavaSingleValueEncodingContainer.encode(value: \(value) \(type(of:value))")
    }
}

private var UriClass = JNI.GlobalFindClass("android/net/Uri")
private var UriConstructor = JNI.api.GetStaticMethodID(JNI.env, JNI.GlobalFindClass("android/net/Uri"), "parse", "(Ljava/lang/String;)Landroid/net/Uri;")

extension JavaEncoder {
    
    fileprivate func getFullClassName<T>(_ value: T) -> String{
        if value is [String: Encodable] {
            return JavaHashMapClassname
        }
        return package  + "/" + String(describing: type(of: value))
    }
    
    @discardableResult
    fileprivate func box<T: Encodable>(_ value: T) throws -> JNIStorageObject {
        let storage: JNIStorageObject
        
        if T.self == URL.self {
            var locals = [jobject]()
            let javaString = (value as! URL).absoluteString.localJavaObject(&locals)
            var args = [jvalue]()
            args.append(jvalue(l: javaString))
            
            let uriObject = JNIMethod.CallStaticObjectMethod(className: "android/net/Uri",
                                                             classCache: &UriClass,
                                                             methodName: "parse",
                                                             methodSig: "(Ljava/lang/String;)Landroid/net/Uri;",
                                                             methodCache: &UriConstructor,
                                                             args: &args,
                                                             locals: &locals)
            
            storage = JNIStorageObject.init(type: .object(className: "android/net/Uri"), javaObject: uriObject!)
        }
        else if T.self == [String].self {
            let value = value as! [String]
            let javaClass = try getJavaClass(JavaStringClassname)
            guard let javaObject = JNI.api.NewObjectArray(JNI.env, jsize(value.count), javaClass, nil) else {
                throw JavaCodingError.cantCreateObject("\(JavaStringClassname)[]")
            }
            storage = JNIStorageObject(type: .array(type: .object(className: JavaStringClassname)), javaObject: javaObject)
            javaObjects.append(storage)
            try value.encode(to: self)
        }
        else if T.self == [Int].self {
            let value = value as! [Int]
            guard let javaObject = JNI.api.NewLongArray(JNI.env, jsize(value.count)) else {
                throw JavaCodingError.cantCreateObject("long[]")
            }
            storage = JNIStorageObject(type: .array(type: .primitive(name: "J")), javaObject: javaObject)
            javaObjects.append(storage)
            try value.encode(to: self)
        }
        else if let valueEncodableArray = value as? [Encodable] {
            let subType = String("\(T.self)".dropFirst(6)).dropLast(1)
            let fullClassName = package  + "/" + subType
            let javaClass = try getJavaClass(fullClassName)
            guard let javaObject = JNI.api.NewObjectArray(JNI.env, jsize(valueEncodableArray.count), javaClass, nil) else {
                throw JavaCodingError.cantCreateObject("\(fullClassName)[]")
            }
            storage = JNIStorageObject(type: .array(type: .object(className: fullClassName)), javaObject: javaObject)
            javaObjects.append(storage)
            try value.encode(to: self)
        }
        else {
            let storageType: JNIStorageType
            let fullClassName: String
            if value is [String: Encodable] {
                fullClassName = JavaHashMapClassname
                storageType = .dictionary
            }
            else {
                fullClassName = package  + "/" + String(describing: type(of: value))
                storageType = .object(className: fullClassName)
            }
            let javaClass = try getJavaClass(fullClassName)
            let emptyContructor = try getJavaEmptyConstructor(forClass: fullClassName)
            guard let javaObject = JNI.api.NewObjectA(JNI.env, javaClass, emptyContructor, nil) else {
                throw JavaCodingError.cantCreateObject(fullClassName)
            }
            storage = JNIStorageObject(type: storageType, javaObject: javaObject)
            javaObjects.append(storage)
            try value.encode(to: self)
        }
        return storage
    }
    
    fileprivate func popInstance() -> JNIStorageObject {
        guard let javaObject = self.javaObjects.popLast() else {
            preconditionFailure("No instances in stack")
        }
        return javaObject
    }
}
