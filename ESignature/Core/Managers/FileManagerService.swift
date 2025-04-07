import Foundation
import UIKit

class FileManagerService {
    static let shared = FileManagerService()
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private init() {
        createDocumentsDirectoryIfNeeded()
    }
    
    private func createDocumentsDirectoryIfNeeded() {
        let dir = documentsDirectory
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                print("Failed to create documents directory: \(error.localizedDescription)")
            }
        }
    }
    
    func getPDF(fileName: String) -> Data? {
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: filePath.path) else {
            print("PDF file not found: \(filePath.lastPathComponent)")
            return nil
        }
        do {
            let data = try Data(contentsOf: filePath)
            print("PDF loaded from: \(filePath.path)")
            return data
        } catch {
            print("Failed to load PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getPDF(from relativePath: String) -> Data? {
        let absoluteURL = documentsDirectory.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: absoluteURL.path) else {
            print("PDF file not found at path: \(absoluteURL.path)")
            return nil
        }
        do {
            let data = try Data(contentsOf: absoluteURL)
            print("PDF loaded from: \(absoluteURL.path)")
            return data
        } catch {
            print("Failed to load PDF: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getFilePath(for fileName: String) -> URL? {
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func saveImage(image: UIImage, fileName: String) -> URL? {
        guard let data = image.pngData(),
              let filePath = getFilePath(for: fileName) else {
            return nil
        }
        do {
            try data.write(to: filePath)
            return filePath
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getImage(from path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        guard fileManager.fileExists(atPath: url.path) else {
            print("Image not found at path: \(path)")
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    
    func getImage(fileName: String) -> UIImage? {
        guard let filePath = getFilePath(for: fileName) else {
            print("Could not get file path for image: \(fileName)")
            return nil
        }
        guard fileManager.fileExists(atPath: filePath.path) else {
            print("Image not found at path: \(filePath.path)")
            return nil
        }
        do {
            let imageData = try Data(contentsOf: filePath)
            return UIImage(data: imageData)
        } catch {
            print("Failed to load image data from: \(filePath.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    func createUniqueFileURL(extension ext: String = "pdf") -> URL {
        let fileName = "document_\(UUID().uuidString).\(ext)"
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func getAbsoluteURL(from relativePath: String) -> URL {
        return documentsDirectory.appendingPathComponent(relativePath)
    }
    
    func copyFile(from sourceURL: URL, to destinationURL: URL) throws {
        var didStartAccessing = false
        if sourceURL.startAccessingSecurityScopedResource() {
            didStartAccessing = true
        }
        defer {
            if didStartAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: sourceURL)
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            print("Failed to copy file: \(error.localizedDescription)")
            throw FileManagerError.fileCopyFailed
        }
    }
    
    func saveFile(data: Data, to url: URL) throws {
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            print("Failed to save file: \(error.localizedDescription)")
            throw error
        }
    }
    
    func renameFile(from oldURL: URL, to newFileName: String) throws -> URL {
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(newFileName)
        guard fileManager.fileExists(atPath: oldURL.path) else {
            throw FileManagerError.fileNotFound
        }
        do {
            try fileManager.moveItem(at: oldURL, to: newURL)
            return newURL
        } catch {
            print("Failed to rename file: \(error.localizedDescription)")
            throw FileManagerError.fileRenamingFailed
        }
    }
    
    func getRelativePath(for url: URL) -> String {
        return url.path.replacingOccurrences(of: documentsDirectory.path + "/", with: "")
    }
    
    func fileExists(fileName: String) -> Bool {
        guard let filePath = getFilePath(for: fileName) else { return false }
        return fileManager.fileExists(atPath: filePath.path)
    }
    
    func deleteFile(fileName: String) {
        guard let filePath = getFilePath(for: fileName),
              fileManager.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try fileManager.removeItem(at: filePath)
        } catch {
            print("Failed to delete file: \(error.localizedDescription)")
        }
    }
}
