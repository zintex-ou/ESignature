import Foundation
import FirebaseRemoteConfig

enum RemoteConfigValueKey: String {
    case remote
}

struct PaywallConfig: Codable {
    var review: Bool
    var trial: Int
}

final class RemoteConfigProvider: ObservableObject {
    static let shared = RemoteConfigProvider()
    
    // MARK: - Published Properties
    @Published private(set) var isReview = true
    @Published private(set) var fetchComplete = false
    
    // MARK: - Configuration
    private(set) var config: PaywallConfig
    private let isDebug: Bool
    private let remoteConfig: RemoteConfig
    
    // MARK: - Initialization
    private init() {
        self.remoteConfig = RemoteConfig.remoteConfig()
        self.isDebug = true
        self.config = Self.loadDefaultConfig()
        setupRemoteConfig()
    }
    
    // MARK: - Public Methods
    func fetchConfig() async {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            try await handleConfigStatus(status)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Private Methods
    private func setupRemoteConfig() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = isDebug ? 0 : 43200
        remoteConfig.configSettings = settings
        remoteConfig.setDefaults(Self.defaultRemoteConfigValues())
    }
    
    private func handleConfigStatus(_ status: RemoteConfigFetchAndActivateStatus) async throws {
        guard status != .error else {
            throw RemoteConfigError.activationFailed
        }
        
        try await updateLocalConfig()
        await MainActor.run { fetchComplete = true }
    }
    
    @MainActor
    private func updateLocalConfig() throws {
        let data = remoteConfig[RemoteConfigValueKey.remote.rawValue].dataValue
        config = try JSONDecoder().decode(PaywallConfig.self, from: data)
        isReview = config.review
    }
    
    // MARK: - Default Configuration
    private static func loadDefaultConfig() -> PaywallConfig {
        PaywallConfig(
            review: true,
            trial: 1
        )
    }
    
    private static func defaultRemoteConfigValues() -> [String: NSObject] {
        guard let data = try? JSONEncoder().encode(loadDefaultConfig()) else {
            return [:]
        }
        return [RemoteConfigValueKey.remote.rawValue: data as NSObject]
    }
    
    private func handleError(_ error: Error) {
        print("RemoteConfig Error: \(error.localizedDescription)")
    }
}

// MARK: - Error Handling
extension RemoteConfigProvider {
    enum RemoteConfigError: Error {
        case activationFailed
        case decodingFailed
    }
}
