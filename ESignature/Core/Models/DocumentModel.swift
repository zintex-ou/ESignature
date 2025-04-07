
import Foundation

struct DocumentModel: Hashable, Identifiable {
    let id = UUID()
    var name: String
    let date: Date
    let previewImage: Data?
    let url: URL
}
