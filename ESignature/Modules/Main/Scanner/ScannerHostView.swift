import SwiftUI

struct ScannerHostView: View {
    @Binding var scanResult: [UIImage]
    
    var body: some View {
        ScannerView(scanResult: $scanResult)
            .ignoresSafeArea()
            .background(Color.black.ignoresSafeArea())
    }
}
