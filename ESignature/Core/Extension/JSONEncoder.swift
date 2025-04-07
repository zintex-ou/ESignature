
import Foundation

extension JSONEncoder {
    static var basic: JSONEncoder {
        let object = JSONEncoder()
        object.dateEncodingStrategy = .millisecondsSince1970
        object.outputFormatting = .prettyPrinted
        return object
    }
}

extension JSONDecoder {
    static var basic: JSONDecoder {
        let object = JSONDecoder()
        object.dateDecodingStrategy = .millisecondsSince1970
        return object
    }
}
