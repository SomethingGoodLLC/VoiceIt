import Foundation
import UIKit
import SwiftData
import MessageUI

/// Service for handling emergency features (panic button, 911, emergency contacts)
final class EmergencyService: Sendable {
    // MARK: - Properties
    
    private let emergencyNumber = "911" // US emergency number
    
    // MARK: - Emergency Calling
    
    /// Initiate emergency call to 911
    func call911() {
        guard let url = URL(string: "tel://\(emergencyNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    /// Call emergency contact
    func callContact(_ contact: EmergencyContact) {
        let phoneNumber = contact.phoneNumber.filter { $0.isNumber }
        guard let url = URL(string: "tel://\(phoneNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - SMS/Message
    
    /// Send SMS to emergency contact
    func sendSMS(to contact: EmergencyContact, message: String) {
        let phoneNumber = contact.phoneNumber.filter { $0.isNumber }
        guard let url = URL(string: "sms:\(phoneNumber)&body=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
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
        // Call 911 first
        call911()
        
        // Notify auto-notify contacts
        let autoNotifyContacts = emergencyContacts.filter { $0.autoNotify }
        
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
