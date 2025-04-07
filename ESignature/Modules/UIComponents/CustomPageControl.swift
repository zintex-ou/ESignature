import SwiftUI

struct CustomPageControl: View {
    @Binding var currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                pageIndicator(for: index)
            }
        }
    }
    
    @ViewBuilder
    private func pageIndicator(for index: Int) -> some View {
        let isCurrentPage = index == currentPage
        
        if isCurrentPage {
            Capsule()
                .fill(.white)
                .frame(width: 28, height: 6)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
        } else {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .animation(.easeInOut(duration: 0.2), value: currentPage)
                .opacity(0.5)
        }
    }

}
