//
//  JNIArgumentProtocol.swift
//  SmartMailCoreBridge
//
//  Created by Andrew on 11/14/17.
//

import Foundation
import java_swift

public protocol JNIArgumentProtocol {
    func value() -> jvalue
}

public struct jnull: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue()
    }
    
}

extension jint: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(i: self)
    }
    
}

extension jbyte: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(b: self)
    }
    
}

extension jchar: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(c: self)
    }
    
}

extension jshort: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(s: self)
    }
    
}

extension jlong: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(j: self)
    }
    
}

extension jboolean: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(z: self)
    }
    
}

extension jfloat: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(f: self)
    }
    
}

extension jdouble: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(d: self)
    }
    
}

extension jobject: JNIArgumentProtocol {
    
    public func value() -> jvalue {
        return jvalue(l: self)
    }
    
}

// For backward compatibility
extension jvalue: JNIArgumentProtocol {

    public func value() -> jvalue {
        return self
    }
    
}
