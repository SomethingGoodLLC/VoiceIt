import SwiftUI

/// View for selecting alternate app icons
struct AppIconPickerView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    @Bindable var service: AppIconService
    
    // MARK: - State
    
    @State private var selectedIcon: AppIcon
    @State private var isChanging = false
    @State private var errorMessage: String?
    
    // MARK: - Initialization
    
    init(service: AppIconService) {
        self.service = service
        _selectedIcon = State(initialValue: service.currentIcon)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(AppIcon.allCases), id: \.self) { icon in
                        iconRow(for: icon)
                    }
                    
                } header: {
                    Text("Choose App Icon")
                } footer: {
                    Text("Change your app icon to disguise the app as a calculator, weather app, notes app, or wellness journal for added privacy.")
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await changeIcon()
                        }
                    } label: {
                        if isChanging {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Apply Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(selectedIcon == service.currentIcon || isChanging)
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Change Icon
    
    @MainActor
    private func changeIcon() async {
        isChanging = true
        errorMessage = nil
        
        do {
            try await service.changeIcon(to: selectedIcon)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticService.shared.error()
        }
        
        isChanging = false
    }
    
    // MARK: - Icon Row
    
    @ViewBuilder
    private func iconRow(for icon: AppIcon) -> some View {
        Button {
            selectedIcon = icon
        } label: {
            HStack(spacing: 16) {
                // Icon preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(icon == AppIcon.default ? Color.voiceitPurple : iconColor(for: icon))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon.previewIcon)
                        .font(.title)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(icon.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(icon.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if selectedIcon == icon {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.voiceitPurple)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Icon Colors
    
    private func iconColor(for icon: AppIcon) -> Color {
        switch icon {
        case .default:
            return Color.voiceitPurple
        case .calculator:
            return .orange
        case .weather:
            return .blue
        case .notes:
            return .yellow
        case .wellness:
            return .pink
        }
    }
}

#Preview {
    AppIconPickerView(service: AppIconService())
}
