
### Swift to Java type mapping

    Int = 32        // java/lang/Integer (only arm32 supported for now)
    Int8 = 8        // java/lang/Byte
    Int16 = 16     	// java/lang/Short
    Int32 = 32     	// java/lang/Integer
    Int64 = 64     	// java/lang/Long
    UInt = 32       // java/lang/Long (doubled to prevent overflow)
    UInt8 = 8       // java/lang/Short
    UInt16 = 16     // java/lang/Integer
    UInt32 = 32     // java/lang/Long
    UInt64 = 64     // java/math/BigInteger
    Bool = 1        // java/lang/Boolean

    []              // java/util/ArrayList
    [:]             // java/util/HashMap

    enum            // java/lang/Enum with rawValue field and valueOf() static method
    OptionSet       // custom type with rawValue field and valueOf() static method

    URL             // android/net/Uri
    UUID            // java/util/UUID
    Date            // java/util/Date
