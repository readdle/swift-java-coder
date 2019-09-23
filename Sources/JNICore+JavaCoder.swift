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
let HashSetClassname = "java/util/HashSet"
let ByteBufferClassname = "java/nio/ByteBuffer"
let FloatClassname = "java/lang/Float"
let DoubleClassname = "java/lang/Double"

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
let HashSetClass = try! JNI.getJavaClass("java/util/HashSet")
let ByteBufferClass = try! JNI.getJavaClass("java/nio/ByteBuffer")
let FloatClass = try! JNI.getJavaClass("java/lang/Float")
let DoubleClass = try! JNI.getJavaClass("java/lang/Double")

// MARK: Java methods
let UriConstructor = JNI.api.GetStaticMethodID(JNI.env, UriClass, "parse", "(Ljava/lang/String;)Landroid/net/Uri;")
let DateConstructor = try! JNI.getJavaMethod(forClass: "java/util/Date", method: "<init>", sig: "(J)V")
let IntegerConstructor = try! JNI.getJavaMethod(forClass: IntegerClassname, method: "<init>", sig: "(I)V")
let ByteConstructor = try! JNI.getJavaMethod(forClass: ByteClassname, method: "<init>", sig: "(B)V")
let ShortConstructor = try! JNI.getJavaMethod(forClass: ShortClassname, method: "<init>", sig: "(S)V")
let LongConstructor = try! JNI.getJavaMethod(forClass: LongClassname, method: "<init>", sig: "(J)V")
let BigIntegerConstructor = try! JNI.getJavaMethod(forClass: BigIntegerClassname, method: "<init>", sig: "(Ljava/lang/String;)V")
let BooleanConstructor = try! JNI.getJavaMethod(forClass: BooleanClassname, method: "<init>", sig: "(Z)V")
let FloatConstructor = try! JNI.getJavaMethod(forClass: FloatClassname, method: "<init>", sig: "(F)V")
let DoubleConstructor = try! JNI.getJavaMethod(forClass: DoubleClassname, method: "<init>", sig: "(D)V")

let ObjectToStringMethod = try! JNI.getJavaMethod(forClass: "java/lang/Object", method: "toString", sig: "()Ljava/lang/String;")
let ClassGetNameMethod = try! JNI.getJavaMethod(forClass: ClassClassname, method: "getName", sig: "()L\(StringClassname);")
let ClassGetFieldMethod = try! JNI.getJavaMethod(forClass: ClassClassname, method: "getField", sig: "(Ljava/lang/String;)Ljava/lang/reflect/Field;")
let FieldGetTypedMethod = try! JNI.getJavaMethod(forClass: "java/lang/reflect/Field", method: "getType", sig: "()L\(ClassClassname);")
let NumberByteValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "byteValue", sig: "()B")
let NumberShortValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "shortValue", sig: "()S")
let NumberIntValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "intValue", sig: "()I")
let NumberLongValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "longValue", sig: "()J")
let NumberFloatValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "floatValue", sig: "()F")
let NumberDoubleValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Number", method: "doubleValue", sig: "()D")
let NumberBooleanValueMethod = try! JNI.getJavaMethod(forClass: "java/lang/Boolean", method: "booleanValue", sig: "()Z")
let HashMapPutMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "put", sig: "(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;")
let HashMapGetMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "get", sig: "(L\(ObjectClassname);)L\(ObjectClassname);")
let HashMapKeySetMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "keySet", sig: "()L\(SetClassname);")
let HashMapSizeMethod = try! JNI.getJavaMethod(forClass: HashMapClassname, method: "size", sig: "()I")
let SetToArrayMethod = try! JNI.getJavaMethod(forClass: SetClassname, method: "toArray", sig: "()[L\(ObjectClassname);")
let ArrayListGetMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "get", sig: "(I)L\(ObjectClassname);")
let ArrayListSizeMethod = try! JNI.getJavaMethod(forClass: ArrayListClassname, method: "size", sig: "()I")
let CollectionAddMethod = try! JNI.getJavaMethod(forClass: "java/util/Collection", method: "add", sig: "(Ljava/lang/Object;)Z")
let CollectionIteratorMethod = try! JNI.getJavaMethod(forClass: "java/util/Collection", method: "iterator", sig: "()Ljava/util/Iterator;")
let CollectionSizeMethod = try! JNI.getJavaMethod(forClass: "java/util/Collection", method: "size", sig: "()I")
let IteratorNextMethod = try! JNI.getJavaMethod(forClass: "java/util/Iterator", method: "next", sig: "()Ljava/lang/Object;")
let DateGetTimeMethod = try! JNI.getJavaMethod(forClass: "java/util/Date", method: "getTime", sig:"()J")
let VMDebugDumpReferenceTablesMethod = JNI.api.GetStaticMethodID(JNI.env, VMDebugClass, "dumpReferenceTables", "()V")
let ByteBufferArray = try! JNI.getJavaMethod(forClass: "java/nio/ByteBuffer", method: "array", sig: "()[B")
let ByteBufferWrap = JNI.api.GetStaticMethodID(JNI.env, ByteBufferClass, "wrap", "([B)Ljava/nio/ByteBuffer;")!

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
fileprivate var javaStaticMethods = [String: jmethodID]()
fileprivate var javaFields = [String: jmethodID]()

fileprivate let javaClassesLock = NSLock()
fileprivate let javaMethodLock = NSLock()
fileprivate let javaStaticMethodLock = NSLock()
fileprivate let javaFieldLock = NSLock()

public extension JNICore {
    
    var TRUE: jboolean {
        return jboolean(JNI_TRUE)
    }
    
    var FALSE: jboolean {
        return jboolean(JNI_FALSE)
    }
    
    enum JNIError: Error {
        
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
    func getJavaClass(_ className: String) throws -> jclass {
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
    
    func getJavaEmptyConstructor(forClass className: String) throws -> jmethodID {
        return try getJavaMethod(forClass: className, method: "<init>", sig: "()V")
    }
    
    func getJavaMethod(forClass className: String, method: String, sig: String) throws -> jmethodID {
        let key = "\(className).\(method)\(sig)"
        let javaClass = try getJavaClass(className)
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
    
    func getStaticJavaMethod(forClass className: String, method: String, sig: String) throws -> jmethodID {
        let key = "\(className).\(method)\(sig)"
        let javaClass = try getJavaClass(className)
        return try javaStaticMethodLock.sync {
            if let methodID = javaStaticMethods[key] {
                return methodID
            }
            guard let javaMethodID = JNI.api.GetStaticMethodID(JNI.env, javaClass, method, sig) else {
                JNI.api.ExceptionClear(JNI.env)
                JNI.ExceptionReset()
                throw JNIError.methodNotFoundException(key)
            }
            javaStaticMethods[key] = javaMethodID
            return javaMethodID
        }
    }
    
    func getJavaField(forClass className: String, field: String, sig: String) throws -> jfieldID {
        let key = "\(className).\(field)\(sig)"
        let javaClass = try getJavaClass(className)
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
    
    func GlobalFindClass( _ name: UnsafePointer<Int8>,
                               _ file: StaticString = #file, _ line: Int = #line ) -> jclass? {
        guard let clazz: jclass = FindClass(name, file, line ) else {
            return nil
        }
        let result = api.NewGlobalRef(env, clazz)
        api.DeleteLocalRef(env, clazz)
        return result
    }
    
    // MARK: Constructors
    func NewObject(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.NewObjectA(env, clazz, methodID, argsPtr)
        })
    }
    
    // MARK: Object methods
    func CallBooleanMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jboolean {
        return checkArgument(args: args, { argsPtr in
            api.CallBooleanMethodA(env, object, methodID, argsPtr)
        })
    }
    
    func CallByteMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jbyte {
        return checkArgument(args: args, { argsPtr in
            api.CallByteMethodA(env, object, methodID, argsPtr)
        })
    }
    
    func CallShortMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jshort {
        return checkArgument(args: args, { argsPtr in
            api.CallShortMethodA(env, object, methodID, argsPtr)
        })
    }
    
    func CallIntMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jint {
        return checkArgument(args: args, { argsPtr in
            api.CallIntMethodA(env, object, methodID, argsPtr)
        })
    }
    
    func CallLongMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jlong {
        return checkArgument(args: args, { argsPtr in
            api.CallLongMethodA(env, object, methodID, argsPtr)
        })
    }
    
    func CallObjectMethod(_ object: jobject, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.CallObjectMethodA(env, object, methodID, argsPtr)
        })
    }
    
    // MARK: Static methods
    func CallStaticBooleanMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jboolean {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticBooleanMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    func CallStaticByteMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jbyte {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticByteMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    func CallStaticShortMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jshort {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticShortMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    func CallStaticIntMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jint {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticIntMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    func CallStaticLongMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jlong {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticLongMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    func CallStaticObjectMethod(_ clazz: jclass, methodID: jmethodID, args: [jvalue] = []) -> jobject? {
        return checkArgument(args: args, { argsPtr in
            api.CallStaticObjectMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    func dumpReferenceTables() {
        JNI.api.CallStaticVoidMethodA(JNI.env, VMDebugClass, VMDebugDumpReferenceTablesMethod, nil)
        JNI.api.ExceptionClear(JNI.env)
        JNI.ExceptionReset()
    }
    
    private func checkArgument<Result>(args: [jvalue], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        var locals = [jobject]()
        if args.count > 0 {
            var args = args
            return withUnsafePointer(to: &args[0]) { argsPtr in
                defer {
                    _ = JNI.check(Void.self, &locals)
                }
                return block(argsPtr)
            }
        }
        else {
            defer {
                _ = JNI.check(Void.self, &locals)
            }
            return block(nil)
        }
    }
    
    // MARK: New API
    func CallObjectMethod(_ object: jobject, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) -> jobject? {
        return checkArgumentAndWrap(args: args, { argsPtr in
            api.CallObjectMethodA(env, object, methodID, argsPtr)
        })
    }

    func CallStaticObjectMethod(_ clazz: jclass, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) -> jobject? {
        return checkArgumentAndWrap(args: args, { argsPtr in
            api.CallStaticObjectMethodA(env, clazz, methodID, argsPtr)
        })
    }

    func CallVoidMethod(_ object: jobject, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            api.CallVoidMethodA(env, object, methodID, argsPtr)
        })
    }
    
    func CallStaticVoidMethod(_ clazz: jclass, _ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            api.CallStaticVoidMethodA(env, clazz, methodID, argsPtr)
        })
    }
    
    private func checkArgumentAndWrap<Result>(args: [JNIArgumentProtocol], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        var locals = [jobject]()
        if args.count > 0 {
            var argsValues = args.map({ $0.value(locals: &locals) })
            return withUnsafePointer(to: &argsValues[0]) { argsPtr in
                defer {
                    _ = JNI.check(Void.self, &locals)
                }
                return block(argsPtr)
            }
        }
        else {
            defer {
                _ = JNI.check(Void.self, &locals)
            }
            return block(nil)
        }
    }
    
}
