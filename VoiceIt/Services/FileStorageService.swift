import Foundation
import UIKit
import AVFoundation

/// Service for managing encrypted file storage
final class FileStorageService: @unchecked Sendable {
    // MARK: - Properties
    
    private let encryptionService: EncryptionService
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    init(encryptionService: EncryptionService) {
        self.encryptionService = encryptionService
    }
    
    // MARK: - Audio Files
    
    /// Save and encrypt audio file
    func saveAudioFile(_ sourceURL: URL, compress: Bool = true) async throws -> (path: String, size: Int64, duration: TimeInterval) {
        // Ensure directories exist
        try Constants.Storage.createDirectories()
        
        // Get audio metadata
        let asset = AVURLAsset(url: sourceURL)
        let durationTime = try await asset.load(.duration)
        let duration = CMTimeGetSeconds(durationTime)
        
        // Encrypt file
        let encryptedURL = try await encryptionService.encryptFile(at: sourceURL)
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: encryptedURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Store in audio directory
        let fileName = encryptedURL.lastPathComponent
        let finalPath = Constants.Storage.audioDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: finalPath.path) {
            try fileManager.removeItem(at: finalPath)
        }
        
        try fileManager.moveItem(at: encryptedURL, to: finalPath)
        
        // Clean up original file
        if fileManager.fileExists(atPath: sourceURL.path) {
            try? fileManager.removeItem(at: sourceURL)
        }
        
        return (finalPath.lastPathComponent, fileSize, duration)
    }
    
    /// Load and decrypt audio file
    func loadAudioFile(_ filePath: String) async throws -> URL {
        let encryptedURL = Constants.Storage.audioDirectory.appendingPathComponent(filePath)
        return try await encryptionService.decryptFile(at: encryptedURL)
    }
    
    // MARK: - Image Files
    
    /// Save and encrypt image
    func saveImage(_ image: UIImage, format: String = "heic") async throws -> (path: String, size: Int64, width: Int, height: Int) {
        // Ensure directories exist
        try Constants.Storage.createDirectories()
        
        // Normalize image orientation (fix upside-down/rotated images)
        let normalizedImage = image.normalizedOrientation()
        
        // Convert to data
        let imageData: Data
        switch format.lowercased() {
        case "heic", "heif":
            guard let data = normalizedImage.heicData(compressionQuality: 0.8) else {
                throw FileStorageError.imageConversionFailed
            }
            imageData = data
        case "jpeg", "jpg":
            guard let data = normalizedImage.jpegData(compressionQuality: 0.8) else {
                throw FileStorageError.imageConversionFailed
            }
            imageData = data
        case "png":
            guard let data = normalizedImage.pngData() else {
                throw FileStorageError.imageConversionFailed
            }
            imageData = data
        default:
            guard let data = normalizedImage.heicData(compressionQuality: 0.8) else {
                throw FileStorageError.imageConversionFailed
            }
            imageData = data
        }
        
        // Create temporary file
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "photo_\(timestamp).\(format)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try imageData.write(to: tempURL)
        
        // Encrypt file
        let encryptedURL = try await encryptionService.encryptFile(at: tempURL)
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: encryptedURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Store in photos directory
        let finalFileName = encryptedURL.lastPathComponent
        let finalPath = Constants.Storage.photoDirectory.appendingPathComponent(finalFileName)
        
        if fileManager.fileExists(atPath: finalPath.path) {
            try fileManager.removeItem(at: finalPath)
        }
        
        try fileManager.moveItem(at: encryptedURL, to: finalPath)
        
        // Clean up temp files
        try? fileManager.removeItem(at: tempURL)
        
        return (finalFileName, fileSize, Int(normalizedImage.size.width), Int(normalizedImage.size.height))
    }
    
    /// Load and decrypt image
    func loadImage(_ filePath: String) async throws -> UIImage {
        let encryptedURL = Constants.Storage.photoDirectory.appendingPathComponent(filePath)
        let decryptedURL = try await encryptionService.decryptFile(at: encryptedURL)
        
        guard let imageData = try? Data(contentsOf: decryptedURL),
              let image = UIImage(data: imageData) else {
            throw FileStorageError.imageLoadFailed
        }
        
        // Clean up decrypted temp file
        try? fileManager.removeItem(at: decryptedURL)
        
        return image
    }
    
    /// Generate thumbnail from image
    func generateThumbnail(from image: UIImage, maxSize: CGFloat = 200) -> UIImage {
        let size = image.size
        let scale = maxSize / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - Video Files
    
    /// Save and encrypt video file
    func saveVideoFile(_ sourceURL: URL) async throws -> (path: String, size: Int64, duration: TimeInterval, thumbnailPath: String?) {
        // Ensure directories exist
        try Constants.Storage.createDirectories()
        
        // Get video metadata
        let asset = AVURLAsset(url: sourceURL)
        let durationTime = try await asset.load(.duration)
        let duration = CMTimeGetSeconds(durationTime)
        
        // Generate thumbnail
        var thumbnailPath: String?
        if let thumbnail = try? await generateVideoThumbnail(from: sourceURL) {
            let (path, _, _, _) = try await saveImage(thumbnail, format: "jpeg")
            thumbnailPath = path
        }
        
        // Encrypt video file
        let encryptedURL = try await encryptionService.encryptFile(at: sourceURL)
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: encryptedURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        // Store in video directory
        let fileName = encryptedURL.lastPathComponent
        let finalPath = Constants.Storage.videoDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: finalPath.path) {
            try fileManager.removeItem(at: finalPath)
        }
        
        try fileManager.moveItem(at: encryptedURL, to: finalPath)
        
        // Clean up original file
        if fileManager.fileExists(atPath: sourceURL.path) {
            try? fileManager.removeItem(at: sourceURL)
        }
        
        return (finalPath.lastPathComponent, fileSize, duration, thumbnailPath)
    }
    
    /// Load and decrypt video file
    func loadVideoFile(_ filePath: String) async throws -> URL {
        let encryptedURL = Constants.Storage.videoDirectory.appendingPathComponent(filePath)
        return try await encryptionService.decryptFile(at: encryptedURL)
    }
    
    /// Generate thumbnail from video
    func generateVideoThumbnail(from url: URL, at time: CMTime = .zero) async throws -> UIImage {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        return try await withCheckedThrowingContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(throwing: FileStorageError.thumbnailGenerationFailed)
                }
            }
        }
    }
    
    // MARK: - File Management
    
    /// Delete file
    func deleteFile(at path: String, type: FileType) throws {
        let directory: URL
        switch type {
        case .audio:
            directory = Constants.Storage.audioDirectory
        case .photo:
            directory = Constants.Storage.photoDirectory
        case .video:
            directory = Constants.Storage.videoDirectory
        }
        
        let fileURL = directory.appendingPathComponent(path)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Get total storage used
    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0
        
        let directories = [
            Constants.Storage.audioDirectory,
            Constants.Storage.photoDirectory,
            Constants.Storage.videoDirectory
        ]
        
        for directory in directories {
            if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for case let fileURL as URL in enumerator {
                    if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                       let fileSize = attributes[.size] as? Int64 {
                        totalSize += fileSize
                    }
                }
            }
        }
        
        return totalSize
    }
}

// MARK: - File Type

enum FileType {
    case audio
    case photo
    case video
}

// MARK: - Errors

enum FileStorageError: LocalizedError {
    case imageConversionFailed
    case imageLoadFailed
    case thumbnailGenerationFailed
    case fileNotFound
    case encryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to data."
        case .imageLoadFailed:
            return "Failed to load image from file."
        case .thumbnailGenerationFailed:
            return "Failed to generate video thumbnail."
        case .fileNotFound:
            return "File not found."
        case .encryptionFailed:
            return "Failed to encrypt file."
        }
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    /// Normalize image orientation by redrawing it
    /// Fixes upside-down and rotated images from camera/photo library
    func normalizedOrientation() -> UIImage {
        // If already up, no need to redraw
        if imageOrientation == .up {
            return self
        }
        
        // Redraw image with correct orientation
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
    
    func heicData(compressionQuality: CGFloat = 0.8) -> Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, "public.heic" as CFString, 1, nil),
              let cgImage = self.cgImage else {
            return nil
        }
        
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return mutableData as Data
    }
}
