//
// JNIBootstrap.swift
// java_swift (compatibility shim)
//
// JVM bootstrap glue.
//
// IMPORTANT: This shim intentionally does NOT define `@_cdecl("JNI_OnLoad")`.
// A dynamic library can export only one `JNI_OnLoad`, and when this package is
// linked alongside swiftlang's `SwiftJava` (which defines its own `JNI_OnLoad`
// that calls `JavaVirtualMachine.setSharedJVM`), defining a second one here
// would be a duplicate-symbol conflict.
//
// Registering the JVM is the application's responsibility. Define your own
// `@_cdecl("JNI_OnLoad")` (or rely on SwiftJava's, when linked in) to register
// the shared JVM via `JavaVirtualMachine.setShared(...)` /
// `JavaVirtualMachine.setSharedJVM(...)`. Once a shared JVM is registered,
// `JNI.env` / `JavaVirtualMachine.shared()` work out of the box.
//
// The only thing this shim needs beyond that is the context class loader, used
// to resolve *application* classes from threads not started by the JVM
// (notably on Android). Call `JNIBootstrap.captureContextClassLoader()` once
// from a Java-originated thread (e.g. your native init method) to capture it.
//
// On desktop where Swift drives the JVM, no bootstrap is required;
// `JavaVirtualMachine.shared()` lazily creates or adopts a JVM, and raw
// `FindClass` resolves classpath classes without a context loader.
//

import Foundation
@_exported import SwiftJavaJNICore

public enum JNIBootstrap {

    /// Capture the current thread's context class loader into ``JNICore``'s
    /// ``JNICore/classLoader`` so that ``JNICore/FindClass(_:_:_:)`` can resolve
    /// application classes from threads not started by the JVM.
    ///
    /// Call this exactly once, early, from a thread that originated in Java
    /// (so the context class loader is the application loader, not the system
    /// loader). Safe to use whether or not SwiftJava is present; it relies only
    /// on the shared JVM already being registered.
    ///
    /// - Returns: `true` if a class loader was captured.
    @discardableResult
    public static func captureContextClassLoader() -> Bool {
        guard let env = JNI.env else {
            return false
        }
        guard let threadClass = JNI.api.FindClass(env, "java/lang/Thread") else {
            return false
        }
        defer { env.deleteLocalRef(threadClass) }

        guard let currentThreadMethod = JNI.api.GetStaticMethodID(env, threadClass,
                                                                  "currentThread",
                                                                  "()Ljava/lang/Thread;"),
              let getContextClassLoaderMethod = JNI.api.GetMethodID(env, threadClass,
                                                                    "getContextClassLoader",
                                                                    "()Ljava/lang/ClassLoader;") else {
            return false
        }

        guard let currentThread = JNI.api.CallStaticObjectMethodA(env, threadClass, currentThreadMethod, nil) else {
            return false
        }
        defer { env.deleteLocalRef(currentThread) }

        guard let loader = JNI.api.CallObjectMethodA(env, currentThread, getContextClassLoaderMethod, nil) else {
            return false
        }
        defer { env.deleteLocalRef(loader) }

        JNI.classLoader = JNI.api.NewGlobalRef(env, loader)
        return JNI.classLoader != nil
    }
}
