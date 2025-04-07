
import SwiftUI
import Combine

struct WatermarkSheetView: View {
    @ObservedObject var viewModel: EditViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            
            VStack(spacing: .zero) {
                HStack {
                    Text(R.string.localizable.watermarks())
                        .font(.custom(R.font.outfitSemiBold, size: 20))
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    Button() {
                        viewModel.showDialog()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .padding(.leading, 16)
                            
                            Text(R.string.localizable.addNew())
                                .foregroundStyle(.white)
                                .font(.custom(R.font.outfitSemiBold, size: 14))
                                .padding(.trailing, 16)
                        }
                        .frame(height: 38)
                        .background(.c0666EB)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .confirmationDialog(
                            "Choose an option",
                            isPresented: $viewModel.shouldShowingDialog,
                            titleVisibility: .hidden
                        ) {
                            Button("From Gallery") {
                                viewModel.showGalleryWatermark()
                            }
                
                            Button("From Files") {
                                viewModel.showFileWatermark()
                            }
//                
//                            Button("Cancel", role: .cancel) {
//                
//                            }
                
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                contentView
                Spacer()
            }
            .frame(height: 321)
            .padding(.top, 24)
               
        }
        .onAppear {
            viewModel.fetchWatermarks()
        }
    }
    
    private var contentView: some View {
        let models = viewModel.watermarksModel.filter { $0.type == .watermark }
        
        if models.isEmpty {
            return AnyView(emptyStateView)
        } else {
            return AnyView(
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [GridItem(.flexible())], alignment: .center, spacing: 10) {
                        ForEach(models, id: \.id) { watermark in
                            Button {
                                if viewModel.selectedOverlay?.id == watermark.id {
                                    viewModel.selectedOverlay = nil
                                    
                                } else {
                                    viewModel.selectedOverlay = watermark
                                    viewModel.editImage = watermark.image
//                                    viewModel.signCompletion { [weak self] image in
//
//                                    }
                                        viewModel.editState = true
                                    
                                }
                            } label: {
                                ItemViewCell(sign: watermark,
                                             isSelected: viewModel.selectedOverlay?.id == watermark.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                    .frame(height: 186)

                .scrollIndicators(.hidden)
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: .zero) {
            Spacer()
            
            Image(R.image.emptyImage)
                .resizable()
                .scaledToFit()
                .frame(width: 107, height: 116)
            
            Text(R.string.localizable.noWatermarksYet())
                .foregroundStyle(.black)
                .font(.custom(R.font.outfitSemiBold, size: 16))
            
            Text(R.string.localizable.yourWatermarksWillAppearHere())
                .foregroundStyle(.c7C7C7C)
                .font(.custom(R.font.outfitRegular, size: 16))
                .padding(.top, 4)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
}
