import CoreData
import UIKit
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    private let persistentContainer: NSPersistentCloudKitContainer

    private init() {
        persistentContainer = NSPersistentCloudKitContainer(name: "SignCoreData")
        guard let description = persistentContainer.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.pdfsignature.electronic.doc.com"
        )
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    

    func clearAllData() {
        clearDocuments()
        clearSigns()
        clearStamps()
        clearWatermarks()
    }
    
    private func clearDocuments() {
        clearEntity(entityName: "DocumentEntity")
    }
    
    private func clearSigns() {
        clearEntity(entityName: "SignEntity")
    }
    
    private func clearStamps() {
        clearEntity(entityName: "StampEntity")
    }
    
    private func clearWatermarks() {
        clearEntity(entityName: "WatermarkEntity")
    }
    
    private func clearEntity(entityName: String) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        do {
            let objects = try context.fetch(fetchRequest)
            for object in objects {
                context.delete(object)
            }
            saveContext()
        } catch {
            print("Failed to clear entity \(entityName): \(error.localizedDescription)")
        }
    }

    
    // MARK: - Document Methods
    
    func createDocument(id: String, isSigned: Bool, url: String, name: String, image: UIImage) {
        let absoluteURL = FileManagerService.shared.getAbsoluteURL(from: url)
        guard FileManager.default.fileExists(atPath: absoluteURL.path) else {
            print("File not found at path: \(absoluteURL.path)")
            return
        }
        
        let previewData = image.fixedOrientation().jpegData(compressionQuality: 0.5) ?? Data()
        
        let context = CoreDataManager.shared.persistentContainer.viewContext
        
        let document = DocumentEntity(context: context)
        document.id = id
        document.isSigned = isSigned
        document.name = name
        document.url = url
        document.preview = previewData
        document.date = Date()
        
        saveContext()
    }

    func fetchDocuments() -> [DocumentEntity] {
        let request: NSFetchRequest<DocumentEntity> = DocumentEntity.fetchRequest()
        do {
            let results = try context.fetch(request)
            return results.filter { $0.url != nil }
        } catch {
            print("Failed to fetch documents: \(error.localizedDescription)")
            return []
        }
    }
    
    func updatePreviewOfDocument(with id: String, isSigned: Bool, preview: Data) {
        guard let document = loadDocumentItem(with: id) else {
            print("Document with ID \(id) not found")
            return
        }
        
        document.isSigned = isSigned
        document.id = id
        document.preview = preview
        document.date = Date()
        saveContext()
    }
    
    func loadDocumentItem(with id: String) -> DocumentEntity? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DocumentEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        fetchRequest.propertiesToFetch = ["id", "isSigned", "name", "url", "preview"]
        fetchRequest.resultType = .managedObjectResultType
        
        do {
            let results = try context.fetch(fetchRequest) as? [DocumentEntity]
            return results?.first
        } catch {
            print("Failed to load document: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteDocument(_ document: DocumentEntity) {
        context.delete(document)
        saveContext()
    }

    
    // MARK: - Sign Methods
    
    func createSign(id: String, url: String, name: String) {
        let sign = SignEntity(context: context)
        sign.id = id
        sign.url = url
        sign.name = name
        saveContext()
    }
    
    func fetchSigns() -> [SignEntity] {
        let request: NSFetchRequest<SignEntity> = SignEntity.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Stamp Methods
    
    func createStamp(id: String, url: String, name: String) {
        let stamp = StampEntity(context: context)
        stamp.id = id
        stamp.url = url
        stamp.name = name
        saveContext()
    }
    
    func fetchStamps() -> [StampEntity] {
        let request: NSFetchRequest<StampEntity> = StampEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id != nil AND url != nil")
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch stamps: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Watermark Methods
    
    func createWatermark(id: String, url: String, name: String) {
        let watermark = WatermarkEntity(context: context)
        watermark.id = id
        watermark.url = url
        watermark.name = name
        saveContext()
    }
    
    func fetchWatermark() -> [WatermarkEntity] {
        let request: NSFetchRequest<WatermarkEntity> = WatermarkEntity.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
}
