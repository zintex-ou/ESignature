import Foundation
import KeychainAccess

final class KeychainManager {
    private enum Keys: String, CodingKey {
        case userIdKey
        case purchasesExpiresAt
        case hasUsedFreeAccess
        case password
        case hasPassword
        case timeLock
        case gracePeriod
        case bioEnable
    }
    
    @KeychainManager.Value(
        key: Keys.userIdKey,
        encoder: .basic,
        decoder: .basic
    )
    var userIdKey: String?
  
    @KeychainManager.Value(
        key: Keys.purchasesExpiresAt,
        encoder: .basic,
        decoder: .basic
    )
    var purchasesExpiresAt: Date?
    
    @KeychainManager.Value(
        key: Keys.hasUsedFreeAccess,
        encoder: .basic,
        decoder: .basic
    )
    
    var hasUsedFreeAccess: Bool?
    
    @KeychainManager.Value(
        key: Keys.password,
        encoder: .basic,
        decoder: .basic
    )
    
    var password: String?
    
    @KeychainManager.Value(
        key: Keys.hasPassword,
        encoder: .basic,
        decoder: .basic
    )
    
    var hasPassword: Bool?
    
    @KeychainManager.Value(
        key: Keys.timeLock,
        encoder: .basic,
        decoder: .basic
    )
    
    var timeLock: Date?
    
    @KeychainManager.Value(
        key: Keys.gracePeriod,
        encoder: .basic,
        decoder: .basic
    )
    
    var gracePeriod: TimeInterval?
    
    @KeychainManager.Value(
        key: Keys.bioEnable,
        encoder: .basic,
        decoder: .basic
    )
    
    var bioEnable: Bool?
    
    func clear() {
        _userIdKey.clear()
        _purchasesExpiresAt.clear()
        _hasUsedFreeAccess.clear()
        _password.clear()
        _hasPassword.clear()
        _timeLock.clear()
        _gracePeriod.clear()
        _bioEnable.clear()
    }
    
}

extension KeychainManager {
    @propertyWrapper
    struct Value<Element: Codable, Key: CodingKey> {
        private let key: Key
        private let keychain: Keychain
        private let decoder: JSONDecoder
        private let encoder: JSONEncoder
        
        public var wrappedValue: Element? {
            get { readAndDecode(for: key) }
            set {
                guard let object = newValue else {
                    try? keychain.remove(key.stringValue)
                    return
                }
                encodeAndSave(object, for: key)
            }
        }
        
        //MARK: - Initialization
        init(
            key: Key,
            encoder: JSONEncoder,
            decoder: JSONDecoder
        ) {
            let service = Bundle.main.bundleIdentifier ?? "KeychainStorage"
            self.keychain = .init(
                service: service
            )
            self.key = key
            self.encoder = encoder
            self.decoder = decoder
        }
        
        //MARK: - Save/Read data
        private func readAndDecode(for key: Key) -> Element? {
            do {
                guard let data = try keychain.getData(key.stringValue) else {
                    return nil
                }
                return try decoder.decode(Element.self, from: data)
            } catch let error {
                fatalError("KeychainStorage.Value of type: \(Element.self) decode error: \(error.localizedDescription)")
            }
        }
    
        private func encodeAndSave(
            _ value: Element,
            for key: Key
        ) {
            do {
                let data = try encoder.encode(value)
                try keychain.set(
                    data,
                    key: key.stringValue
                )
            } catch let error {
                fatalError("KeychainStorage.Value of type: \(Element.self) encode/save error: \(error.localizedDescription)")
            }
        }
        
        func clear() {
            try? keychain.remove(key.stringValue)
        }
    }
}
