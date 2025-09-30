import Foundation
import UIKit
import SwiftData
import MessageUI

/// Service for handling emergency features (panic button, 911, emergency contacts)
final class EmergencyService: Sendable {
    // MARK: - Properties
    
    private let emergencyNumber = "911" // US emergency number
    
    /// Whether to automatically call 911 when panic button is activated
    @MainActor
    var shouldCall911: Bool {
        get { UserDefaults.standard.bool(forKey: "shouldCall911") }
        set { UserDefaults.standard.set(newValue, forKey: "shouldCall911") }
    }
    
    // MARK: - Emergency Calling
    
    /// Initiate emergency call to 911
    @MainActor
    func call911() {
        guard let url = URL(string: "tel://\(emergencyNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Call emergency contact
    @MainActor
    func callContact(_ contact: EmergencyContact) {
        let phoneNumber = contact.phoneNumber.filter { $0.isNumber }
        guard let url = URL(string: "tel://\(phoneNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - SMS/Message
    
    /// Send SMS to emergency contact
    @MainActor
    func sendSMS(to contact: EmergencyContact, message: String) {
        let phoneNumber = contact.phoneNumber.filter { $0.isNumber }
        
        // Encode message for URL
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("⚠️ Failed to encode message")
            return
        }
        
        // Use correct SMS URL format: sms:phoneNumber&body=message (no ? needed)
        let smsURL = "sms:\(phoneNumber)&body=\(encodedMessage)"
        print("📱 Opening SMS URL: \(smsURL)")
        
        guard let url = URL(string: smsURL) else {
            print("⚠️ Failed to create URL from: \(smsURL)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            print("✅ SMS URL opened successfully")
        } else {
            print("❌ Cannot open SMS URL")
        }
    }
    
    // MARK: - Location Sharing
    
    /// Generate emergency message with location
    func generateEmergencyMessage(location: LocationSnapshot?) -> String {
        var message = "EMERGENCY: I need help."
        
        if let location = location {
            message += "\nMy location: \(location.fullAddress.isEmpty ? location.coordinatesString : location.fullAddress)"
            message += "\nCoordinates: \(location.coordinatesString)"
        }
        
        message += "\n\nSent from Voice It app"
        
        return message
    }
    
    /// Share location with emergency contact
    @MainActor
    func shareLocation(with contact: EmergencyContact, location: LocationSnapshot) {
        let message = generateEmergencyMessage(location: location)
        sendSMS(to: contact, message: message)
    }
    
    // MARK: - Panic Button
    
    /// Handle panic button press (calls 911 and notifies emergency contacts)
    @MainActor
    func activatePanicButton(
        emergencyContacts: [EmergencyContact],
        location: LocationSnapshot?
    ) {
        // Call 911 if enabled in settings
        if shouldCall911 {
            print("📞 Calling 911 (enabled in settings)")
            call911()
        } else {
            print("⏭️ Skipping 911 call (disabled in settings)")
        }
        
        // Notify auto-notify contacts
        let autoNotifyContacts = emergencyContacts.filter { $0.autoNotify }
        
        print("📱 Notifying \(autoNotifyContacts.count) auto-notify contacts")
        
        for contact in autoNotifyContacts {
            if let location = location {
                shareLocation(with: contact, location: location)
            } else {
                sendSMS(to: contact, message: generateEmergencyMessage(location: nil))
            }
        }
    }
    
    // MARK: - Emergency Contact Validation
    
    /// Validate phone number format
    func validatePhoneNumber(_ number: String) -> Bool {
        let phoneRegex = #"^\+?[1-9]\d{1,14}$"#
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: number.filter { $0.isNumber })
    }
    
    /// Check if device can make phone calls
    @MainActor
    func canMakePhoneCalls() -> Bool {
        guard let url = URL(string: "tel://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // MARK: - Emergency Contact Management
    
    /// Get primary emergency contact
    func getPrimaryContact(from contacts: [EmergencyContact]) -> EmergencyContact? {
        contacts.first { $0.isPrimary }
    }
    
    /// Sort contacts by priority
    func sortByPriority(_ contacts: [EmergencyContact]) -> [EmergencyContact] {
        contacts.sorted { $0.priority < $1.priority }
    }
}
