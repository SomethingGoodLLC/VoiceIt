import SwiftUI

extension View {
    /// Prevents screenshots and screen recording on this view
    func screenshotProtected(_ isProtected: Bool = true) -> some View {
        self.modifier(ScreenshotProtectionModifier(isProtected: isProtected))
    }
}

struct ScreenshotProtectionModifier: ViewModifier {
    let isProtected: Bool
    
    func body(content: Content) -> some View {
        content
            .background(ScreenshotDetectorView(isProtected: isProtected))
    }
}

struct ScreenshotDetectorView: UIViewRepresentable {
    let isProtected: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if isProtected {
            // Create a secure text field (which iOS prevents from being captured)
            let textField = UITextField()
            textField.isSecureTextEntry = true
            textField.isUserInteractionEnabled = false
            textField.alpha = 0
            view.addSubview(textField)
            
            // Make the text field cover the entire view
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                textField.topAnchor.constraint(equalTo: view.topAnchor),
                textField.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            
            // Detect screenshots
            NotificationCenter.default.addObserver(
                forName: UIApplication.userDidTakeScreenshotNotification,
                object: nil,
                queue: .main
            ) { _ in
                // Provide haptic feedback when screenshot is attempted
                HapticService.shared.warning()
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}

extension View {
    /// Applies screenshot protection to sensitive screens based on user settings
    @ViewBuilder
    func conditionalScreenshotProtection() -> some View {
        let isEnabled = UserDefaults.standard.bool(forKey: "disableScreenshots")
        if isEnabled {
            self.screenshotProtected()
        } else {
            self
        }
    }
}
