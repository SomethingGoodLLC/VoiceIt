import SwiftUI

struct SponsorFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var roadmapStore: RoadmapStore
    let feature: RoadmapFeature
    
    @State private var yourName = ""
    @State private var yourEmail = ""
    @State private var yourPhone = ""
    @State private var sponsorName = ""
    @State private var sponsorEmail = ""
    @State private var sponsorPhone = ""
    @State private var relationship = ""
    @State private var comments = ""
    
    @State private var showAlert = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Know someone who might sponsor **\(feature.title)**?")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("We're looking for organizations or individuals who care about supporting survivors. Share their details below and we'll reach out to discuss sponsorship opportunities.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                
                Section("Your Contact Information") {
                    TextField("Your Name", text: $yourName)
                        .textContentType(.name)
                    
                    TextField("Your Email", text: $yourEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Your Phone (Optional)", text: $yourPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Potential Sponsor Information") {
                    TextField("Sponsor's Name or Organization", text: $sponsorName)
                        .textContentType(.name)
                    
                    TextField("Sponsor's Email (if known)", text: $sponsorEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Sponsor's Phone (Optional)", text: $sponsorPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section("Your Connection") {
                    TextField("How do you know them? (e.g., colleague, friend, family)", text: $relationship)
                }
                
                Section("Additional Comments") {
                    TextEditor(text: $comments)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: submitForm) {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Submitting...")
                            }
                            .frame(maxWidth: .infinity)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)
                        } else if yourName.isEmpty || yourEmail.isEmpty || sponsorName.isEmpty {
                            Text("Submit Referral")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Submit Referral")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(yourName.isEmpty || yourEmail.isEmpty || sponsorName.isEmpty || isSubmitting)
                    .listRowBackground(
                        (yourName.isEmpty || yourEmail.isEmpty || sponsorName.isEmpty || isSubmitting) 
                            ? Color(.secondarySystemGroupedBackground) 
                            : Color.voiceitPurple
                    )
                }
            }
            .navigationTitle("Refer a Sponsor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Thank You!", isPresented: $showAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("We've received your referral and will reach out to the potential sponsor. Thank you for helping us build this feature!")
            }
            .alert("Submission Error", isPresented: $showErrorAlert) {
                Button("Retry") {
                    submitForm()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unable to submit referral. Please check your internet connection and try again.")
            }
        }
    }
    
    private func submitForm() {
        Task {
            await submitFormAsync()
        }
    }
    
    @MainActor
    private func submitFormAsync() async {
        // Prevent double submission
        guard !isSubmitting else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // Submit to backend
            let response = try await APIService.shared.submitSponsorReferral(
                featureId: feature.id,
                yourName: yourName,
                yourEmail: yourEmail,
                yourPhone: yourPhone.isEmpty ? nil : yourPhone,
                sponsorName: sponsorName,
                sponsorEmail: sponsorEmail.isEmpty ? nil : sponsorEmail,
                sponsorPhone: sponsorPhone.isEmpty ? nil : sponsorPhone,
                relationship: relationship.isEmpty ? nil : relationship,
                comments: comments.isEmpty ? nil : comments,
                anonUserId: roadmapStore.anonUserId
            )
            
            // Track local analytics
            roadmapStore.recordSponsorLead(featureId: feature.id)
            
            print("✅ Sponsor Referral Submitted Successfully")
            print("   Referral ID: \(response.referralId ?? "none")")
            print("   Your Info: \(yourName), \(yourEmail)")
            print("   Sponsor Info: \(sponsorName), \(sponsorEmail.isEmpty ? "no email" : sponsorEmail)")
            print("   Connection: \(relationship)")
            
            isSubmitting = false
            showAlert = true
            
        } catch let error as APIError {
            // Handle API-specific errors
            isSubmitting = false
            errorMessage = error.errorDescription
            showErrorAlert = true
            
            print("❌ API Error submitting referral: \(error.errorDescription ?? "unknown")")
            
        } catch {
            // Handle general network errors
            isSubmitting = false
            errorMessage = "Network error: \(error.localizedDescription)"
            showErrorAlert = true
            
            print("❌ Network Error submitting referral: \(error.localizedDescription)")
        }
    }
}

#Preview {
    SponsorFormView(
        feature: RoadmapFeature.initialFeatures[0]
    )
    .environmentObject(RoadmapStore())
}
