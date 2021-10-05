//
// Created by Andriy Druk on 19.04.2020.
//

import Foundation

public enum JavaCodingError: LocalizedError {
    case notSupported(String)
    case cantCreateObject(String)
    case cantFindObject(String)

    public var errorDescription: String? {
        switch self {
        case .notSupported(let message):
            return "Not supported: \(message)"
        case .cantCreateObject(let message):
            return "Can't create object: \(message)"
        case .cantFindObject(let message):
            return "Can't find object: \(message)"
        }
    }
}

// We need one more protocol, because we can't override description func in EncodingError & DecodingError
public protocol JavaCodingErrorDescription {
    var detailedDescription: String { get }
}

fileprivate func contextDescription(codingPath: [CodingKey],
                                    debugDescription: String,
                                    underlyingError: Error?) -> String {
    var underlyingErrorDescription = ""
    if let underlyingError = underlyingError {
        underlyingErrorDescription = " with underlying error: \(underlyingError.localizedDescription)"
    }
    let path = codingPath.map({ $0.stringValue }).joined(separator: "/")
    return "\(debugDescription) [\(path)]" + underlyingErrorDescription
}

extension EncodingError.Context: JavaCodingErrorDescription {
    public var detailedDescription: String {
        return contextDescription(codingPath: codingPath, debugDescription: debugDescription, underlyingError: underlyingError)
    }
}

extension DecodingError.Context: JavaCodingErrorDescription {
    public var detailedDescription: String {
        return contextDescription(codingPath: codingPath, debugDescription: debugDescription, underlyingError: underlyingError)
    }
}

extension EncodingError: JavaCodingErrorDescription {
    public var detailedDescription: String {
        switch self {
        case .invalidValue(let value, let context):
            return "Invalid value \"\(value)\": \(context.detailedDescription)"
        @unknown default:
            return "Not supported encoding error"
        }
    }
}

extension DecodingError: JavaCodingErrorDescription {
    public var detailedDescription: String {
        switch self {
        case .typeMismatch(let value, let context):
            return "Type mismatch \"\(value)\": \(context.detailedDescription)"
        case .valueNotFound(let value, let context):
            return "Value not found \"\(value)\": \(context.detailedDescription)"
        case .keyNotFound(let codingKey, let context):
            return "Key not found \"\(codingKey)\": \(context.detailedDescription)"
        case .dataCorrupted(let context):
            return "Data corrupted: \(context.detailedDescription)"
        @unknown default:
            return "Not supported decoding error"
        }
    }
}