
enum FileManagerError: Error {
    case directoryCreationFailed
    case fileDeletionFailed
    case fileNotFound
    case fileRenamingFailed
    case fileCopyFailed
    case unknown
}
