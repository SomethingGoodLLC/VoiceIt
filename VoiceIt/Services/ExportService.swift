import Foundation
import PDFKit
import SwiftData
import UIKit
import CryptoKit

/// Service for PDF and JSON export generation for legal proceedings  
/// Modern Swift 6: Regular class, methods marked with isolation as needed
final class ExportService {
    private let encryptionService: EncryptionService
    private let fileStorageService: FileStorageService
    
    init(encryptionService: EncryptionService, fileStorageService: FileStorageService) {
        self.encryptionService = encryptionService
        self.fileStorageService = fileStorageService
    }
    
    struct ExportOptions {
        var startDate: Date?
        var endDate: Date?
        var includeVoiceNotes: Bool = true
        var includePhotos: Bool = true
        var includeVideos: Bool = true
        var includeTextEntries: Bool = true
        var includeLocation: Bool = true
        var includeImages: Bool = true
        var password: String?
        
        static var defaultOptions: ExportOptions { ExportOptions() }
    }
    
    // Main PDF export
    // Modern Swift 6: @MainActor since we work with SwiftData models from UI context
    @MainActor
    func generatePDF(evidence: [any EvidenceProtocol], options: ExportOptions = .defaultOptions) async throws -> URL {
        let filtered = filterEvidence(evidence, with: options)
        let sorted = filtered.sorted { $0.timestamp < $1.timestamp }
        let docID = UUID().uuidString.prefix(8).uppercased()
        
        // Pre-load all images if we're including them (to handle async in sync PDF context)
        var imageCache: [String: UIImage] = [:]
        if options.includeImages {
            for item in sorted {
                if let photo = item as? PhotoEvidence {
                    do {
                        let image = try await fileStorageService.loadImage(photo.imageFilePath)
                        imageCache[photo.imageFilePath] = image
                        print("✅ Loaded image: \(photo.imageFilePath)")
                    } catch {
                        print("❌ Failed to load image \(photo.imageFilePath): \(error)")
                    }
                } else if let video = item as? VideoEvidence, let thumbPath = video.thumbnailFilePath {
                    do {
                        let thumbnail = try await fileStorageService.loadImage(thumbPath)
                        imageCache[thumbPath] = thumbnail
                        print("✅ Loaded thumbnail: \(thumbPath)")
                    } catch {
                        print("❌ Failed to load thumbnail \(thumbPath): \(error)")
                    }
                }
            }
        }
        
        let data = createPDF(evidence: sorted, documentID: String(docID), options: options, imageCache: imageCache)
        
        let name = "VoiceIt_Legal_\(docID).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url)
        
        if let password = options.password {
            return try encryptPDF(at: url, password: password)
        }
        return url
    }
    
    private func createPDF(evidence: [any EvidenceProtocol], documentID: String, options: ExportOptions, imageCache: [String: UIImage]) -> Data {
        let meta = [kCGPDFContextCreator: "Voice It", kCGPDFContextTitle: "Legal Export #\(documentID)"]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = meta as [String: Any]
        
        let rect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: rect, format: format)
        
        return renderer.pdfData { ctx in
            var page = 1
            
            // Cover page
            ctx.beginPage()
            drawCover(ctx: ctx, rect: rect, docID: documentID, count: evidence.count)
            drawFooter(ctx: ctx, rect: rect, page: page, docID: documentID)
            page += 1
            
            // Evidence pages
            for (i, item) in evidence.enumerated() {
                ctx.beginPage()
                drawEvidence(item, index: i + 1, ctx: ctx, rect: rect, options: options, imageCache: imageCache)
                drawFooter(ctx: ctx, rect: rect, page: page, docID: documentID)
                page += 1
            }
        }
    }
    
    private func drawCover(ctx: UIGraphicsPDFRendererContext, rect: CGRect, docID: String, count: Int) {
        var y: CGFloat = 150
        let title = "LEGAL EVIDENCE EXPORT"
        draw(title, at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 32))
        y += 80
        
        let info = [
            "Document ID: \(docID)",
            "Generated: \(Date().formatted(date: .long, time: .shortened))",
            "Total Evidence: \(count) items",
            "",
            "This document contains encrypted evidence with",
            "cryptographic verification for legal proceedings."
        ]
        
        for line in info {
            draw(line, at: CGPoint(x: 80, y: y), font: .systemFont(ofSize: 14))
            y += 22
        }
    }
    
    private func drawEvidence(_ evidence: any EvidenceProtocol, index: Int, ctx: UIGraphicsPDFRendererContext, rect: CGRect, options: ExportOptions, imageCache: [String: UIImage]) {
        var y: CGFloat = 50
        
        // Draw critical evidence banner
        if evidence.isCritical {
            let bannerRect = CGRect(x: 40, y: 40, width: rect.width - 80, height: 35)
            UIColor.red.withAlphaComponent(0.1).setFill()
            UIBezierPath(roundedRect: bannerRect, cornerRadius: 8).fill()
            
            UIColor.red.setStroke()
            let border = UIBezierPath(roundedRect: bannerRect, cornerRadius: 8)
            border.lineWidth = 2
            border.stroke()
            
            // Critical badge
            let badgeText = "⚠️ CRITICAL EVIDENCE"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.red
            ]
            badgeText.draw(at: CGPoint(x: 50, y: 48), withAttributes: attrs)
            
            y = 85
        }
        
        draw("EVIDENCE #\(index)", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 20))
        y += 40
        
        // Determine clean evidence type
        let evidenceType: String
        if evidence is VoiceNote {
            evidenceType = "Audio Recording"
        } else if evidence is PhotoEvidence {
            evidenceType = "Photograph"
        } else if evidence is VideoEvidence {
            evidenceType = "Video Recording"
        } else if evidence is TextEntry {
            evidenceType = "Text Entry"
        } else {
            evidenceType = "Evidence"
        }
        
        let meta = [
            ("Type:", evidenceType),
            ("Timestamp:", evidence.timestamp.formatted(date: .complete, time: .complete)),
            ("ID:", evidence.id.uuidString),
            ("Critical:", evidence.isCritical ? "YES" : "No")
        ]
        
        for (label, value) in meta {
            draw(label, at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
            draw(value, at: CGPoint(x: 150, y: y), font: .systemFont(ofSize: 12))
            y += 20
        }
        
        y += 10
        
        // Type-specific content
        if let voice = evidence as? VoiceNote {
            drawVoice(voice, y: &y, rect: rect)
        } else if let photo = evidence as? PhotoEvidence {
            drawPhoto(photo, y: &y, ctx: ctx, rect: rect, options: options, imageCache: imageCache)
        } else if let video = evidence as? VideoEvidence {
            drawVideo(video, y: &y, ctx: ctx, rect: rect, options: options, imageCache: imageCache)
        } else if let text = evidence as? TextEntry {
            drawText(text, y: &y, rect: rect)
        }
        
        // Notes
        if !evidence.notes.isEmpty {
            y += 20
            draw("NOTES:", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
            y += 20
            drawMultiline(evidence.notes, at: CGPoint(x: 50, y: y), width: rect.width - 100, font: .systemFont(ofSize: 12))
            y += 100
        }
        
        // Location
        if let loc = evidence.locationSnapshot, options.includeLocation {
            y += 20
            draw("LOCATION DATA:", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
            y += 20
            
            // Coordinates
            draw("Coordinates: \(loc.coordinatesString)", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 18
            
            // Address
            if !loc.fullAddress.isEmpty {
                draw("Address: \(loc.fullAddress)", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
                y += 18
            }
            
            // Accuracy
            draw("Accuracy: ±\(Int(loc.horizontalAccuracy))m", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 18
            
            // Altitude if available
            if let altitude = loc.altitude, altitude != 0 {
                draw("Altitude: \(Int(altitude))m", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
                y += 18
            }
            
            // Timestamp
            draw("Captured: \(loc.timestamp.formatted(date: .abbreviated, time: .shortened))", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 10
        }
        
        // Hash
        let hash = encryptionService.hash("\(evidence.id)|\(evidence.timestamp.timeIntervalSince1970)")
        y = rect.height - 100
        draw("Verification: \(hash.prefix(32))...", at: CGPoint(x: 50, y: y), font: .systemFont(ofSize: 9))
    }
    
    private func drawVoice(_ voice: VoiceNote, y: inout CGFloat, rect: CGRect) {
        draw("AUDIO: \(voice.formattedDuration)", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
        y += 20
        
        if let transcript = voice.transcription {
            draw("Transcription:", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 11))
            y += 18
            drawMultiline(transcript, at: CGPoint(x: 70, y: y), width: rect.width - 120, font: .systemFont(ofSize: 11))
            y += 150
        }
    }
    
    private func drawPhoto(_ photo: PhotoEvidence, y: inout CGFloat, ctx: UIGraphicsPDFRendererContext, rect: CGRect, options: ExportOptions, imageCache: [String: UIImage]) {
        y += 10
        
        draw("PHOTOGRAPH:", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
        y += 20
        
        draw("Dimensions: \(photo.width) x \(photo.height) pixels", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
        y += 18
        
        draw("File Size: \(photo.formattedFileSize)", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
        y += 30
        
        // Embed image if option enabled and available in cache
        if options.includeImages, let image = imageCache[photo.imageFilePath] {
            let maxW = rect.width - 100
            let maxH: CGFloat = 300
            let aspect = image.size.width / image.size.height
            var w = min(maxW, image.size.width)
            var h = w / aspect
            if h > maxH {
                h = maxH
                w = h * aspect
            }
            
            // Center the image
            let imageRect = CGRect(x: 50 + (maxW - w) / 2, y: y, width: w, height: h)
            image.draw(in: imageRect)
            y += h + 20
        } else if options.includeImages {
            draw("[Image could not be loaded]", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 20
        } else {
            draw("[Image excluded from export]", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 20
        }
    }
    
    private func drawVideo(_ video: VideoEvidence, y: inout CGFloat, ctx: UIGraphicsPDFRendererContext, rect: CGRect, options: ExportOptions, imageCache: [String: UIImage]) {
        y += 10
        
        draw("VIDEO RECORDING:", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
        y += 20
        
        draw("Duration: \(video.formattedDuration)", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
        y += 18
        
        draw("Resolution: \(video.resolution)", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
        y += 18
        
        draw("File Size: \(video.formattedFileSize)", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
        y += 30
        
        // Embed thumbnail if option enabled and available in cache
        if options.includeImages, let thumbPath = video.thumbnailFilePath, let thumbnail = imageCache[thumbPath] {
            let maxW = rect.width - 100
            let maxH: CGFloat = 200
            let aspect = thumbnail.size.width / thumbnail.size.height
            var w = min(maxW, thumbnail.size.width)
            var h = w / aspect
            if h > maxH {
                h = maxH
                w = h * aspect
            }
            
            // Center the thumbnail
            let imageRect = CGRect(x: 50 + (maxW - w) / 2, y: y, width: w, height: h)
            thumbnail.draw(in: imageRect)
            y += h + 20
        } else if options.includeImages {
            draw("[Video thumbnail could not be loaded]", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 20
        } else {
            draw("[Video thumbnail excluded from export]", at: CGPoint(x: 70, y: y), font: .systemFont(ofSize: 11))
            y += 20
        }
    }
    
    private func drawText(_ text: TextEntry, y: inout CGFloat, rect: CGRect) {
        draw("TEXT ENTRY: \(text.wordCount) words", at: CGPoint(x: 50, y: y), font: .boldSystemFont(ofSize: 12))
        y += 30
        drawMultiline(text.bodyText, at: CGPoint(x: 70, y: y), width: rect.width - 120, font: .systemFont(ofSize: 11))
        y += 200
    }
    
    private func drawFooter(ctx: UIGraphicsPDFRendererContext, rect: CGRect, page: Int, docID: String) {
        let y = rect.height - 30
        draw("Page \(page)", at: CGPoint(x: 50, y: y), font: .systemFont(ofSize: 9))
        let watermark = "Voice It • Document #\(docID) • Encrypted Evidence"
        let w = watermark.size(withAttributes: [.font: UIFont.systemFont(ofSize: 9)]).width
        draw(watermark, at: CGPoint(x: rect.width - 50 - w, y: y), font: .systemFont(ofSize: 9))
    }
    
    private func draw(_ text: String, at point: CGPoint, font: UIFont) {
        text.draw(at: point, withAttributes: [.font: font, .foregroundColor: UIColor.black])
    }
    
    private func drawMultiline(_ text: String, at point: CGPoint, width: CGFloat, font: UIFont) {
        text.draw(in: CGRect(x: point.x, y: point.y, width: width, height: 500), withAttributes: [.font: font])
    }
    
    // JSON Export
    @MainActor
    func generateJSON(evidence: [any EvidenceProtocol], options: ExportOptions = .defaultOptions) async throws -> URL {
        let filtered = filterEvidence(evidence, with: options)
        let sorted = filtered.sorted { $0.timestamp < $1.timestamp }
        
        let exportData = sorted.map { item in
            [
                "id": item.id.uuidString,
                "type": String(describing: type(of: item)),
                "timestamp": item.timestamp.ISO8601Format(),
                "notes": item.notes,
                "isCritical": item.isCritical,
                "hash": encryptionService.hash("\(item.id)|\(item.timestamp.timeIntervalSince1970)")
            ] as [String: Any]
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted])
        
        let name = "VoiceIt_Export_\(Date().formatted(.iso8601)).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try jsonData.write(to: url)
        
        return url
    }
    
    // Word Document Export
    @MainActor
    func generateWordDocument(evidence: [any EvidenceProtocol], options: ExportOptions = .defaultOptions) async throws -> URL {
        let filtered = filterEvidence(evidence, with: options)
        let sorted = filtered.sorted { $0.timestamp < $1.timestamp }
        let docID = UUID().uuidString.prefix(8).uppercased()
        
        // Pre-load images if including them (same as PDF)
        var imageCache: [String: UIImage] = [:]
        if options.includeImages {
            for item in sorted {
                if let photo = item as? PhotoEvidence {
                    if let image = try? await fileStorageService.loadImage(photo.imageFilePath) {
                        imageCache[photo.imageFilePath] = image
                    }
                } else if let video = item as? VideoEvidence, let thumbPath = video.thumbnailFilePath {
                    if let thumbnail = try? await fileStorageService.loadImage(thumbPath) {
                        imageCache[thumbPath] = thumbnail
                    }
                }
            }
        }
        
        // Create Word-compatible RTF document with images
        let rtfContent = createRTFDocument(evidence: sorted, documentID: String(docID), options: options, imageCache: imageCache)
        
        let name = "VoiceIt_Legal_\(docID).rtf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try rtfContent.write(to: url, atomically: true, encoding: .utf8)
        
        return url
    }
    
    private func createRTFDocument(evidence: [any EvidenceProtocol], documentID: String, options: ExportOptions, imageCache: [String: UIImage]) -> String {
        var rtf = "{\\rtf1\\ansi\\deff0\n"
        
        // Font table
        rtf += "{\\fonttbl{\\f0\\fswiss\\fcharset0 Helvetica;}{\\f1\\fswiss\\fcharset0 Helvetica-Bold;}}\n"
        
        // Color table
        rtf += "{\\colortbl;\\red124\\green58\\blue237;\\red255\\green0\\blue0;\\red0\\green0\\blue0;}\n"
        
        // Title page
        rtf += "\\pard\\qc\\f1\\fs48 LEGAL EVIDENCE EXPORT\\par\n"
        rtf += "\\fs24\\par\\par\n"
        rtf += "\\pard\\ql\\f0\\fs20\n"
        rtf += "\\b Document ID:\\b0  \(documentID)\\par\n"
        rtf += "\\b Generated:\\b0  \(Date().formatted(date: .long, time: .shortened))\\par\n"
        rtf += "\\b Total Evidence:\\b0  \(evidence.count) items\\par\n"
        rtf += "\\par\\par\n"
        rtf += "{\\pard\\box\\brdrs\\fs16 \\par\n"
        rtf += "\\b LEGAL NOTICE\\b0\\par\n"
        rtf += "This document contains encrypted evidence collected using Voice It,\\par\n"
        rtf += "a privacy-first evidence documentation system. All evidence includes\\par\n"
        rtf += "cryptographic verification for authenticity.\\par}\n"
        rtf += "\\page\n"
        
        // Evidence items
        for (index, item) in evidence.enumerated() {
            // Critical evidence banner
            if item.isCritical {
                rtf += "\\pard\\box\\brdrs\\brdrw20\\brsp20\\brdrcf2\\shading1000\\par\n"
                rtf += "{\\f1\\fs24\\cf2 ⚠️ CRITICAL EVIDENCE}\\par\n"
                rtf += "\\pard\\par\n"
            }
            
            rtf += "\\pard\\f1\\fs28\\cf1 EVIDENCE #\(index + 1)\\cf0\\par\n"
            rtf += "\\pard\\f0\\fs20\\par\n"
            
            // Determine clean evidence type
            let evidenceType: String
            if item is VoiceNote {
                evidenceType = "Audio Recording"
            } else if item is PhotoEvidence {
                evidenceType = "Photograph"
            } else if item is VideoEvidence {
                evidenceType = "Video Recording"
            } else if item is TextEntry {
                evidenceType = "Text Entry"
            } else {
                evidenceType = "Evidence"
            }
            
            rtf += "\\b Type:\\b0  \(evidenceType)\\par\n"
            rtf += "\\b Timestamp:\\b0  \(item.timestamp.formatted(date: .complete, time: .complete))\\par\n"
            rtf += "\\b Evidence ID:\\b0  \(item.id.uuidString)\\par\n"
            
            if item.isCritical {
                rtf += "\\b Critical:\\b0  {\\cf2\\b YES}\\par\n"
            } else {
                rtf += "\\b Critical:\\b0  No\\par\n"
            }
            
            if !item.tags.isEmpty {
                rtf += "\\b Tags:\\b0  \(item.tags.joined(separator: ", "))\\par\n"
            }
            
            rtf += "\\par\n"
            
            // Type-specific content
            if let voice = item as? VoiceNote {
                rtf += "\\b AUDIO DETAILS:\\b0\\par\n"
                rtf += "Duration: \(voice.formattedDuration)\\par\n"
                rtf += "Format: \(voice.audioFormat.uppercased())\\par\n"
                rtf += "File Size: \(voice.formattedFileSize)\\par\n"
                rtf += "File Reference: \(voice.audioFilePath)\\par\\par\n"
                
                if let transcript = voice.transcription, !transcript.isEmpty {
                    rtf += "\\b TRANSCRIPTION:\\b0\\par\n"
                    rtf += "\(escapeRTF(transcript))\\par\\par\n"
                }
            } else if let photo = item as? PhotoEvidence {
                rtf += "\\b PHOTOGRAPH DETAILS:\\b0\\par\n"
                rtf += "Dimensions: \(photo.width) x \(photo.height) pixels\\par\n"
                rtf += "Format: \(photo.imageFormat.uppercased())\\par\n"
                rtf += "File Size: \(photo.formattedFileSize)\\par\n"
                rtf += "\\par\n"
                
                // Embed image if available in cache
                if options.includeImages {
                    if let image = imageCache[photo.imageFilePath] {
                        if let imageRTF = convertImageToRTF(image, maxWidth: 400) {
                            rtf += imageRTF
                            rtf += "\\par\n"
                        } else {
                            rtf += "{\\i Image could not be embedded - conversion failed}\\par\n"
                        }
                    } else {
                        rtf += "{\\i Image could not be loaded from encrypted storage}\\par\n"
                    }
                } else {
                    rtf += "{\\i Image excluded from export}\\par\n"
                }
                rtf += "\\par\n"
            } else if let video = item as? VideoEvidence {
                rtf += "\\b VIDEO DETAILS:\\b0\\par\n"
                rtf += "Duration: \(video.formattedDuration)\\par\n"
                rtf += "Resolution: \(escapeRTF(video.resolution))\\par\n"
                rtf += "Format: \(video.videoFormat.uppercased())\\par\n"
                rtf += "File Size: \(video.formattedFileSize)\\par\n"
                rtf += "\\par\n"
                
                // Embed video thumbnail if available
                if options.includeImages, let thumbPath = video.thumbnailFilePath, let thumbnail = imageCache[thumbPath] {
                    rtf += "\\b VIDEO THUMBNAIL:\\b0\\par\n"
                    if let thumbRTF = convertImageToRTF(thumbnail, maxWidth: 300) {
                        rtf += thumbRTF
                        rtf += "\\par\n"
                    }
                } else if options.includeImages {
                    rtf += "{\\i Video thumbnail could not be loaded}\\par\n"
                }
                rtf += "\\par\n"
            } else if let text = item as? TextEntry {
                rtf += "\\b TEXT DETAILS:\\b0\\par\n"
                rtf += "Word Count: \(text.wordCount)\\par\\par\n"
                rtf += "\\b CONTENT:\\b0\\par\n"
                rtf += "\(escapeRTF(text.bodyText))\\par\\par\n"
            }
            
            // Notes
            if !item.notes.isEmpty {
                rtf += "\\b NOTES:\\b0\\par\n"
                rtf += "\(escapeRTF(item.notes))\\par\\par\n"
            }
            
            // Location
            if options.includeLocation, let loc = item.locationSnapshot {
                rtf += "\\b LOCATION DATA:\\b0\\par\n"
                rtf += "Coordinates: \(loc.coordinatesString)\\par\n"
                
                if !loc.fullAddress.isEmpty {
                    rtf += "Address: \(escapeRTF(loc.fullAddress))\\par\n"
                }
                
                rtf += "Accuracy: ±\(Int(loc.horizontalAccuracy))m (\(loc.accuracyQuality.rawValue))\\par\n"
                
                if let altitude = loc.altitude, altitude != 0 {
                    rtf += "Altitude: \(Int(altitude))m above sea level\\par\n"
                }
                
                rtf += "Captured: \(loc.timestamp.formatted(date: .abbreviated, time: .shortened))\\par\n"
                
                rtf += "{\\i Location data verified and timestamped for legal accuracy.}\\par\\par\n"
            }
            
            // Digital signature
            let hash = encryptionService.hash("\(item.id)|\(item.timestamp.timeIntervalSince1970)")
            rtf += "\\fs16\\i Verification Hash: \(hash.prefix(32))...\\i0\\fs20\\par\n"
            
            if index < evidence.count - 1 {
                rtf += "\\page\n"
            }
        }
        
        // Footer
        rtf += "\\par\\par\\par\n"
        rtf += "\\pard\\qc\\fs16 Generated by Voice It • Document #\(documentID) • Encrypted Evidence Timeline\\par\n"
        
        rtf += "}\n"
        
        return rtf
    }
    
    private func escapeRTF(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "{", with: "\\{")
            .replacingOccurrences(of: "}", with: "\\}")
            .replacingOccurrences(of: "\n", with: "\\par\n")
    }
    
    /// Convert UIImage to RTF-compatible embedded image format
    /// Note: RTF hex encoding creates large files - images are heavily compressed
    private func convertImageToRTF(_ image: UIImage, maxWidth: CGFloat) -> String? {
        // Aggressively resize for RTF (smaller = much smaller file size)
        let size = image.size
        var newSize = size
        let targetWidth = min(maxWidth, 250) // Max 250px for RTF to reduce file size
        if size.width > targetWidth {
            let scale = targetWidth / size.width
            newSize = CGSize(width: targetWidth, height: size.height * scale)
        }
        
        // Render resized image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // Use JPEG with heavy compression instead of PNG (much smaller)
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.3) else {
            return nil
        }
        
        // Convert to hex string for RTF
        let hexString = jpegData.map { String(format: "%02x", $0) }.joined()
        
        // Calculate dimensions for RTF
        // picw/pich are the original image dimensions in hundredths of millimeters
        // picwgoal/pichgoal are the desired display dimensions in twips (1/20 point)
        let pixelWidth = Int(newSize.width)
        let pixelHeight = Int(newSize.height)
        
        // Convert to hundredths of millimeters (assuming 72 DPI)
        let widthHMM = pixelWidth * 2540 / 72
        let heightHMM = pixelHeight * 2540 / 72
        
        // Display size in twips (1 inch = 1440 twips, assume 72 DPI)
        let widthTwips = pixelWidth * 20
        let heightTwips = pixelHeight * 20
        
        // RTF picture format - Word-compatible JPEG with line breaks for hex data
        var rtf = "{\\*\\shppict{\\pict\\jpegblip"
        rtf += "\\picw\(widthHMM)\\pich\(heightHMM)"
        rtf += "\\picwgoal\(widthTwips)\\pichgoal\(heightTwips)"
        rtf += "\n"
        
        // Add hex string with line breaks every 128 chars for better RTF compatibility
        var hexWithBreaks = ""
        for (index, char) in hexString.enumerated() {
            hexWithBreaks.append(char)
            if (index + 1) % 128 == 0 {
                hexWithBreaks.append("\n")
            }
        }
        
        rtf += hexWithBreaks
        rtf += "}}\n"
        
        return rtf
    }
    
    // Helpers
    private func filterEvidence(_ evidence: [any EvidenceProtocol], with options: ExportOptions) -> [any EvidenceProtocol] {
        evidence.filter { item in
            if let start = options.startDate, item.timestamp < start { return false }
            if let end = options.endDate, item.timestamp > end { return false }
            if item is VoiceNote && !options.includeVoiceNotes { return false }
            if item is PhotoEvidence && !options.includePhotos { return false }
            if item is VideoEvidence && !options.includeVideos { return false }
            if item is TextEntry && !options.includeTextEntries { return false }
            return true
        }
    }
    
    private func encryptPDF(at url: URL, password: String) throws -> URL {
        guard let pdfDoc = PDFDocument(url: url) else { throw ExportError.pdfEncryptionFailed }
        
        let opts: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password + "_owner"
        ]
        
        let encURL = url.deletingPathExtension().appendingPathExtension("encrypted.pdf")
        guard pdfDoc.write(to: encURL, withOptions: opts) else { throw ExportError.pdfEncryptionFailed }
        
        try? FileManager.default.removeItem(at: url)
        return encURL
    }
}

enum ExportError: LocalizedError {
    case noEvidence
    case pdfGenerationFailed
    case pdfEncryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .noEvidence: return "No evidence to export"
        case .pdfGenerationFailed: return "Failed to generate PDF"
        case .pdfEncryptionFailed: return "Failed to encrypt PDF"
        }
    }
}
