//
// Created by Andrew on 12/22/17.
//

import Foundation
import java_swift

public typealias JavaDecodableClosure = (jobject) throws -> Decodable
public typealias JavaEncodableClosure = (Encodable) throws -> jobject

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
        let typeName = String(reflecting: type)
        NSLog("JavaCoderConfig register: \(typeName)")
        codableClassNames[typeName] = javaClassname
        encodableClosures[typeName] = encodableClosure
        decodableClosures[typeName] = decodableClosure
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
            return JNI.check(JNI.CallStaticObjectMethod(UriClass, methodID: UriConstructor!, args: args)!, &locals)
        }, decodableClosure: {
            let pathString = JNI.api.CallObjectMethodA(JNI.env, $0, ObjectToStringMethod, nil)
            return URL(string: String(javaObject: pathString))
        })
    }

}