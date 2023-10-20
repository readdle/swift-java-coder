//
// Created by Andrew on 12/22/17.
//

import Foundation
import java_swift
import CAndroidNDK

public typealias JavaEncodableClosure = (Any, [CodingKey]) throws -> jobject
public typealias JavaDecodableClosure = (jobject, [CodingKey]) throws -> Decodable

public struct JavaCoderConfig {

    private static let closuresLock = NSRecursiveLock()

    static var decodableClosures = [String: JavaDecodableClosure]()
    static var encodableClosures = [String: JavaEncodableClosure]()
    static var codableClassNames = [String: String]()

    public static func RegisterType<T: Codable>(type: T.Type,
                                                javaClassname: String,
                                                encodableClosure: @escaping JavaEncodableClosure,
                                                decodableClosure: @escaping JavaDecodableClosure) {
        closuresLock.lock()
        defer {
            closuresLock.unlock()
        }
        let typeName = String(describing: type)
        NSLog("JavaCoderConfig register: \(typeName)")
        codableClassNames[typeName] = javaClassname
        encodableClosures[typeName] = encodableClosure
        decodableClosures[typeName] = decodableClosure
    }

    public static func typeName(from className: String) -> String? {
        for (typeName, registeredClassName) in codableClassNames {
            if registeredClassName == className {
                return typeName
            }
        }
        return nil
    }

    public static func RegisterBasicJavaTypes() {

        RegisterType(type: Int.self, javaClassname: IntegerClassname, encodableClosure: { any, codingPath in
            let value = any as! Int
            let primitive = try value.javaPrimitive(codingPath: codingPath)
            let args = [jvalue(i: primitive)]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Int(fromJavaPrimitive: JNI.CallIntMethod(value, methodID: NumberIntValueMethod))
        })

        RegisterType(type: Int8.self, javaClassname: ByteClassname, encodableClosure: { any, _ in
            let value = any as! Int8
            let primitive = try value.javaPrimitive()
            let args = [jvalue(b: primitive)]
            return JNI.NewObject(ByteClass, methodID: ByteConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Int8(fromJavaPrimitive: JNI.CallByteMethod(value, methodID: NumberByteValueMethod))
        })

        RegisterType(type: Int16.self, javaClassname: ShortClassname, encodableClosure: { any, _ in
            let value = any as! Int16
            let primitive = try value.javaPrimitive()
            let args = [jvalue(s: primitive)]
            return JNI.NewObject(ShortClass, methodID: ShortConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Int16(fromJavaPrimitive: JNI.CallShortMethod(value, methodID: NumberShortValueMethod))
        })

        RegisterType(type: Int32.self, javaClassname: IntegerClassname, encodableClosure: { any, _ in
            let value = any as! Int32
            let primitive = try value.javaPrimitive()
            let args = [jvalue(i: primitive)]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Int32(fromJavaPrimitive: JNI.CallIntMethod(value, methodID: NumberIntValueMethod))
        })

        RegisterType(type: Int64.self, javaClassname: LongClassname, encodableClosure: { any, _ in
            let value = any as! Int64
            let primitive = try value.javaPrimitive()
            let args = [jvalue(j: primitive)]
            return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Int64(fromJavaPrimitive: JNI.CallLongMethod(value, methodID: NumberLongValueMethod))
        })

        RegisterType(type: UInt.self, javaClassname: IntegerClassname, encodableClosure: { any, codingPath in
            let value = any as! UInt
            let primitive = try value.javaPrimitive(codingPath: codingPath)
            let args = [jvalue(i: primitive)]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: { value, _ in
            UInt(fromJavaPrimitive: JNI.CallIntMethod(value, methodID: NumberIntValueMethod))
        })

        RegisterType(type: UInt8.self, javaClassname: ByteClassname, encodableClosure: { any, _ in
            let value = any as! UInt8
            let primitive = try value.javaPrimitive()
            let args = [jvalue(b: primitive)]
            return JNI.NewObject(ByteClass, methodID: ByteConstructor, args: args)!
        }, decodableClosure: { value, _ in
            UInt8(fromJavaPrimitive: JNI.CallByteMethod(value, methodID: NumberByteValueMethod))
        })

        RegisterType(type: UInt16.self, javaClassname: ShortClassname, encodableClosure: { any, _ in
            let value = any as! UInt16
            let primitive = try value.javaPrimitive()
            let args = [jvalue(s: primitive)]
            return JNI.NewObject(ShortClass, methodID: ShortConstructor, args: args)!
        }, decodableClosure: { value, _ in
            UInt16(fromJavaPrimitive: JNI.CallShortMethod(value, methodID: NumberShortValueMethod))
        })

        RegisterType(type: UInt32.self, javaClassname: IntegerClassname, encodableClosure: { any, _ in
            let value = any as! UInt32
            let primitive = try value.javaPrimitive()
            let args = [jvalue(i: primitive)]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: { value, _ in
            UInt32(fromJavaPrimitive: JNI.CallIntMethod(value, methodID: NumberIntValueMethod))
        })

        RegisterType(type: UInt64.self, javaClassname: LongClassname, encodableClosure: { any, _ in
            let value = any as! UInt64
            let primitive = try value.javaPrimitive()
            let args = [jvalue(j: primitive)]
            return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
        }, decodableClosure: { value, _ in
            UInt64(fromJavaPrimitive: JNI.CallLongMethod(value, methodID: NumberLongValueMethod))
        })

        RegisterType(type: Float.self, javaClassname: FloatClassname, encodableClosure: { any, _ in
            let value = any as! Float
            let primitive = jfloat(value)
            let args = [jvalue(f: primitive)]
            return JNI.NewObject(FloatClass, methodID: FloatConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Float(fromJavaPrimitive: JNI.CallFloatMethod(value, methodID: NumberFloatValueMethod))
        })

        RegisterType(type: Double.self, javaClassname: DoubleClassname, encodableClosure: { any, _ in
            let value = any as! Double
            let primitive = jdouble(value)
            let args = [jvalue(d: primitive)]
            return JNI.NewObject(DoubleClass, methodID: DoubleConstructor, args: args)!
        }, decodableClosure: { value, _ in
            Double(fromJavaPrimitive: JNI.CallDoubleMethod(value, methodID: NumberDoubleValueMethod))
        })

        RegisterType(type: Bool.self, javaClassname: BooleanClassname, encodableClosure: { value, _ in
            let args = [jvalue(z: value as! Bool ? JNI.TRUE : JNI.FALSE)]
            return JNI.NewObject(BooleanClass, methodID: BooleanConstructor, args: args)!
        }, decodableClosure: { value, _ in
            JNI.CallBooleanMethod(value, methodID: NumberBooleanValueMethod) == JNI.TRUE
        })

        RegisterType(type: String.self, javaClassname: StringClassname, encodableClosure: { value, _ in
            let valueString = value as! String
            var locals = [jobject]()
            // Locals ignored because JNIStorageObject take ownership of LocalReference
            return valueString.localJavaObject(&locals)!
        }, decodableClosure: { value, _ in
            String(javaObject: value)
        })

        RegisterType(type: Date.self, javaClassname: DateClassname, encodableClosure: { value, _ in
            let valueDate = value as! Date
            let args = [jvalue(j: jlong(valueDate.timeIntervalSince1970 * 1000))]
            return JNI.NewObject(DateClass, methodID: DateConstructor, args: args)!
        }, decodableClosure: { value, _ in
            let timeInterval = JNI.api.CallLongMethodA(JNI.env, value, DateGetTimeMethod, nil)
            // Java save TimeInterval in UInt64 milliseconds
            return Date(timeIntervalSince1970: TimeInterval(timeInterval) / 1000.0)
        })

        RegisterType(type: URL.self, javaClassname: UriClassname, encodableClosure: { value, _ in
            var locals = [jobject]()
            let javaString = (value as! URL).absoluteString.localJavaObject(&locals)
            let args = [jvalue(l: javaString)]
            JNI.SaveFatalErrorMessage("UriConstructor")
            defer {
                JNI.RemoveFatalErrorMessage()
            }
            return JNI.check(JNI.CallStaticObjectMethod(UriClass, methodID: UriConstructor!, args: args)!, &locals)
        }, decodableClosure: { value, _ in
            let pathString = JNI.api.CallObjectMethodA(JNI.env, value, ObjectToStringMethod, nil)
            return URL(string: String(javaObject: pathString))
        })

        RegisterType(type: Data.self, javaClassname: ByteBufferClassname, encodableClosure: { data, codingPath in
            let valueData = data as! Data
            let byteArray = JNI.api.NewByteArray(JNI.env, jint(valueData.count))
            if let throwable = JNI.ExceptionCheck() {
                throw EncodingError.invalidValue(data, EncodingError.Context(codingPath: codingPath,
                        debugDescription: "Can't create NewByteArray \(valueData.count): \(throwable)"))
            }
            try valueData.withUnsafeBytes({ pointer in
                guard let bytes = pointer.baseAddress?.assumingMemoryBound(to: Int8.self) else {
                    throw EncodingError.invalidValue(valueData, EncodingError.Context(codingPath: codingPath,
                            debugDescription: "Can't get unsafeBytes \(valueData.count)"))
                }
                JNI.api.SetByteArrayRegion(JNI.env, byteArray, 0, jint(valueData.count), bytes)
            })
            if let throwable = JNI.ExceptionCheck() {
                throw EncodingError.invalidValue(data, EncodingError.Context(codingPath: codingPath,
                        debugDescription: "SetByteArrayRegion failed \(valueData.count): \(throwable)"))
            }
            JNI.SaveFatalErrorMessage("java/nio/ByteBuffer wrap")
            defer {
                JNI.RemoveFatalErrorMessage()
            }
            return JNI.CallStaticObjectMethod(ByteBufferClass, methodID: ByteBufferWrap, args: [jvalue(l: byteArray)])!
        }, decodableClosure: { value, _ in
            let byteArray = JNI.CallObjectMethod(value, methodID: ByteBufferArray)
            defer {
                JNI.api.DeleteLocalRef(JNI.env, byteArray)
            }
            guard let pointer = JNI.api.GetByteArrayElements(JNI.env, byteArray, nil) else {
                throw JavaCodingError.cantFindObject("ByteBuffer")
            }
            let length = JNI.api.GetArrayLength(JNI.env, byteArray)
            defer {
                JNI.api.ReleaseByteArrayElements(JNI.env, byteArray, pointer, 0)
            }
            return Data(bytes: pointer, count: Int(length))
        })
    }

}