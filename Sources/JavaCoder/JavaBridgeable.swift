//
// JavaBridgeable.swift
//
// Ported from readdle/swift-java's `Java` module (JavaBridgeable.swift) and
// readdle/java_swift (Throwable.swift) so that the JavaCoder package provides
// the non-primitive bridging the SwiftJava codegen relies on, without the
// readdle `Java`/`java_swift` runtime dependencies.
//
// This lives in the JavaCoder target (rather than the `java_swift` shim)
// because the default `from(javaObject:)`/`javaObject()` implementations are
// built on `JavaDecoder`/`JavaEncoder`. The shim cannot import JavaCoder
// without forming a dependency cycle.
//

import Foundation
import java_swift

public protocol JavaBridgeable: Codable {

    static func from(javaObject: jobject) throws -> Self

    func javaObject() throws -> jobject
}

extension JavaBridgeable {

    // Decoding SwiftValue type with JavaCoder
    public static func from(javaObject: jobject) throws -> Self {
        // ignore forPackage for basic impl
        return try JavaDecoder(forPackage: "").decode(Self.self, from: javaObject)
    }

    // Encoding SwiftValue type with JavaCoder
    public func javaObject() throws -> jobject {
        // ignore forPackage for basic impl
        return try JavaEncoder(forPackage: "").encode(self)
    }

}

extension Bool: JavaBridgeable {}
extension Int: JavaBridgeable {}
extension Int8: JavaBridgeable {}
extension Int16: JavaBridgeable {}
extension Int32: JavaBridgeable {}
extension Int64: JavaBridgeable {}
extension UInt: JavaBridgeable {}
extension UInt8: JavaBridgeable {}
extension UInt16: JavaBridgeable {}
extension UInt32: JavaBridgeable {}
extension UInt64: JavaBridgeable {}
extension Float: JavaBridgeable {}
extension Double: JavaBridgeable {}
extension Dictionary: JavaBridgeable where Key: Codable, Value: Codable {}
extension Set: JavaBridgeable where Element: Codable {}
extension Date: JavaBridgeable {}
extension Data: JavaBridgeable {}
extension URL: JavaBridgeable {}

extension String: JavaBridgeable {

    public static func from(javaObject: jobject) throws -> String {
        var isCopy: jboolean = 0
        guard let env = JNI.env,
              let chars = JNI.api.GetStringChars(env, javaObject, &isCopy) else {
            throw JavaCodingError.cantCreateObject("String")
        }
        defer {
            JNI.api.ReleaseStringChars(env, javaObject, chars)
        }
        return String(utf16CodeUnits: chars, count: Int(JNI.api.GetStringLength(env, javaObject)))
    }

    public func javaObject() throws -> jobject {
        // Use NewString with UTF-16 code units rather than NewStringUTF, which
        // expects Java's "modified UTF-8" and mangles supplementary (4-byte)
        // characters. Matches the GetStringChars decode path above.
        guard let env = JNI.env else {
            throw JavaCodingError.cantCreateObject("String")
        }
        let utf16 = Array(self.utf16)
        guard let javaObject: jstring = utf16.withUnsafeBufferPointer({ buffer in
            JNI.api.NewString(env, buffer.baseAddress, jsize(buffer.count))
        }) else {
            throw JavaCodingError.cantCreateObject("String")
        }
        return javaObject
    }

}

/// Minimal `java.lang.Throwable` wrapper, ported from readdle/java_swift, used
/// to bridge Java exceptions into `NSError`.
open class Throwable {

    private let javaObject: jobject

    public required init(javaObject: jobject) {
        self.javaObject = javaObject
    }

    open func getMessage() -> String! {
        guard let methodID = try? JNI.getJavaMethod(forClass: "java/lang/Throwable",
                                                    method: "getMessage",
                                                    sig: "()Ljava/lang/String;"),
              let result = JNI.CallObjectMethod(javaObject, methodID: methodID) else {
            return nil
        }
        defer {
            JNI.DeleteLocalRef(result)
        }
        return String(javaObject: result)
    }

    open func printStackTrace() {
        guard let methodID = try? JNI.getJavaMethod(forClass: "java/lang/Throwable",
                                                    method: "printStackTrace",
                                                    sig: "()V") else {
            return
        }
        JNI.CallVoidMethod(javaObject, methodID)
    }

    public func className() -> String {
        guard let env = JNI.env,
              let cls = JNI.api.GetObjectClass(env, javaObject) else {
            return "java/lang/Throwable"
        }
        defer {
            JNI.DeleteLocalRef(cls)
        }
        guard let methodID = try? JNI.getJavaMethod(forClass: "java/lang/Class",
                                                    method: "getName",
                                                    sig: "()Ljava/lang/String;"),
              let javaClassName = JNI.CallObjectMethod(cls, methodID: methodID) else {
            return "java/lang/Throwable"
        }
        defer {
            JNI.DeleteLocalRef(javaClassName)
        }
        return String(javaObject: javaClassName)
    }

    public func stackTraceString() -> String {
        return "" // no stack trace here
    }

    public func lastStackTraceString() -> String? {
        return nil
    }

}

// Error can't implement JavaBridgeable protocol
fileprivate let javaExceptionClass = JNI.GlobalFindClass("java/lang/Exception")!
fileprivate let javaExceptionConstructor = try! JNI.getJavaMethod(forClass: "java/lang/Exception",
                                                                  method: "<init>",
                                                                  sig: "(Ljava/lang/String;)V")

fileprivate let JavaErrorMessageKey = "JavaErrorMessageKey"
fileprivate let JavaErrorStackTrace = "JavaErrorStackTrace"

extension Error {

    public static var javaErrorMessageKey: String {
        return JavaErrorMessageKey
    }

    public static var javaErrorStackTrace: String {
        return JavaErrorStackTrace
    }

    public static func from(javaObject: jobject) throws -> Error {
        let throwable = Throwable(javaObject: javaObject)
        let className = throwable.className()
        let message = throwable.getMessage()
        let lastStackTrace = throwable.lastStackTraceString()
        let userInfo: [String: Any] = [javaErrorMessageKey: message ?? "unavailable",
                                        javaErrorStackTrace: lastStackTrace ?? "unavailable"]

        // Try extract error according to Error.javaObject()
        if let javaMessage = message {
            let parts = javaMessage.split(separator: ":")
            if parts.count > 1 {
                let domain = String(parts[0])
                let codeString = String(parts[1])
                if let code = Int(codeString) {
                    return NSError(domain: domain, code: code, userInfo: userInfo)
                }
            }
        }

        // Plan B
        let domain = className
        let code = 0
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }

}

#if !HIDE_ERROR_JAVA_BRIDGEABLE
extension Error {
    public func javaObject() throws -> jobject {
        let nsError = self as NSError
        let message = "\(nsError.domain):\(nsError.code)"
        guard let javaObject = JNI.NewObject(javaExceptionClass,
                                             methodID: javaExceptionConstructor,
                                             args: [jvalue(l: try message.javaObject())]) else {
            throw JavaCodingError.cantCreateObject("java/lang/Exception")
        }
        return javaObject
    }
}

extension Error where Self: RawRepresentable, Self.RawValue: SignedInteger {

    public func javaObject() throws -> jobject {
        let domain = String(reflecting: type(of: self))
        let code: Int = numericCast(self.rawValue)
        let message = try "\(domain):\(code)".javaObject()
        guard let javaObject = JNI.NewObject(javaExceptionClass,
                                             methodID: javaExceptionConstructor,
                                             args: [jvalue(l: message)]) else {
            throw JavaCodingError.cantCreateObject("java/lang/Exception")
        }
        return javaObject
    }
}

extension Error where Self: RawRepresentable, Self.RawValue: UnsignedInteger {

    public func javaObject() throws -> jobject {
        let domain = String(reflecting: type(of: self))
        let code: Int = numericCast(self.rawValue)
        let message = try "\(domain):\(code)".javaObject()
        guard let javaObject = JNI.NewObject(javaExceptionClass,
                                             methodID: javaExceptionConstructor,
                                             args: [jvalue(l: message)]) else {
            throw JavaCodingError.cantCreateObject("java/lang/Exception")
        }
        return javaObject
    }
}
#endif
