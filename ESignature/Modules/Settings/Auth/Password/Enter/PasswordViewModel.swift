
import Foundation
import LocalAuthentication

final class PasswordViewModel: ObservableObject {
    
    weak var output: PasswordOutput?
    
    private var keychainManager = KeychainManager()
    
    var bioEnable: Bool = false
    
    var isPresent: Bool
    
    init(output: PasswordOutput? = nil, keychainManager: KeychainManager = KeychainManager(), isPresent: Bool) {
        self.output = output
        self.keychainManager = keychainManager
        self.isPresent = isPresent
        
        self.bioEnable = keychainManager.bioEnable ?? false
    }
    
    func dismiss() {
        output?.dissmis()
    }
    
    func pop() {
        output?.pop()
    }
    
    func showResetPassoword() {
        output?.showResetPassword()
    }
    
    func checkPassword(_ code: String) -> Bool {
        code == keychainManager.password
    }
    
    func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        let reason = "Authenticate to reset your password"
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluateError in
                DispatchQueue.main.async {
                    if success {
                        print("Biometric authentication successful")
                        self.showResetPassoword()
                    } else {
                        print("Biometric authentication failed: \(evaluateError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
}

