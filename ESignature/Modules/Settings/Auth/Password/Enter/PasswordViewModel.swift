
import Foundation
import LocalAuthentication

final class PasswordViewModel: ObservableObject {
    
    weak var output: PasswordOutput?
    
    private var fileManagerService = FileManagerService.shared
    private var coreDataManager = CoreDataManager.shared
    private var keychainManager = KeychainManager()
    
    var bioEnable: Bool = false
    
    @Published var shouldShowingDialog: Bool = false
    
    var isPresent: Bool
    
    var onUnlockComplete: (() -> Void)?
    
    init(output: PasswordOutput? = nil, keychainManager: KeychainManager = KeychainManager(), isPresent: Bool, onUnlockComplete: (() -> Void)? = nil) {
        self.output = output
        self.keychainManager = keychainManager
        self.isPresent = isPresent
        self.onUnlockComplete = onUnlockComplete
        
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
                        if self.isPresent {
                            self.dismiss()
                            self.onUnlockComplete?()
                        } else {
                            self.showResetPassoword()
                        }
                    } else {
                        print("Biometric authentication failed: \(evaluateError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
        }
    }
    
    func forgotPasswordReset() {
        coreDataManager.clearAllData()
        dismiss()
        showResetPassoword()
    }
}

