
enum AuthEnum: CaseIterable {
    case pinCode
    case biometric
    case reset
    case lock
    
    var title: String {
        switch self {
        case .pinCode:
            R.string.localizable.enablePINCode()
            
        case .biometric:
            R.string.localizable.biometricAuth()
            
        case .reset:
            R.string.localizable.resetPasscode()
            
        case .lock:
            R.string.localizable.lockTime()

        }
    }
    
    var toggleable: Bool {
        switch self {
        case .pinCode:
            true
            
        case .biometric:
            true
            
        case .reset:
            false
            
        case .lock:
            false
            
        }
    }
    
    var hasInfo: Bool {
        switch self {
        case .pinCode:
            false
            
        case .biometric:
            false
            
        case .reset:
            false
            
        case .lock:
            true
            
        }
    }
}
