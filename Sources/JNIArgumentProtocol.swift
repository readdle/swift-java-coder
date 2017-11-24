//
//  JNIArgumentProtocol.swift
//  SmartMailCoreBridge
//
//  Created by Andrew on 11/14/17.
//

import Foundation
import java_swift

public protocol JNIArgumentProtocol {
    func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue
    func sig() -> String
}

public struct jnull: JNIArgumentProtocol {
    
    let className: String
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue()
    }
    
    public func sig() -> String {
        return "L\(className);"
    }
    
}

extension jint: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(i: self)
    }
    
    public func sig() -> String {
        return "I"
    }
    
}

extension jbyte: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(b: self)
    }
    
    public func sig() -> String {
        return "B"
    }
    
}

extension jchar: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(c: self)
    }
    
    public func sig() -> String {
        return "C"
    }
    
}

extension jshort: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(s: self)
    }
    
    public func sig() -> String {
        return "S"
    }
    
}

extension jlong: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(j: self)
    }
    
    public func sig() -> String {
        return "J"
    }
    
}

extension jboolean: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(z: self)
    }
    
    public func sig() -> String {
        return "Z"
    }
    
}

extension jfloat: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(f: self)
    }
    
    public func sig() -> String {
        return "F"
    }
    
}

extension jdouble: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(d: self)
    }
    
    public func sig() -> String {
        return "D"
    }
    
}

extension String: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(l: self.localJavaObject(locals))
    }
    
    public func sig() -> String {
        return "Ljava/lang/String;"
    }
    
}

extension jobject: JNIArgumentProtocol {
    
    public func value(locals: UnsafeMutablePointer<[jobject]>) -> jvalue {
        return jvalue(l: self)
    }
    
    public func sig() -> String {
        return "L\(JNIObject.getJavaClassname(javaObject: self));"
    }
    
}
