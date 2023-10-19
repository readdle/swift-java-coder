//
// Created by Andriy Druk on 24.01.2020.
//

import Foundation
import java_swift
import CAndroidNDK

public typealias JavaBoolean = jboolean
public typealias JavaByte = jbyte
public typealias JavaShort = jshort
public typealias JavaInt = jint
public typealias JavaLong = jlong

#if arch(arm)
// Looks like calling convention for ARM32 is broken: probably soft-float vs hard-float
// https://android.googlesource.com/platform/ndk/+/master/docs/HardFloatAbi.md
// We will replace jfloat with 4-byte jint bit pattern
public typealias JavaFloat = jint
#else
public typealias JavaFloat = jfloat
#endif
#if arch(arm)
// We will replace jdouble with 8-byte jlong bit pattern
public typealias JavaDouble = jlong
#else
public typealias JavaDouble = jdouble
#endif

extension Bool {

    public init(fromJavaPrimitive javaPrimitive: JavaBoolean) {
        self.init(javaPrimitive == JNI_TRUE)
    }

    public func javaPrimitive() throws -> JavaBoolean {
        return jboolean(self ? JNI_TRUE : JNI_FALSE)
    }
}

extension Int {

    public init(fromJavaPrimitive javaPrimitive: JavaInt) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive(codingPath: [CodingKey] = []) throws -> JavaInt {
        if self < Int(Int32.min) || self > Int(Int32.max) {
            let errorDescription = "Not enough bits to represent Int"
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: errorDescription)
            throw EncodingError.invalidValue(self, context)
        }
        return jint(self)
    }
}

extension Int8 {

    public init(fromJavaPrimitive javaPrimitive: JavaByte) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaByte {
        return jbyte(self)
    }
}

extension Int16 {

    public init(fromJavaPrimitive javaPrimitive: JavaShort) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaShort {
        return jshort(self)
    }
}

extension Int32 {

    public init(fromJavaPrimitive javaPrimitive: JavaInt) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaInt {
        return jint(self)
    }
}

extension Int64 {

    public init(fromJavaPrimitive javaPrimitive: JavaLong) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaLong {
        return jlong(self)
    }
}

extension UInt {

    public init(fromJavaPrimitive javaPrimitive: JavaInt) {
        #if arch(x86_64) || arch(arm64)
        self.init(UInt32(bitPattern: javaPrimitive))
        #else
        self.init(bitPattern: javaPrimitive)
        #endif
    }

    public func javaPrimitive(codingPath: [CodingKey] = []) throws -> JavaInt {
        if self < UInt(UInt32.min) || self > UInt(UInt32.max) {
            let errorDescription = "Not enough bits to represent UInt"
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: errorDescription)
            throw EncodingError.invalidValue(self, context)
        }
        #if arch(x86_64) || arch(arm64)
        return jint(bitPattern: UInt32(self))
        #else
        return jint(bitPattern: self)
        #endif
    }
}

extension UInt8 {

    public init(fromJavaPrimitive javaPrimitive: JavaByte) {
        self.init(bitPattern: javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaByte {
        return jbyte(bitPattern: self)
    }
}

extension UInt16 {

    public init(fromJavaPrimitive javaPrimitive: JavaShort) {
        self.init(bitPattern: javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaShort {
        return jshort(bitPattern: self)
    }
}

extension UInt32 {

    public init(fromJavaPrimitive javaPrimitive: JavaInt) {
        #if arch(x86_64) || arch(arm64)
        self.init(bitPattern: javaPrimitive)
        #else
        self.init(UInt(bitPattern: javaPrimitive))
        #endif
    }

    public func javaPrimitive() throws -> JavaInt {
        #if arch(x86_64) || arch(arm64)
        return jint(bitPattern: self)
        #else
        return jint(bitPattern: UInt(self))
        #endif
    }
}

extension UInt64 {

    public init(fromJavaPrimitive javaPrimitive: JavaLong) {
        self.init(bitPattern: javaPrimitive)
    }

    public func javaPrimitive() throws -> JavaLong {
        return jlong(bitPattern: self)
    }
}

extension Float {

    public init(fromJavaPrimitive javaPrimitive: jfloat) {
        self.init(javaPrimitive)
    }

    #if arch(arm)
    public init(fromJavaPrimitive javaPrimitive: jint) {
        self.init(bitPattern: UInt32(bitPattern: Int32(javaPrimitive)))
    }
    #endif

    public func javaPrimitive() throws -> JavaFloat {
        #if arch(arm)
        return jint(Int32(bitPattern: bitPattern))
        #else
        return self
        #endif
    }
}

extension Double {

    public init(fromJavaPrimitive javaPrimitive: jdouble) {
        self.init(javaPrimitive)
    }

    #if arch(arm)
    public init(fromJavaPrimitive javaPrimitive: jlong) {
        self.init(bitPattern: UInt64(javaPrimitive))
    }
    #endif

    public func javaPrimitive() throws -> JavaDouble {
        #if arch(arm)
        return jlong(bitPattern: bitPattern)
        #else
        return self
        #endif
    }
}



extension JavaBoolean {
    public static func defaultValue() -> JavaBoolean {
        return jboolean(JNI_FALSE)
    }
}

extension JavaByte {
    public static func defaultValue() -> JavaByte {
        return 0
    }
}

extension JavaShort {
    public static func defaultValue() -> JavaShort {
        return 0
    }
}

extension JavaInt {
    public static func defaultValue() -> JavaInt {
        return 0
    }
}

extension JavaLong {
    public static func defaultValue() -> JavaLong {
        return 0
    }
}

#if arch(arm)
#else
extension JavaFloat {
    public static func defaultValue() -> JavaFloat {
        return 0
    }
}

extension JavaDouble {
    public static func defaultValue() -> JavaDouble {
        return 0
    }
}
#endif