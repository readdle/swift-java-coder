//
// Created by Andriy Druk on 24.01.2020.
//

import Foundation
import java_swift
import CJavaVM

public protocol JavaPrimitive: Codable {

    func javaPrimitive() -> JNIArgumentProtocol

}

extension Bool: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jboolean(self ? JNI_TRUE : JNI_FALSE)
    }
}

extension Int: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jint(self)
    }
}

extension Int8: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jbyte(self)
    }
}

extension Int16: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jshort(self)
    }
}

extension Int32: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jint(self)
    }
}

extension Int64: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jlong(self)
    }
}

extension UInt: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jlong(self)
    }
}

extension UInt8: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jshort(self)
    }
}

extension UInt16: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jint(self)
    }
}

extension UInt32: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jlong(self)
    }
}

extension Float: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jfloat(self)
    }
}

extension Double: JavaPrimitive {
    public func javaPrimitive() -> JNIArgumentProtocol {
        return jdouble(self)
    }
}