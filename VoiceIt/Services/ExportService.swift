import Foundation
import PDFKit
import SwiftData

/// Service for generating PDF and JSON exports of evidence
final class ExportService: Sendable {
    // MARK: - Properties
    
    private let encryptionService: EncryptionService
    
    // MARK: - Initialization
    
    init(encryptionService: EncryptionService) {
        self.encryptionService = encryptionService
    }
    
    // MARK: - PDF Export
    
    /// Generate PDF export of evidence
    func generatePDF(evidence: [any EvidenceProtocol], includeImages: Bool = true) async throws -> URL {
        let pdfData = try await createPDFData(evidence: evidence, includeImages: includeImages)
        
        let fileName = "VoiceIt_Export_\(Date().formatted(.iso8601)).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try pdfData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Create PDF data from evidence
    private func createPDFData(evidence: [any EvidenceProtocol], includeImages: Bool) async throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Voice It",
            kCGPDFContextAuthor: "Evidence Documentation",
            kCGPDFContextTitle: "Evidence Export"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            // Title page
            context.beginPage()
            drawTitlePage(in: context, rect: pageRect)
            
            // Evidence pages
            for item in evidence.sorted(by: { $0.timestamp > $1.timestamp }) {
                context.beginPage()
                drawEvidencePage(item, in: context, rect: pageRect, includeImages: includeImages)
            }
        }
        
        return data
    }
    
    private func drawTitlePage(in context: UIGraphicsPDFRendererContext, rect: CGRect) {
        let titleFont = UIFont.boldSystemFont(ofSize: 28)
        let dateFont = UIFont.systemFont(ofSize: 14)
        
        let title = "Evidence Documentation"
        let date = "Generated: \(Date().formatted(date: .long, time: .shortened))"
        
        let titleRect = CGRect(x: 50, y: 200, width: rect.width - 100, height: 50)
        let dateRect = CGRect(x: 50, y: 250, width: rect.width - 100, height: 30)
        
        title.draw(in: titleRect, withAttributes: [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ])
        
        date.draw(in: dateRect, withAttributes: [
            .font: dateFont,
            .foregroundColor: UIColor.gray
        ])
    }
    
    private func drawEvidencePage(_ evidence: any EvidenceProtocol, in context: UIGraphicsPDFRendererContext, rect: CGRect, includeImages: Bool) {
        var yPosition: CGFloat = 50
        
        // Type and timestamp
        let headerFont = UIFont.boldSystemFont(ofSize: 18)
        let bodyFont = UIFont.systemFont(ofSize: 12)
        
        let header = evidence.displayTitle
        let timestamp = "Date: \(evidence.timestamp.formatted(date: .long, time: .shortened))"
        
        header.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: headerFont])
        yPosition += 30
        
        timestamp.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
        yPosition += 25
        
        // Notes
        if !evidence.notes.isEmpty {
            let notesLabel = "Notes:"
            notesLabel.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 12)
            ])
            yPosition += 20
            
            let notesRect = CGRect(x: 50, y: yPosition, width: rect.width - 100, height: 200)
            evidence.notes.draw(in: notesRect, withAttributes: [.font: bodyFont])
            yPosition += 220
        }
        
        // Location
        if let location = evidence.locationSnapshot {
            let locationLabel = "Location: \(location.shortAddress.isEmpty ? location.coordinatesString : location.shortAddress)"
            locationLabel.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: [.font: bodyFont])
            yPosition += 20
        }
    }
    
    // MARK: - JSON Export
    
    /// Generate JSON export of evidence
    func generateJSON(evidence: [any EvidenceProtocol]) async throws -> URL {
        let exportData = evidence.map { item in
            EvidenceExportData(
                id: item.id.uuidString,
                type: String(describing: type(of: item)),
                timestamp: item.timestamp.ISO8601Format(),
                notes: item.notes,
                tags: item.tags,
                isCritical: item.isCritical,
                location: item.locationSnapshot.map { location in
                    LocationExportData(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        address: location.fullAddress,
                        timestamp: location.timestamp.ISO8601Format()
                    )
                }
            )
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(exportData)
        
        let fileName = "VoiceIt_Export_\(Date().formatted(.iso8601)).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    // MARK: - Encrypted Export
    
    /// Generate encrypted export with password
    func generateEncryptedExport(evidence: [any EvidenceProtocol], password: String) async throws -> URL {
        // Generate JSON export first
        let jsonURL = try await generateJSON(evidence: evidence)
        
        // Encrypt the file
        let encryptedURL = try await encryptionService.encryptFile(at: jsonURL)
        
        // Clean up unencrypted file
        try? FileManager.default.removeItem(at: jsonURL)
        
        return encryptedURL
    }
}

// MARK: - Export Data Models

struct EvidenceExportData: Codable {
    let id: String
    let type: String
    let timestamp: String
    let notes: String
    let tags: [String]
    let isCritical: Bool
    let location: LocationExportData?
}

struct LocationExportData: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
    let timestamp: String
}
