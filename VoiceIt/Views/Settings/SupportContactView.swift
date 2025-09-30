import SwiftUI

/// Support and safety resources contact view
struct SupportContactView: View {
    var body: some View {
        List {
            // Emergency Resources Section
            Section {
                EmergencyResourceRow(
                    name: "National Domestic Violence Hotline",
                    phone: "1-800-799-7233",
                    description: "24/7 support for domestic violence survivors",
                    icon: "phone.fill",
                    color: .red
                )
                
                EmergencyResourceRow(
                    name: "Crisis Text Line",
                    phone: "741741",
                    description: "Text HOME to 741741 for 24/7 crisis support",
                    icon: "message.fill",
                    color: .orange
                )
                
                EmergencyResourceRow(
                    name: "National Sexual Assault Hotline",
                    phone: "1-800-656-4673",
                    description: "24/7 confidential support from RAINN",
                    icon: "shield.fill",
                    color: .purple
                )
                
                EmergencyResourceRow(
                    name: "National Suicide Prevention Lifeline",
                    phone: "988",
                    description: "24/7 suicide prevention and mental health crisis support",
                    icon: "heart.fill",
                    color: .pink
                )
                
            } header: {
                Text("Emergency Resources")
            } footer: {
                Text("These are 24/7 hotlines staffed by trained professionals. All calls are confidential.")
            }
            
            // Safety Planning Section
            Section {
                SafetyResourceRow(
                    title: "Safety Planning",
                    description: "Create a personalized safety plan with step-by-step guidance",
                    icon: "list.clipboard.fill"
                )
                
                SafetyResourceRow(
                    title: "Local Shelters",
                    description: "Find safe housing and shelter resources near you",
                    icon: "house.fill"
                )
                
                SafetyResourceRow(
                    title: "Legal Resources",
                    description: "Connect with legal aid and learn about protective orders",
                    icon: "scale.3d"
                )
                
                SafetyResourceRow(
                    title: "Counseling Services",
                    description: "Find free or low-cost counseling and therapy options",
                    icon: "person.2.fill"
                )
                
            } header: {
                Text("Additional Resources")
            }
            
            // App Support Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("App Support", systemImage: "questionmark.circle.fill")
                        .font(.headline)
                    
                    Text("For technical issues or questions about using Voice It, please contact us:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        // TODO: Open email client
                        if let url = URL(string: "mailto:support@voiceit.app") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("support@voiceit.app", systemImage: "envelope.fill")
                    }
                }
                
            } header: {
                Text("Technical Support")
            } footer: {
                Text("We're committed to helping you use Voice It safely and effectively.")
            }
            
            // Privacy Notice Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Privacy Notice", systemImage: "lock.shield.fill")
                        .font(.headline)
                    
                    Text("Your privacy is our top priority. All data in Voice It stays on your device. We never collect, transmit, or store your evidence on external servers.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text("When you contact support, only share information you're comfortable sharing. We'll never ask for your evidence or sensitive personal details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Support & Resources")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Emergency Resource Row

struct EmergencyResourceRow: View {
    let name: String
    let phone: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Button {
                    callPhone(phone)
                } label: {
                    Label("Call", systemImage: "phone.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(color)
                
                if phone.count <= 6 {
                    Button {
                        // Text message
                        openSMS(phone)
                    } label: {
                        Label("Text", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(color)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func callPhone(_ number: String) {
        let cleaned = number.replacingOccurrences(of: "-", with: "")
        if let url = URL(string: "tel://\(cleaned)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSMS(_ number: String) {
        if let url = URL(string: "sms://\(number)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Safety Resource Row

struct SafetyResourceRow: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.voiceitPurple)
                .font(.title3)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SupportContactView()
    }
}
