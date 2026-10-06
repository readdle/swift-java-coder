import Testing
import java_swift

@Suite(.serialized)
struct FindClassTests {

    @Test func findClassWithoutClassLoader() throws {
        JNI.classLoader = nil
        let clazz = try #require(JNI.FindClass("java/lang/Integer"))
        JNI.DeleteLocalRef(clazz)
    }

    @Test func findClassThroughClassLoader() throws {
        let env = try #require(JNI.env)
        let loaderClass = try #require(JNI.api.FindClass(env, "java/lang/ClassLoader"))
        let getSystemLoader = try #require(JNI.api.GetStaticMethodID(env, loaderClass, "getSystemClassLoader",
                                                                    "()Ljava/lang/ClassLoader;"))
        let loader = try #require(JNI.api.CallStaticObjectMethodA(env, loaderClass, getSystemLoader, nil))
        JNI.classLoader = JNI.api.NewGlobalRef(env, loader)
        JNI.DeleteLocalRef(loader)
        JNI.DeleteLocalRef(loaderClass)
        defer {
            JNI.api.DeleteGlobalRef(env, JNI.classLoader)
            JNI.classLoader = nil
        }

        // JNI internal (slash) names must be translated for ClassLoader.loadClass.
        let clazz = try #require(JNI.FindClass("java/lang/Integer"))
        JNI.DeleteLocalRef(clazz)

        #expect(JNI.FindClass("does/not/Exist") == nil)
        JNI.api.ExceptionClear(env) // caller's job, same as raw JNI FindClass
    }
}
