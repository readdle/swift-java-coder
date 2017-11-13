
### SampleClass for testing

#### Swift
```
public class SampleClass: Codable {
    
    public var string1: String?
    
    public var integer: Int = 32
    public var int8: Int8 = 8
    public var int16: Int16 = 16
    public var int32: Int32 = 32
    public var int64: Int64 = 64
    
    public var uint: UInt = 32
    public var uint8: UInt8 = 32
    public var uint16: UInt16 = 32
    public var uint32: UInt32 = 32
    public var uint64: UInt64 = 32
    
    public var sampleClass: SampleClass?
    
    public var objectArray: [SampleClass] = []
    public var stringArray: [String] = ["one", "two", "free"]
    public var numberArray: [Int] = [1, 2, 3]
    public var arrayInArray: [[Int]] = [[1, 2, 3]]
    public var dictInArray: [[Int:Int]] = [[1: 1, 2: 2, 3: 3]]
    
    public var dictSampleClass: [String: SampleClass] = [:]
    public var dictStrings: [String: String] = ["oneKey": "oneValue"]
    public var dictNumbers: [Int: Int] = [123: 2]
    public var dict64Numbers: [UInt64: UInt64] = [123: 2]
    public var dictInDict: [UInt64: [UInt64: UInt64]] = [123: [123: 2]]
    public var arrayInDict: [UInt64: [UInt64]] = [123: [1, 2, 3]]
    
    public init() {
    
    }
    
}
```

#### Java
```
public class SampleClass {

    String string1;

    Integer integer;
    Byte int8;
    Short int16;
    Integer int32;
    Long int64;

    Long uint;
    Short uint8;
    Integer uint16;
    Long uint32;
    BigInteger uint64;

    SampleClass sampleClass;

    ArrayList<SampleClass> objectArray;
    ArrayList<String> stringArray;
    ArrayList<Integer> numberArray;
    ArrayList<ArrayList<Integer>> arrayInArray;
    ArrayList<HashMap<Integer, Integer>> dictInArray;

    HashMap<String, SampleClass> dictSampleClass;
    HashMap<String, String> dictStrings;
    HashMap<Integer, Integer> dictNumbers;
    HashMap<BigInteger, BigInteger> dict64Numbers;
    HashMap<BigInteger, HashMap<BigInteger, BigInteger>> dictInDict;
    HashMap<BigInteger, ArrayList<BigInteger>> arrayInDict;

    @Override
    public String toString() {
        return "SampleClass{" +
                "string1='" + string1 + '\'' +
                ", integer=" + integer +
                ", int8=" + int8 +
                ", int16=" + int16 +
                ", int32=" + int32 +
                ", int64=" + int64 +
                ", uint=" + uint +
                ", uint8=" + uint8 +
                ", uint16=" + uint16 +
                ", uint32=" + uint32 +
                ", uint64=" + uint64 +
                ", sampleClass=" + sampleClass +
                ", objectArray=" + objectArray +
                ", stringArray=" + stringArray +
                ", numberArray=" + numberArray +
                ", arrayInArray=" + arrayInArray +
                ", dictInArray=" + dictInArray +
                ", dictSampleClass=" + dictSampleClass +
                ", dictStrings=" + dictStrings +
                ", dictNumbers=" + dictNumbers +
                ", dict64Numbers=" + dict64Numbers +
                ", dictInDict=" + dictInDict +
                ", arrayInDict=" + arrayInDict +
                '}';
    }
}
```