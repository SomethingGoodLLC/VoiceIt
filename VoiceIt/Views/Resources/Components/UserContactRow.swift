import SwiftUI

/// Row displaying a user's emergency contact
struct UserContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with initials
            ZStack {
                Circle()
                    .fill(contact.isPrimary ? Color.voiceitPurple : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(initials)
                    .font(.headline)
                    .foregroundStyle(contact.isPrimary ? .white : .primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.name)
                        .font(.headline)
                    
                    if contact.isPrimary {
                        Text("PRIMARY")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.voiceitPurple)
                            .clipShape(Capsule())
                    }
                }
                
                Text(contact.relationship)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(contact.phoneNumber)
                    .font(.subheadline)
                    .foregroundColor(Color.voiceitPurple)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                callContact()
            } label: {
                Label("Call", systemImage: "phone.fill")
            }
            .tint(.voiceitPurple)
            
            Button {
                messageContact()
            } label: {
                Label("Message", systemImage: "message.fill")
            }
            .tint(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            callContact()
        }
    }
    
    private var initials: String {
        let components = contact.name.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        }
        return String(contact.name.prefix(2)).uppercased()
    }
    
    private func callContact() {
        let cleanNumber = contact.phoneNumber.filter { $0.isNumber }
        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func messageContact() {
        let cleanNumber = contact.phoneNumber.filter { $0.isNumber }
        if let url = URL(string: "sms:\(cleanNumber)") {
            UIApplication.shared.open(url)
        }
    }
}
