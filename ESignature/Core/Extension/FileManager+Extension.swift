import Foundation

extension FileManager {
    static var documentsDirectory: URL {
        `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
