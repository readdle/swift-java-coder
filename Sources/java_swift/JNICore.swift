//
// JNICore.swift
// java_swift (compatibility shim)
//
// Drop-in replacement for the subset of the readdle/java_swift `JNICore`
// API used by JavaCoder, re-implemented on top of swiftlang's
// SwiftJavaJNICore (jni-core).
//
// The original library exposed a global `JNI` instance of `JNICore` that
// vended the raw JNI function table (`JNI.api`) and the current thread's
// environment pointer (`JNI.env`). jni-core models the same concepts via
// `JavaVirtualMachine.shared().environment()` and `env.interface`, so this
// file simply re-shapes those into the historical surface.
//

import Foundation
@_exported import SwiftJavaJNICore

/// Global JNI access point, matching the historical `java_swift` API.
public let JNI = JNICore()

open class JNICore {

    /// Context class loader captured at `JNI_OnLoad` time. Used by
    /// ``FindClass(_:_:_:)`` to resolve application classes from threads that
    /// were not started by the JVM (notably on Android).
    open var classLoader: jclass!

    /// Logger used for diagnostics. Mirrors the original library's hook.
    open var errorLogger: (_ message: String) -> Void = { message in
        NSLog("%@", message)
    }

    public init() {}

    // MARK: Environment / raw interface

    /// The JNI environment for the current thread, attaching it to the JVM if
    /// necessary. Returns `nil` if no JVM is available.
    open var env: JNIEnvironment? {
        guard let vm = try? JavaVirtualMachine.shared() else {
            return nil
        }
        return try? vm.environment()
    }

    /// The raw JNI function table (`JNINativeInterface`) for the current thread.
    ///
    /// Force-unwraps the environment to match the historical non-optional
    /// `JNI.api` shape; call sites always have a live JVM by the time they
    /// reach JNI calls.
    open var api: JNINativeInterface {
        return env!.interface
    }

    // MARK: Diagnostics

    open func report(_ msg: String, _ file: StaticString = #file, _ line: Int = #line) {
        errorLogger("\(msg) - at \(file):\(line)")
    }

    // MARK: Class lookup

    private var loadClassMethodID: jmethodID?

    /// Find a Java class by its JNI name (e.g. `java/lang/Integer`).
    ///
    /// When a ``classLoader`` was captured, classes are resolved through
    /// `ClassLoader.loadClass(String)` so that application classes are found
    /// from arbitrary threads. Otherwise this falls back to the raw
    /// `FindClass` JNI call.
    open func FindClass(_ name: UnsafePointer<Int8>,
                        _ file: StaticString = #file,
                        _ line: Int = #line) -> jclass? {
        ExceptionReset()
        guard let env = self.env else {
            return nil
        }
        let className = String(cString: name)

        if let classLoader = self.classLoader {
            var locals = [jobject]()
            let javaName = className.localJavaObject(&locals)
            if loadClassMethodID == nil, let clClass = api.GetObjectClass(env, classLoader) {
                loadClassMethodID = api.GetMethodID(env, clClass,
                                                    "loadClass",
                                                    "(Ljava/lang/String;)Ljava/lang/Class;")
                api.DeleteLocalRef(env, clClass)
            }
            let args = [jvalue(l: javaName)]
            let clazz: jclass? = args.withUnsafeBufferPointer { ptr in
                api.CallObjectMethodA(env, classLoader, loadClassMethodID, ptr.baseAddress)
            }
            for local in locals {
                DeleteLocalRef(local)
            }
            if clazz == nil {
                report("Could not find class \(className)", file, line)
            }
            return clazz
        } else {
            let clazz = api.FindClass(env, name)
            if clazz == nil {
                report("Could not find class \(className)", file, line)
            }
            return clazz
        }
    }

    // MARK: Reference management

    open func DeleteLocalRef(_ local: jobject?) {
        if let local = local, let env = self.env {
            env.deleteLocalRef(local)
        }
    }

    /// Delete the supplied local references and drain any pending Java
    /// exception into the thread-local cache so it can later be retrieved via
    /// ``ExceptionCheck()``. Returns `result` unchanged for call-site
    /// convenience.
    @discardableResult
    open func check<T>(_ result: T,
                       _ locals: UnsafeMutablePointer<[jobject]>,
                       removeLast: Bool = false,
                       _ file: StaticString = #file,
                       _ line: Int = #line) -> T {
        if removeLast && locals.pointee.count != 0 {
            locals.pointee.removeLast()
        }
        for local in locals.pointee {
            DeleteLocalRef(local)
        }
        if let env = self.env, api.ExceptionCheck(env) != 0 {
            if let throwable = api.ExceptionOccurred(env) {
                setThrown(throwable)
                api.ExceptionClear(env)
            }
        }
        return result
    }

    // MARK: Exceptions

    /// Returns and clears the pending exception captured for the current
    /// thread, if any.
    open func ExceptionCheck() -> jthrowable? {
        return takeThrown()
    }

    /// Logs and clears any left-over exception captured for the current thread.
    open func ExceptionReset() {
        if let env = self.env, api.ExceptionCheck(env) != 0 {
            if let throwable = api.ExceptionOccurred(env) {
                setThrown(throwable)
                api.ExceptionClear(env)
            }
        }
        if ExceptionCheck() != nil {
            errorLogger("Left over exception")
        }
    }

    // MARK: Fatal error message (thread-local breadcrumb)

    open func SaveFatalErrorMessage(_ msg: String,
                                    _ file: StaticString = #file,
                                    _ line: Int = #line) {
        Thread.current.threadDictionary[JNICore.fatalKey] = "\(msg) at \(file):\(line)"
    }

    open func RemoveFatalErrorMessage() {
        Thread.current.threadDictionary.removeObject(forKey: JNICore.fatalKey)
    }

    open func GetFatalErrorMessage() -> String? {
        return Thread.current.threadDictionary[JNICore.fatalKey] as? String
    }

    // MARK: Thread-local storage

    private static let thrownKey = "com.readdle.java_swift.thrown"
    private static let fatalKey = "com.readdle.java_swift.fatal"

    private func setThrown(_ throwable: jthrowable) {
        Thread.current.threadDictionary[JNICore.thrownKey] = UInt(bitPattern: throwable)
    }

    private func takeThrown() -> jthrowable? {
        let dict = Thread.current.threadDictionary
        guard let bits = dict[JNICore.thrownKey] as? UInt,
              let throwable = UnsafeMutableRawPointer(bitPattern: bits) else {
            return nil
        }
        dict.removeObject(forKey: JNICore.thrownKey)
        return throwable
    }
}
