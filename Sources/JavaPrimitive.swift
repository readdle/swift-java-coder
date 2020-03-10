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

    public func javaPrimitive() throws -> jint {
        if self > Int(Int32.max) || self < Int(Int32.min) {
            throw JavaCodingError.notEnoughBitsToRepresent("Int \(self)")
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
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jint {
        return jint(self)
    }
}

extension UInt8 {

    public init(fromJavaPrimitive javaPrimitive: jbyte) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jbyte {
        return jbyte(self)
    }
}

extension UInt16 {

    public init(fromJavaPrimitive javaPrimitive: jshort) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jshort {
        return jshort(self)
    }
}

extension UInt32 {

    public init(fromJavaPrimitive javaPrimitive: jint) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jint {
        return jint(self)
    }
}

extension UInt64 {

    public init(fromJavaPrimitive javaPrimitive: jlong) {
        self.init(javaPrimitive)
    }

    public func javaPrimitive() throws -> jlong {
        return jlong(self)
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