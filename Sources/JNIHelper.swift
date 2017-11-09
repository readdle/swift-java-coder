//
//  JNIHelper.swift
//  jniBridge
//
//  Created by Andrew on 10/18/17.
//

import Foundation
import java_swift

let JavaHashMapClassname = "java/util/HashMap"
let JavaStringClassname = "java/lang/String"
let JavaSetClassname = "java/util/Set"
let JavaObjectClassname = "java/lang/Object"
let JavaClassClassname = "java/lang/Class"

let JavaHashMapSig = "Ljava/util/HashMap;"
let JavaStringSig = "Ljava/lang/String;"


public enum JNIError: Error {
    
    case classNotFoundException(String)
    case methodNotFoundException(String)
    case fieldNotFoundException(String)
    
    private static let JavaExceptionClass = try! getJavaClass("java/lang/Exception")
    
    public func `throw`() {
        switch self {
        case .classNotFoundException(let message):
            assert(JNI.api.ThrowNew(JNI.env, JNIError.JavaExceptionClass, "ClassNotFoundaException: \(message)") == 0)
        case .methodNotFoundException(let message):
            assert(JNI.api.ThrowNew(JNI.env, JNIError.JavaExceptionClass, "MethodNotFoundException: \(message)") == 0)
        case .fieldNotFoundException(let message):
            assert(JNI.api.ThrowNew(JNI.env, JNIError.JavaExceptionClass, "FieldNotFoundException: \(message)") == 0)
        }
        
    }
}

fileprivate extension NSLock {
    
    func sync<T>(_ block: () throws -> T) throws -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try block()
    }
}
    
fileprivate var javaClasses = [String: jclass]()
fileprivate var javaMethods = [String: jmethodID]()
fileprivate var javaFields = [String: jmethodID]()

fileprivate let javaClassesLock = NSLock()
fileprivate let javaMethodLock = NSLock()
fileprivate let javaFieldLock = NSLock()

func getJavaClass(_ className: String) throws -> jclass {
    if let javaClass = javaClasses[className] {
        return javaClass
    }
    return try javaClassesLock.sync {
        if let javaClass = javaClasses[className] {
            return javaClass
        }
        guard let javaClass = JNI.GlobalFindClass(className) else {
            JNI.api.ExceptionClear(JNI.env)
            JNI.ExceptionReset()
            throw JNIError.classNotFoundException(className)
        }
        javaClasses[className] = javaClass
        return javaClass
    }
}

func getJavaEmptyConstructor(forClass className: String) throws -> jmethodID? {
    return try getJavaMethod(forClass: className, method: "<init>", sig: "()V")
}

func getJavaMethod(forClass className: String, method: String, sig: String) throws -> jmethodID {
    let key = "\(className).\(method)\(sig)"
    let javaClass = try getJavaClass(className)
    if let methodID = javaMethods[key] {
        return methodID
    }
    return try javaMethodLock.sync {
        if let methodID = javaMethods[key] {
            return methodID
        }
        guard let javaMethodID = JNI.api.GetMethodID(JNI.env, javaClass, method, sig) else {
            JNI.api.ExceptionClear(JNI.env)
            JNI.ExceptionReset()
            throw JNIError.methodNotFoundException(key)
        }
        javaMethods[key] = javaMethodID
        return javaMethodID
    }
}

func getJavaField(forClass className: String, field: String, sig: String) throws -> jfieldID {
    let key = "\(className).\(field)\(sig)"
    let javaClass = try getJavaClass(className)
    if let fieldID = javaFields[key] {
        return fieldID
    }
    return try javaFieldLock.sync({
        if let fieldID = javaFields[key] {
            return fieldID
        }
        guard let fieldID = JNI.api.GetFieldID(JNI.env, javaClass, field, sig) else {
            JNI.api.ExceptionClear(JNI.env)
            JNI.ExceptionReset()
            throw JNIError.fieldNotFoundException(key)
        }
        javaFields[key] = fieldID
        return fieldID
        
    })
}

extension JNICore {
    
    open func GlobalFindClass( _ name: UnsafePointer<Int8>,
                               _ file: StaticString = #file, _ line: Int = #line ) -> jclass? {
        guard let clazz: jclass = FindClass(name, file, line ) else {
            return nil
        }
        let result = api.NewGlobalRef(env, clazz)
        api.DeleteLocalRef(env, clazz)
        return result
    }
    
    func dumpReferenceTables() throws {
        let vm_class = try getJavaClass("dalvik/system/VMDebug")
        let dump_mid =  JNI.api.GetStaticMethodID(JNI.env, vm_class, "dumpReferenceTables", "()V")
        JNI.api.CallStaticVoidMethodA(JNI.env, vm_class, dump_mid, nil)
        JNI.api.ExceptionClear(JNI.env)
        JNI.ExceptionReset()
    }
    
}

