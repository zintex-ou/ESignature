import Foundation

final class AuthViewModel: ObservableObject {
    weak var output: AuthOutput?
    
    private var keychainManager = KeychainManager()
    

    @Published var seconds: Int = 5 {
        didSet {
            keychainManager.gracePeriod = TimeInterval(seconds)
        }
    }
    
    @Published var pinEnable: Bool = false
    @Published var bioEnable: Bool = false
    
    init(
        output: AuthOutput?
    ) {
        self.output = output
        self.pinEnable = keychainManager.hasPassword ?? false
        self.bioEnable = keychainManager.bioEnable ?? false
        self.seconds = Int(keychainManager.gracePeriod ?? 5)
    }
    
    func pop() {
        output?.pop()
    }
    
    func showResetPassword() {
        if keychainManager.hasPassword ?? false {
            output?.showPassword()
        } else {
            output?.showResetPassword()
        }
    }
    
    @MainActor func handleTap(on item: AuthEnum) {
        switch item {
            
        case .pinCode:
            pinEnableToggle()
            
        case .biometric:
            bioEnableToggle()
            
        case .reset:
            showResetPassword()
            
        case .lock:
            chooselockTime()
            
        }
    }
    
    func pinEnableToggle() {
        if keychainManager.password == nil {
            output?.showResetPassword()
        } else {
            keychainManager.hasPassword?.toggle()
            print("keychainManager.hasPassword \(String(describing: keychainManager.hasPassword))")
            pinEnable.toggle()
        }
    }
    
    func bioEnableToggle() {
        guard pinEnable else {
            bioEnable = false
            return
        }
        keychainManager.bioEnable?.toggle()
        bioEnable.toggle()
    }
    
    func showPasswordView() {
        showResetPassword()
    }
    
    func chooselockTime() {
        
    }
    
}
