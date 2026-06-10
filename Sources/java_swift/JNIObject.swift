//
// JNIObject.swift
// java_swift (compatibility shim)
//
// Faithful port of the readdle/java_swift `JNIObject` hierarchy and the
// `String` <-> Java bridging helpers that JavaCoder depends on, backed by
// SwiftJavaJNICore.
//

import Foundation
@_exported import SwiftJavaJNICore

public protocol JNIObjectProtocol {
    func localJavaObject(_ locals: UnsafeMutablePointer<[jobject]>) -> jobject?
}

public protocol JNIObjectInit {
    init(javaObject: jobject?)
}

extension JNIObjectProtocol {
    public func withJavaObject<Result>(_ body: @escaping (jobject?) throws -> Result) rethrows -> Result {
        var locals = [jobject]()
        let javaObject: jobject? = localJavaObject(&locals)
        defer {
            for local in locals {
                JNI.DeleteLocalRef(local)
            }
        }
        return try body(javaObject)
    }
}

public protocol JavaProtocol: JNIObjectProtocol {}

/// A Swift handle to a Java object. The underlying reference is promoted to a
/// JNI global reference so it remains valid across native calls and threads,
/// matching the original library's lifetime semantics.
open class JNIObject: JNIObjectProtocol, JNIObjectInit {

    private var _javaObject: jobject?

    open var javaObject: jobject? {
        get {
            return _javaObject
        }
        set(newValue) {
            if newValue != _javaObject {
                let oldValue: jobject? = _javaObject
                if let newValue = newValue, let env = JNI.env {
                    _javaObject = JNI.api.NewGlobalRef(env, newValue)
                } else {
                    _javaObject = nil
                }
                if let oldValue = oldValue, let env = JNI.env {
                    JNI.api.DeleteGlobalRef(env, oldValue)
                }
            }
        }
    }

    public required init(javaObject: jobject?) {
        self.javaObject = javaObject
    }

    public convenience init() {
        self.init(javaObject: nil)
    }

    open var isNull: Bool {
        guard let env = JNI.env else {
            return _javaObject == nil
        }
        return _javaObject == nil || JNI.api.IsSameObject(env, _javaObject, nil) == jboolean(JNI_TRUE)
    }

    open func localJavaObject(_ locals: UnsafeMutablePointer<[jobject]>) -> jobject? {
        guard let javaObject = _javaObject, let env = JNI.env else {
            return nil
        }
        if let local: jobject = JNI.api.NewLocalRef(env, javaObject) {
            locals.pointee.append(local)
            return local
        }
        return nil
    }

    open func clearLocal() {}

    deinit {
        javaObject = nil
    }
}

open class JNIObjectForward: JNIObject {}

// MARK: - String bridging

extension String: JNIObjectProtocol {
    public func localJavaObject(_ locals: UnsafeMutablePointer<[jobject]>) -> jobject? {
        guard let env = JNI.env else {
            return nil
        }
        // Delegate to jni-core's `JavaValue` conformance, which builds the
        // jstring via `NewString` over UTF-16 code units. (We deliberately do
        // NOT use jni-core's read path `String(fromJNI:)`, which decodes via
        // `GetStringUTFChars` / modified UTF-8 and mangles supplementary
        // 4-byte characters — see `init(javaObject:)` below.)
        if let javaObject: jstring = self.getJNIValue(in: env) {
            locals.pointee.append(javaObject)
            return javaObject
        }
        return nil
    }
}

extension String: JNIObjectInit {
    public init(javaObject: jobject?) {
        var isCopy: jboolean = 0
        if let javaObject = javaObject,
           let env = JNI.env,
           let value: UnsafePointer<jchar> = JNI.api.GetStringChars(env, javaObject, &isCopy) {
            self.init(utf16CodeUnits: value, count: Int(JNI.api.GetStringLength(env, javaObject)))
            JNI.api.ReleaseStringChars(env, javaObject, value)
        } else {
            self.init()
        }
    }
}

// MARK: - Object array helpers

extension jobject {
    public func arrayMap<T>(block: (_ javaObject: jobject?) -> T) -> [T] {
        guard let env = JNI.env else {
            return []
        }
        return (0 ..< JNI.api.GetArrayLength(env, self)).map { index in
            let element: jobject? = JNI.api.GetObjectArrayElement(env, self, index)
            defer { JNI.DeleteLocalRef(element) }
            return block(element)
        }
    }
}
