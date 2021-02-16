//
// Created by Andriy Druk on 24.01.2020.
//

import Foundation
import java_swift
import CJavaVM

extension Bool {

    public init(fromJavaPrimitive javaPrimitive: jboolean) {
        self.init(javaPrimitive == JNI_TRUE)
    }

    public func javaPrimitive() throws -> jboolean {
        return jboolean(self ? JNI_TRUE : JNI_FALSE)
    }
}

extension Int {

    public init(fromJavaPrimitive javaPrimitive: jint) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive(codingPath: [CodingKey] = []) throws -> jint {
        if self < Int(Int32.min) || self > Int(Int32.max) {
            let errorDescription = "Not enough bits to represent Int"
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: errorDescription)
            throw EncodingError.invalidValue(self, context)
        }
        return jint(self)
    }
}

extension Int8 {

    public init(fromJavaPrimitive javaPrimitive: jbyte) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jbyte {
        return jbyte(self)
    }
}

extension Int16 {

    public init(fromJavaPrimitive javaPrimitive: jshort) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jshort {
        return jshort(self)
    }
}

extension Int32 {

    public init(fromJavaPrimitive javaPrimitive: jint) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jint {
        return jint(self)
    }
}

extension Int64 {

    public init(fromJavaPrimitive javaPrimitive: jlong) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jlong {
        return jlong(self)
    }
}

extension UInt {

    public init(fromJavaPrimitive javaPrimitive: jint) {
        #if arch(x86_64) || arch(arm64)
        self.init(UInt32(bitPattern: javaPrimitive))
        #else
        self.init(javaPrimitive)
        #endif
    }

    public func javaPrimitive(codingPath: [CodingKey] = []) throws -> jint {
        if self < UInt(UInt32.min) || self > Int(UInt32.max) {
            let errorDescription = "Not enough bits to represent UInt"
            let context = EncodingError.Context(codingPath: codingPath, debugDescription: errorDescription)
            throw EncodingError.invalidValue(self, context)
        }
        let uint32 = UInt32(self)
        #if arch(x86_64) || arch(arm64)
        return jint(bitPattern: uint32)
        #else
        return jint(uint32)
        #endif
    }
}

extension UInt8 {

    public init(fromJavaPrimitive javaPrimitive: jbyte) {
        self.init(bitPattern: javaPrimitive)
    }

    public func javaPrimitive() throws -> jbyte {
        return jbyte(bitPattern: self)
    }
}

extension UInt16 {

    public init(fromJavaPrimitive javaPrimitive: jshort) {
        self.init(bitPattern: javaPrimitive)
    }

    public func javaPrimitive() throws -> jshort {
        return jshort(bitPattern: self)
    }
}

extension UInt32 {

    public init(fromJavaPrimitive javaPrimitive: jint) {
        #if arch(x86_64) || arch(arm64)
        self.init(bitPattern: javaPrimitive)
        #else
        self.init(javaPrimitive)
        #endif
    }

    public func javaPrimitive() throws -> jint {
        #if arch(x86_64) || arch(arm64)
        return jint(bitPattern: self)
        #else
        return jint(self)
        #endif
    }
}

extension UInt64 {

    public init(fromJavaPrimitive javaPrimitive: jlong) {
        self.init(bitPattern: javaPrimitive)
    }

    public func javaPrimitive() throws -> jlong {
        return jlong(bitPattern: self)
    }
}

extension Float {

    public init(fromJavaPrimitive javaPrimitive: jfloat) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jfloat {
        return jfloat(self)
    }
}

extension Double {

    public init(fromJavaPrimitive javaPrimitive: jdouble) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jdouble {
        return jdouble(self)
    }
}