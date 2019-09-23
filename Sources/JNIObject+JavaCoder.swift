//
//  JNIObject_JavaCoder.swift
//  SmartMailCoreBridge
//
//  Created by Andrew on 11/14/17.
//

import Foundation
import java_swift

public class JNIObjectWithClass: JNIObject {
    
    var privateClassName: String!
    
    public required init(javaObject: jobject?) {
        super.init(javaObject: javaObject)
        privateClassName = JNIObject.getJavaClassname(javaObject: self.javaObject)
    }
    
    public required init(javaObject: jobject?, className: String) {
        super.init(javaObject: javaObject)
        self.privateClassName = className
    }
    
}

public extension JNIObject {
    
    static func getJavaClassname(javaObject: jobject?) -> String {
        let cls = JNI.api.GetObjectClass(JNI.env, javaObject)
        let javaClassName = JNI.api.CallObjectMethodA(JNI.env, cls, ClassGetNameMethod, nil)
        return String(javaObject: javaClassName).replacingOccurrences(of: ".", with: "/")
    }
    
    var className: String {
        if let jniObject = self as? JNIObjectWithClass {
            return jniObject.privateClassName
        }
        return JNIObject.getJavaClassname(javaObject: self.javaObject)
    }

    func callVoidMethod(_ methodID: jmethodID, _ args: JNIArgumentProtocol...) {
        checkArgumentAndWrap(args: args, { argsPtr in
            JNI.api.CallVoidMethodA(JNI.env, javaObject, methodID, argsPtr)
        })
    }
    
    func callStringMethod(method: String? = nil, functionName: String = #function, _ args: JNIArgumentProtocol...) -> String {
        let methodName = method ?? String(functionName.split(separator: "(")[0])
        return String(javaObject: self.internalcallObjectMethod(method: methodName, returnType: "Ljava/lang/String;", args))
    }
    
    func callObjectMethod(method: String? = nil, functionName: String = #function, returnType: String, _ args: JNIArgumentProtocol...) -> jobject? {
        let methodName = method ?? String(functionName.split(separator: "(")[0])
        return self.internalcallObjectMethod(method: methodName, returnType: returnType, args)
    }
    
    private func internalcallObjectMethod(method: String, returnType: String, _ args: [JNIArgumentProtocol]) -> jobject? {
        let sig = "(\(args.map({ $0.sig() }).joined()))\(returnType)"
        let methodID = try! JNI.getJavaMethod(forClass: self.className, method: method, sig: sig)
        return checkArgumentAndWrap(args: args, { argsPtr in
            return JNI.api.CallObjectMethodA(JNI.env, javaObject, methodID, argsPtr)
        })
    }
    
    private func checkArgumentAndWrap<Result>(args: [JNIArgumentProtocol], _ block: (_ argsPtr: UnsafePointer<jvalue>?) -> Result) -> Result {
        if args.count > 0 {
            var locals = [jobject]()
            var argsValues = args.map({ $0.value(locals: &locals) })
            return withUnsafePointer(to: &argsValues[0]) { argsPtr in
                defer {
                    _ = JNI.check(Void.self, &locals)
                }
                return block(argsPtr)
            }
        }
        else {
            return block(nil)
        }
    }
    
}
