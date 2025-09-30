import SwiftUI

/// Terms of service view
struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last Updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                termsSection(
                    title: "Acceptance of Terms",
                    content: """
                    By using Voice It, you agree to these Terms of Service. If you do not agree to these terms, please do not use the app.
                    """
                )
                
                termsSection(
                    title: "Purpose of the App",
                    content: """
                    Voice It is designed to help individuals document evidence in sensitive situations. The app provides:
                    • Secure, encrypted evidence storage
                    • Privacy-first documentation tools
                    • Emergency safety features
                    • Export capabilities for legal purposes
                    """
                )
                
                termsSection(
                    title: "User Responsibilities",
                    content: """
                    You are responsible for:
                    • Maintaining the security of your device and passcode
                    • The accuracy of evidence you document
                    • Compliance with local laws regarding evidence collection
                    • Backing up important data
                    • Using the app ethically and legally
                    """
                )
                
                termsSection(
                    title: "Emergency Features",
                    content: """
                    The panic button and emergency contact features are provided as-is. While we strive for reliability:
                    • We cannot guarantee emergency services will be reached
                    • Network connectivity is required for SMS and calls
                    • You should have alternative safety plans
                    • Test emergency features in safe conditions
                    """
                )
                
                termsSection(
                    title: "Legal Disclaimer",
                    content: """
                    • This app is not a substitute for legal advice
                    • Evidence documentation does not guarantee legal admissibility
                    • Consult with legal professionals about your specific situation
                    • Laws regarding evidence vary by jurisdiction
                    """
                )
                
                termsSection(
                    title: "No Warranties",
                    content: """
                    The app is provided "as is" without warranties of any kind. We do not warrant that:
                    • The app will be error-free or uninterrupted
                    • Data will never be lost (always maintain backups)
                    • The app will meet all your requirements
                    """
                )
                
                termsSection(
                    title: "Limitation of Liability",
                    content: """
                    To the maximum extent permitted by law, we are not liable for:
                    • Loss of data (maintain backups)
                    • Inability to access the app
                    • Any indirect or consequential damages
                    • Issues related to device compatibility
                    """
                )
                
                termsSection(
                    title: "Privacy Commitment",
                    content: """
                    We are committed to your privacy:
                    • No data collection or analytics
                    • All data stays on your device
                    • No third-party access to your data
                    • See our Privacy Policy for details
                    """
                )
                
                termsSection(
                    title: "Changes to Terms",
                    content: """
                    We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the updated terms.
                    """
                )
                
                termsSection(
                    title: "Contact",
                    content: """
                    For questions about these terms, please contact support through the app.
                    """
                )
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Safety Matters")
                        .font(.headline)
                    
                    Text("If you're in immediate danger, call emergency services (911 in the US). This app is a tool to help you, but your immediate safety is the priority.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func termsSection(title: String, content: String) -> some View {
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
        TermsOfServiceView()
    }
}
