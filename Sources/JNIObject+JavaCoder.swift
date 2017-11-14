//
//  JNIObject_JavaCoder.swift
//  SmartMailCoreBridge
//
//  Created by Andrew on 11/14/17.
//

import Foundation
import java_swift

public extension JNIObject {

    
    
    public func callVoidMethod(_ methodID: jmethodID, _ args: JNIArgumentProtocol..., locals: UnsafeMutablePointer<[jobject]>? = nil) {
        checkArgumentAndWrap(args: args, { argsPtr in

            JNI.api.CallVoidMethodA(JNI.env, javaObject, methodID, argsPtr)
        })
    }
    
    private func checkArgumentAndWrap<Result>(args: [JNIArgumentProtocol], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result, locals: UnsafeMutablePointer<[jobject]>? = nil) -> Result {
        if args.count > 0 {
            var argsValues = args.map({ $0.value() })
            return withUnsafePointer(to: &argsValues[0]) { argsPtr in
                defer {
                    if let locals = locals {
                        _ = JNI.check(Void.self, locals)
                    }
                }
                return block(argsPtr)
            }
        }
        else {
            defer {
                if let locals = locals {
                    _ = JNI.check(Void.self, locals)
                }
            }
            return block(nil)
        }
    }
    
}
