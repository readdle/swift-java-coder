//
// Created by Andrew on 12/22/17.
//

import Foundation
import java_swift
import CJavaVM

public typealias JavaEncodableClosure = (Any) throws -> jobject
public typealias JavaDecodableClosure = (jobject) throws -> Decodable

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

        RegisterType(type: Int.self, javaClassname: IntegerClassname, encodableClosure: {
            // jint for macOS and Android different, that's why we make cast to jint() here
            let args = [jvalue(i: jint($0 as! Int))]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: {
            return Int(JNI.CallIntMethod($0, methodID: NumberIntValueMethod))
        })

        RegisterType(type: Int8.self, javaClassname: ByteClassname, encodableClosure: {
            let args = [jvalue(b: $0 as! Int8)]
            return JNI.NewObject(ByteClass, methodID: ByteConstructor, args: args)!
        }, decodableClosure: {
            return JNI.CallByteMethod($0, methodID: NumberByteValueMethod)
        })

        RegisterType(type: Int16.self, javaClassname: ShortClassname, encodableClosure: {
            let args = [jvalue(s: $0 as! Int16)]
            return JNI.NewObject(ShortClass, methodID: ShortConstructor, args: args)!
        }, decodableClosure: {
            return JNI.CallShortMethod($0, methodID: NumberShortValueMethod)
        })

        RegisterType(type: Int32.self, javaClassname: IntegerClassname, encodableClosure: {
            let args = [jvalue(i: jint($0 as! Int32))]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: {
            return Int32(JNI.CallIntMethod($0, methodID: NumberIntValueMethod))
        })

        RegisterType(type: Int64.self, javaClassname: LongClassname, encodableClosure: {
            let args = [jvalue(j: $0 as! Int64)]
            return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
        }, decodableClosure: {
            return JNI.CallLongMethod($0, methodID: NumberLongValueMethod)
        })

        RegisterType(type: UInt.self, javaClassname: LongClassname, encodableClosure: {
            let args = [jvalue(j:  Int64($0 as! UInt))]
            return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
        }, decodableClosure: {
            return UInt(JNI.CallLongMethod($0, methodID: NumberLongValueMethod))
        })

        RegisterType(type: UInt8.self, javaClassname: ShortClassname, encodableClosure: {
            let args = [jvalue(s: Int16($0 as! UInt8))]
            return JNI.NewObject(ShortClass, methodID: ShortConstructor, args: args)!
        }, decodableClosure: {
            return UInt8(JNI.CallShortMethod($0, methodID: NumberShortValueMethod))
        })

        RegisterType(type: UInt16.self, javaClassname: IntegerClassname, encodableClosure: {
            let args = [jvalue(i: jint($0 as! UInt16))]
            return JNI.NewObject(IntegerClass, methodID: IntegerConstructor, args: args)!
        }, decodableClosure: {
            return UInt16(JNI.CallIntMethod($0, methodID: NumberIntValueMethod))
        })

        RegisterType(type: UInt32.self, javaClassname: LongClassname, encodableClosure: {
            let args = [jvalue(j: Int64($0 as! UInt32))]
            return JNI.NewObject(LongClass, methodID: LongConstructor, args: args)!
        }, decodableClosure: {
            return UInt32(JNI.CallLongMethod($0, methodID: NumberLongValueMethod))
        })

        RegisterType(type: UInt64.self, javaClassname: BigIntegerClassname, encodableClosure: {
            var locals = [jobject]()
            let args = [jvalue(l: String($0 as! UInt64).localJavaObject(&locals))]
            return JNI.check(JNI.NewObject(BigIntegerClass, methodID: BigIntegerConstructor, args: args)!, &locals)
        }, decodableClosure: {
            let javaString = JNI.CallObjectMethod($0, methodID: ObjectToStringMethod)
            defer {
                JNI.api.DeleteLocalRef(JNI.env, javaString)
            }
            let stringRepresentation = String(javaObject: javaString)
            return UInt64(stringRepresentation)
        })

        RegisterType(type: Float.self, javaClassname: FloatClassname, encodableClosure: {
            let args = [jvalue(f: $0 as! Float)]
            return JNI.NewObject(FloatClass, methodID: FloatConstructor, args: args)!
        }, decodableClosure: {
            return JNI.api.CallFloatMethodA(JNI.env, $0, NumberFloatValueMethod, nil)
        })

        RegisterType(type: Double.self, javaClassname: DoubleClassname, encodableClosure: {
            let args = [jvalue(d: $0 as! Double)]
            return JNI.NewObject(DoubleClass, methodID: DoubleConstructor, args: args)!
        }, decodableClosure: {
            return JNI.api.CallDoubleMethodA(JNI.env, $0, NumberDoubleValueMethod, nil)
        })

        RegisterType(type: Bool.self, javaClassname: BooleanClassname, encodableClosure: {
            let args = [jvalue(z: $0 as! Bool ? JNI.TRUE : JNI.FALSE)]
            return JNI.NewObject(BooleanClass, methodID: BooleanConstructor, args: args)!
        }, decodableClosure: {
            return (JNI.CallBooleanMethod($0, methodID: NumberBooleanValueMethod) == JNI.TRUE)
        })

        RegisterType(type: String.self, javaClassname: StringClassname, encodableClosure: {
            let valueString = $0 as! String
            var locals = [jobject]()
            // Locals ignored because JNIStorageObject take ownership of LocalReference
            return valueString.localJavaObject(&locals)!
        }, decodableClosure: {
            return String(javaObject: $0)
        })

        RegisterType(type: Date.self, javaClassname: DateClassname, encodableClosure: {
            let valueDate = $0 as! Date
            let args = [jvalue(j: jlong(valueDate.timeIntervalSince1970 * 1000))]
            return JNI.NewObject(DateClass, methodID: DateConstructor, args: args)!
        }, decodableClosure: {
            let timeInterval = JNI.api.CallLongMethodA(JNI.env, $0, DateGetTimeMethod, nil)
            // Java save TimeInterval in UInt64 milliseconds
            return Date(timeIntervalSince1970: TimeInterval(timeInterval) / 1000.0)
        })

        RegisterType(type: URL.self, javaClassname: UriClassname, encodableClosure: {
            var locals = [jobject]()
            let javaString = ($0 as! URL).absoluteString.localJavaObject(&locals)
            let args = [jvalue(l: javaString)]
            JNI.SaveFatalErrorMessage("UriConstructor")
            defer {
                JNI.RemoveFatalErrorMessage()
            }
            return JNI.check(JNI.CallStaticObjectMethod(UriClass, methodID: UriConstructor!, args: args)!, &locals)
        }, decodableClosure: {
            let pathString = JNI.api.CallObjectMethodA(JNI.env, $0, ObjectToStringMethod, nil)
            return URL(string: String(javaObject: pathString))
        })

        RegisterType(type: Data.self, javaClassname: ByteBufferClassname, encodableClosure: {
            let valueData = $0 as! Data
            let byteArray = JNI.api.NewByteArray(JNI.env, Int32(valueData.count))
            if let throwable = JNI.ExceptionCheck() {
                throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: [],
                        debugDescription: "Can't create NewByteArray \(valueData.count)"))
            }
            valueData.withUnsafeBytes({ (pointer: UnsafePointer<Int8>) -> Void in
                JNI.api.SetByteArrayRegion(JNI.env, byteArray, 0, Int32(valueData.count), pointer)
            })
            if let throwable = JNI.ExceptionCheck() {
                throw EncodingError.invalidValue($0, EncodingError.Context(codingPath: [],
                        debugDescription: "SetByteArrayRegion failed \(valueData.count)"))
            }
            JNI.SaveFatalErrorMessage("java/nio/ByteBuffer wrap")
            defer {
                JNI.RemoveFatalErrorMessage()
            }
            return JNI.CallStaticObjectMethod(ByteBufferClass, methodID: ByteBufferWrap, args: [jvalue(l: byteArray)])!
        }, decodableClosure: {
            let byteArray = JNI.CallObjectMethod($0, methodID: ByteBufferArray)
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