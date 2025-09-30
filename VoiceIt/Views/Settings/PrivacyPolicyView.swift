import SwiftUI

/// Privacy policy view
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                privacySection(
                    title: "Your Privacy is Our Priority",
                    content: """
                    Voice It is designed with privacy-first principles. We believe that sensitive evidence documentation requires the highest level of data protection.
                    """
                )
                
                privacySection(
                    title: "Data Storage",
                    content: """
                    • All data stays on your device - we never transmit your evidence to external servers
                    • All evidence is encrypted using AES-256-GCM encryption
                    • Encryption keys are stored securely in iOS Keychain
                    • Only you have access to your data
                    """
                )
                
                privacySection(
                    title: "Location Data",
                    content: """
                    • Location tracking is optional and disabled by default
                    • Location data is only captured when you create evidence with location enabled
                    • GPS coordinates are stored encrypted on your device
                    • We never share or transmit location data
                    """
                )
                
                privacySection(
                    title: "No Analytics or Tracking",
                    content: """
                    • We do not collect analytics data
                    • We do not track your usage
                    • We do not use third-party tracking services
                    • We do not have access to your device data
                    """
                )
                
                privacySection(
                    title: "Biometric Authentication",
                    content: """
                    • Face ID/Touch ID data never leaves your device
                    • We use iOS LocalAuthentication framework
                    • Biometric data is managed by iOS, not our app
                    • You can disable biometrics at any time
                    """
                )
                
                privacySection(
                    title: "Exports",
                    content: """
                    • You control when and what to export
                    • Exported files can be password-protected
                    • Exports are created locally on your device
                    • You choose where to share exported files
                    """
                )
                
                privacySection(
                    title: "Data Deletion",
                    content: """
                    • You can delete all data at any time from Settings
                    • Deleted files are securely overwritten before removal
                    • Deletion is immediate and permanent
                    • No backup copies are retained
                    """
                )
                
                privacySection(
                    title: "Your Rights",
                    content: """
                    • You own all your data
                    • You can export your data at any time
                    • You can delete your data at any time
                    • No one else has access to your evidence
                    """
                )
                
                Divider()
                
                Text("If you have questions about privacy, please contact support.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
