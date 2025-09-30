import SwiftUI

/// Accessible settings row with VoiceOver support
struct AccessibleSettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let value: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        value: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.action = action
    }
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.voiceitPurple)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let value {
                    Text(value)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(action != nil ? .isButton : .isStaticText)
    }
    
    private var accessibilityLabel: String {
        var label = title
        if let value = value {
            label += ", \(value)"
        }
        if let subtitle = subtitle {
            label += ", \(subtitle)"
        }
        return label
    }
    
    private var accessibilityHint: String {
        guard action != nil else { return "" }
        return "Double tap to open"
    }
}

// MARK: - Toggle Row

struct AccessibleToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let onChange: ((Bool) -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.onChange = onChange
    }
    
    var body: some View {
        Toggle(isOn: Binding(
            get: { isOn },
            set: { newValue in
                isOn = newValue
                onChange?(newValue)
                
                // Announce change to VoiceOver
                AccessibilityAnnouncer.shared.announce(
                    "\(title) \(newValue ? "enabled" : "disabled")"
                )
            }
        )) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.voiceitPurple)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + (subtitle != nil ? ", \(subtitle!)" : ""))
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
    }
}

// MARK: - Picker Row

struct AccessiblePickerRow<T: Hashable>: View {
    let icon: String
    let title: String
    let options: [T]
    let optionLabel: (T) -> String
    @Binding var selection: T
    let onChange: ((T) -> Void)?
    
    init(
        icon: String,
        title: String,
        options: [T],
        selection: Binding<T>,
        optionLabel: @escaping (T) -> String,
        onChange: ((T) -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.options = options
        self._selection = selection
        self.optionLabel = optionLabel
        self.onChange = onChange
    }
    
    var body: some View {
        Picker(selection: Binding(
            get: { selection },
            set: { newValue in
                selection = newValue
                onChange?(newValue)
                
                // Announce change to VoiceOver
                AccessibilityAnnouncer.shared.announce(
                    "\(title) set to \(optionLabel(newValue))"
                )
            }
        )) {
            ForEach(options, id: \.self) { option in
                Text(optionLabel(option))
                    .tag(option)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.voiceitPurple)
                    .frame(width: 30)
                    .accessibilityHidden(true)
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .accessibilityLabel(title)
        .accessibilityValue(optionLabel(selection))
        .accessibilityHint("Double tap to change")
    }
}

#Preview {
    List {
        AccessibleSettingsRow(
            icon: "lock.fill",
            title: "Security",
            subtitle: "Protect your data",
            value: "Enabled",
            action: {}
        )
        
        AccessibleToggleRow(
            icon: "faceid",
            title: "Face ID",
            subtitle: "Use biometric authentication",
            isOn: .constant(true)
        )
    }
}
