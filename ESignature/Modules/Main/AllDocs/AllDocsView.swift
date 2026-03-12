
import SwiftUI

struct AllDocsView: View {
    
    @ObservedObject var viewModel: MainViewModel
    
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(R.string.localizable.allDocuments())
                        .foregroundStyle(.c191919)
                        .font(.custom(R.font.outfitSemiBold, size: 20))
                        .padding(.leading, 16)
                    
                    Spacer()
                }
                .padding(.top, 16)
                
                CustomSearchBar(text: $searchText, placeholder: R.string.localizable.search())
                             .padding(.horizontal)
                             .padding(.vertical, 8)
                
                historyStack
            }
        }
    }
    
    @ViewBuilder
    private var historyStack: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredDocuments(), id: \.id) { doc in
                            SignedViewCell(
                                name: doc.name,
                                image: doc.preview,
                                isSigned: doc.isSigned,
                                date: doc.date,
                                onRename: {
                                    viewModel.selectedDocumentID = doc.id
                                    viewModel.shouldRenameSheet = true
                                },
                                onShare: {
                                    viewModel.shareDocument(at: doc.url)
                                },
                                onPrint: {
                                    viewModel.printDocument(at: doc.url)
                                },
                                onDelete: {
                                    viewModel.deleteDocument(doc)
                                },
                                onTap: {
                                    viewModel.selectedDocumentID = doc.id
                                    viewModel.showFile(doc.url ?? "", fileName: doc.name)
                                }
                            )
                        }
                    }
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func sortDisplayDocs() -> [DocumentEntity] {
        viewModel.documents?
            .sorted { ($0.date ?? Date()) > ($1.date ?? Date()) } ?? []
    }
    
    private func filteredDocuments() -> [DocumentEntity] {
        let allDocs = sortDisplayDocs()
        guard !searchText.isEmpty else {
            return allDocs
        }
        return allDocs.filter { doc in
            (doc.name?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
}
