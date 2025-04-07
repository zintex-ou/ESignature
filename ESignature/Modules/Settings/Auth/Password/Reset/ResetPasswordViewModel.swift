
import Foundation

final class ResetPasswordViewModel: ObservableObject {
    
    weak var output: ResetPasswordOutput?
    
    private var keychainManager = KeychainManager()
    
    init(output: ResetPasswordOutput? = nil, keychainManager: KeychainManager = KeychainManager()) {
        self.output = output
        self.keychainManager = keychainManager
    }
    
    func setPassword(_ code: String) {
        keychainManager.password = code
        keychainManager.hasPassword = true
        keychainManager.bioEnable = true
        keychainManager.gracePeriod = 5
    }
    
    func popToRoot() {
        output?.popToRoot()
    }
}

