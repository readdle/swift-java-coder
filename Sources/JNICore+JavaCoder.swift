//
//  JNIHelper.swift
//  jniBridge
//
//  Created by Andrew on 10/18/17.
//

import Foundation
import java_swift

// MARK: Java Classnames
let ObjectClassname = "java/lang/Object"
let ClassClassname = "java/lang/Class"
var IntegerClassname = "java/lang/Integer"
var ByteClassname = "java/lang/Byte"
var ShortClassname = "java/lang/Short"
var LongClassname = "java/lang/Long"
var BigIntegerClassname = "java/math/BigInteger"
var BooleanClassname = "java/lang/Boolean"
var StringClassname = "java/lang/String"
var ArrayListClassname = "java/util/ArrayList"
let HashMapClassname = "java/util/HashMap"
let SetClassname = "java/util/Set"
let UriClassname = "android/net/Uri"
let DateClassname = "java/util/Date"

// MARK: Java Classes
var IntegerClass = try! JNI.getJavaClass("java/lang/Integer")
var ByteClass = try! JNI.getJavaClass("java/lang/Byte")
var ShortClass = try! JNI.getJavaClass("java/lang/Short")
var LongClass = try! JNI.getJavaClass("java/lang/Long")
var BigIntegerClass = try! JNI.getJavaClass("java/math/BigInteger")
var BooleanClass = try! JNI.getJavaClass("java/lang/Boolean")
var StringClass = try! JNI.getJavaClass("java/lang/String")
let ExceptionClass = try! JNI.getJavaClass("java/lang/Exception")
let UriClass = try! JNI.getJavaClass("android/net/Uri")
let DateClass = try! JNI.getJavaClass("java/util/Date")
let VMDebugClass = try! JNI.getJavaClass("dalvik/system/VMDebug")

// MARK: Java methods
let UriConstructor = JNI.api.GetStaticMethodID(JNI.env, UriClass, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
let DateConstructor = try! JNI.getJavaMethod(forClass: "java/util/Date", method: "<init>", sig: "(J)V")
let IntegerConstructor = try! JNI.getJavaMethod(forClass: IntegerClassname, method: "<init>", sig: "(I)V")
let ByteConstructor = try! JNI.getJavaMethod(forClass: ByteClassname, method: "<init>", sig: "(B)V")
let ShortConstructor = try! JNI.getJavaMethod(forClass: ShortClassname, method: "<init>", sig: "(S)V")
let LongConstructor = try! JNI.getJavaMethod(forClass: LongClassname, method: "<init>", sig: "(J)V")
let BigIntegerConstructor = try! JNI.getJavaMethod(forClass: BigIntegerClassname, method: "<init>", sig: "(Ljava/lang/String;)V")
let BooleanConstructor = try! JNI.getJavaMethod(forClass: BooleanClassname, method: "<init>", sig: "(Z)V")

let ObjectToStringMethod = try! JNI.getJavaMethod(forClass: "java/lang/Object", method: "toString", sig: "()Ljava/lang/String;")
let ClassGetNameMethod = try! JNI.getJavaMethod(forClass: ClassClassname, method: "getName", sig: "()L\(StringClassname);")
let NumberByteValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "byteValue", sig: "()B")
let NumberShortValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "shortValue", sig: "()S")
let NumberIntValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "intValue", sig: "()I")
let NumberLongValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "longValue", sig: "()J")
let NumberBooleanValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Boolean", method: "booleanValue", sig: "()Z")
let HashMapPutMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "put", sig: "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;")
let HashMapGetMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "get", sig: "(L\(ObjectClassname);)L\(ObjectClassname);")
let HashMapKeySetMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "keySet", sig: "()L\(SetClassname);")
let HashMapSizeMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "size", sig: "()I")
let SetToArrayMethod = try! JNI.getJavaMethod(forClass: SetClassname, method: "toArray", sig: "()[L\(ObjectClassname);")
let ArrayListGetMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "get", sig: "(I)L\(ObjectClassname);")
let ArrayListSizeMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "size", sig: "()I")
let ArrayListAddMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "add", sig: "(Ljava/lang/Object;)Z")
let DateGetTimeMethod = try! JNI.getJavaMethod(forClass: "java/util/Date", method: "getTime", sig:"()J")
let VMDebugDumpReferenceTablesMethod = JNI.api.GetStaticMethodID(JNI.env, VMDebugClass, "dumpReferenceTables", "()V")

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

public extension JNICore {
    
    public var NULL: JNIArgumentProtocol {
        return jnull()
    }
    
    public var TRUE: jboolean {
        return jboolean(JNI_TRUE)
    }
    
    public var FALSE: jboolean {
        return jboolean(JNI_FALSE)
    }
    
    public enum JNIError: Error {
        
        case classNotFoundException(String)
        case methodNotFoundException(String)
        case fieldNotFoundException(String)
        
        public func `throw`() {
            switch self {
            case .classNotFoundException(let message):
                assert(JNI.api.ThrowNew(JNI.env, ExceptionClass, "ClassNotFoundaException: \(message)") == 0)
            case .methodNotFoundException(let message):
                assert(JNI.api.ThrowNew(JNI.env, ExceptionClass, "MethodNotFoundException: \(message)") == 0)
            case .fieldNotFoundException(let message):
                assert(JNI.api.ThrowNew(JNI.env, ExceptionClass, "FieldNotFoundException: \(message)") == 0)
            }
            
        }
    }
    
    // MARK: Global cache functions
    public func getJavaClass(_ className: String) throws -> jclass {
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
    
    public func getJavaEmptyConstructor(forClass className: String) throws -> jmethodID {
        return try getJavaMethod(forClass: className, method: "<init>", sig: "()V")
    }
    
    public func getJavaMethod(forClass className: String, method: String, sig: String) throws -> jmethodID {
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
    
    public func getJavaField(forClass className: String, field: String, sig: String) throws -> jfieldID {
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
    
    public func GlobalFindClass( _ name: UnsafePointer<Int8>,
                               _ file: StaticString = #file, _ line: Int = #line ) -> jclass? {
        guard let clazz: jclass = FindClass(name, file, line ) else {
            return nil
        }
        let result = api.NewGlobalRef(env, clazz)
        api.DeleteLocalRef(env, clazz)
        return result
    }
    
    // MARK: Constructors
    public func NewObject(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.NewObjectA(env, clazz, methodID, argsPtr)
        })
    }
    
    // MARK: Object methods
    public func CallBooleanMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jboolean {
        return checkArgument(args: args, { argsPtr in
            api.CallBooleanMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallByteMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jbyte {
        return checkArgument(args: args, { argsPtr in
            api.CallByteMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallShortMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jshort {
        return checkArgument(args: args, { argsPtr in
            api.CallShortMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallIntMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jint {
        return checkArgument(args: args, { argsPtr in
            api.CallIntMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallLongMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jlong {
        return checkArgument(args: args, { argsPtr in
            api.CallLongMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallObjectMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.CallObjectMethodA(env, object, methodID, argsPtr)
        })
    }
    
    // MARK: Static methods
    public func CallStaticBooleanMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jboolean {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticBooleanMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticByteMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jbyte {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticByteMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticShortMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jshort {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticShortMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticIntMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jint {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticIntMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticLongMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jlong {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticLongMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func CallStaticObjectMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticObjectMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    public func dumpReferenceTables() {
        JNI.api.CallStaticVoidMethodA(JNI.env, VMDebugClass, VMDebugDumpReferenceTablesMethod, nil)
        JNI.api.ExceptionClear(JNI.env)
        JNI.ExceptionReset()
    }
    
    private func checkArgument<Result>(args: [jvalue], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        if args.count > 0 {
            var args = args
            return withUnsafePointer(to: &args[0]) { argsPtr in
                return block(argsPtr)
            }
        }
        else {
            return block(nil)
        }
    }
    
    // MARK: New API
    public func CallVoidMethod(_ object: jobject, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            api.CallVoidMethodA(env, object, methodID, argsPtr)
        })
    }
    
    public func CallStaticVoidMethod(_ clazz: jclass, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            api.CallStaticVoidMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    private func checkArgumentAndWrap<Result>(args: [JNIArgumentProtocol], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        if args.count > 0 {
            var argsValues = args.map({ $0.value() })
            return withUnsafePointer(to: &argsValues[0]) { argsPtr in
                return block(argsPtr)
            }
        }
        else {
            return block(nil)
        }
    }
    
}
