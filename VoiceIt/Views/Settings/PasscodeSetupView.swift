import SwiftUI

/// View for setting up or changing the app passcode
struct PasscodeSetupView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authenticationService) private var authService
    
    // MARK: - State
    
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var errorMessage: String?
    @State private var isProcessing = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case newPasscode
        case confirmPasscode
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("New Passcode", text: $newPasscode)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .newPasscode)
                    
                    SecureField("Confirm Passcode", text: $confirmPasscode)
                        .keyboardType(.numberPad)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPasscode)
                    
                } header: {
                    Text("Set Passcode")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Must be at least 6 digits")
                        Text("• Must contain only numbers")
                        
                        if newPasscode.count > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: newPasscode.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(newPasscode.count >= 6 ? .green : .red)
                                Text("\(newPasscode.count) digits")
                            }
                            .font(.caption)
                        }
                        
                        if newPasscode.count > 0 && !newPasscode.allSatisfy({ $0.isNumber }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text("Must contain only numbers")
                            }
                            .font(.caption)
                        }
                    }
                    .font(.caption)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        savePasscode()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Set Passcode")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValid || isProcessing)
                }
            }
            .navigationTitle("Set Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                focusedField = .newPasscode
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        newPasscode.count >= 6 &&
        newPasscode == confirmPasscode &&
        newPasscode.allSatisfy { $0.isNumber }
    }
    
    // MARK: - Save Passcode
    
    private func savePasscode() {
        guard isValid else { return }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            try authService.setPasscode(newPasscode)
            HapticService.shared.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticService.shared.error()
        }
        
        isProcessing = false
    }
}

#Preview {
    PasscodeSetupView()
        .environment(\.authenticationService, AuthenticationService())
}
