import SwiftUI

/// Decoy calculator screen for stealth mode
struct CalculatorDecoyView: View {
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    @State private var display = "0"
    @State private var currentOperation: Operation?
    @State private var previousValue: Double = 0
    @State private var shouldResetDisplay = false
    
    private let buttons: [[CalculatorButton]] = [
        [.clear, .plusMinus, .percent, .divide],
        [.seven, .eight, .nine, .multiply],
        [.four, .five, .six, .subtract],
        [.one, .two, .three, .add],
        [.zero, .decimal, .equals]
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
                // Display
                Text(display)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 24)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    // Keep gesture on display too
                    .onLongPressGesture(minimumDuration: 1.0) {
                        triggerBiometricUnlock()
                    }
                
                // Buttons
                ForEach(buttons.indices, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(buttons[row], id: \.self) { button in
                            CalculatorButtonView(button: button) {
                                handleButtonTap(button)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerBiometricUnlock)) { _ in
            triggerBiometricUnlock()
        }
    }
    
    private func triggerBiometricUnlock() {
        Task {
            do {
                // Try biometrics ONLY first (no passcode fallback)
                try await authService.authenticateWithBiometrics(reason: "Unlock with \(authService.biometricType.displayName)")
                // If successful, deactivate stealth mode
                await MainActor.run {
                    stealthService.completeUnlock()
                }
            } catch {
                // If biometrics fail, silently stay in stealth mode
                // User can still use passcode method via typing it
                print("Biometric unlock failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleButtonTap(_ button: CalculatorButton) {
        switch button {
        case .clear:
            display = "0"
            currentOperation = nil
            previousValue = 0
            shouldResetDisplay = false
            
        case .plusMinus:
            if let value = Double(display) {
                display = String(value * -1)
            }
            
        case .percent:
            if let value = Double(display) {
                display = String(value / 100)
            }
            
        case .decimal:
            if !display.contains(".") {
                display += "."
            }
            
        case .equals:
            // Check for unlock code before performing operation
            checkForUnlock()
            
            performOperation()
            currentOperation = nil
            shouldResetDisplay = true
            
        case .add, .subtract, .multiply, .divide:
            if let operation = Operation(from: button) {
                if currentOperation != nil {
                    performOperation()
                }
                previousValue = Double(display) ?? 0
                currentOperation = operation
                shouldResetDisplay = true
            }
            
        default:
            if shouldResetDisplay {
                display = button.title
                shouldResetDisplay = false
            } else {
                if display == "0" {
                    display = button.title
                } else {
                    display += button.title
                }
            }
        }
    }
    
    private func checkForUnlock() {
        // Try to verify the current display as a passcode
        Task {
            do {
                if try authService.verifyPasscode(display) {
                    await MainActor.run {
                        stealthService.completeUnlock()
                    }
                }
            } catch {
                // Ignore errors, just don't unlock
                print("Unlock failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func performOperation() {
        guard let operation = currentOperation,
              let currentValue = Double(display) else { return }
        
        let result: Double
        switch operation {
        case .add:
            result = previousValue + currentValue
        case .subtract:
            result = previousValue - currentValue
        case .multiply:
            result = previousValue * currentValue
        case .divide:
            result = currentValue != 0 ? previousValue / currentValue : 0
        }
        
        display = formatResult(result)
    }
    
    private func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.8f", value).trimmingCharacters(in: CharacterSet(charactersIn: "0")).trimmingCharacters(in: CharacterSet(charactersIn: "."))
        }
    }
    
    enum Operation {
        case add, subtract, multiply, divide
        
        init?(from button: CalculatorButton) {
            switch button {
            case .add: self = .add
            case .subtract: self = .subtract
            case .multiply: self = .multiply
            case .divide: self = .divide
            default: return nil
            }
        }
    }
}

// MARK: - Calculator Button View

struct CalculatorButtonView: View {
    let button: CalculatorButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.title)
                .font(.system(size: button == .zero ? 32 : 36, weight: .medium))
                .foregroundColor(button.foregroundColor)
                .frame(
                    width: button == .zero ? 168 : 76,
                    height: 76
                )
                .background(button.backgroundColor)
                .cornerRadius(38)
        }
        // Add gesture directly to button to capture touches
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 1.0)
                .onEnded { _ in
                    // Only trigger for equals button, or maybe all buttons?
                    // User specifically asked about equals button
                    if button == .equals {
                        NotificationCenter.default.post(name: .triggerBiometricUnlock, object: nil)
                    }
                }
        )
    }
}

// MARK: - Calculator Button Model

enum CalculatorButton: Hashable {
    case zero, one, two, three, four, five, six, seven, eight, nine
    case decimal, equals
    case add, subtract, multiply, divide
    case clear, plusMinus, percent
    
    var title: String {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .decimal: return "."
        case .equals: return "="
        case .add: return "+"
        case .subtract: return "−"
        case .multiply: return "×"
        case .divide: return "÷"
        case .clear: return "AC"
        case .plusMinus: return "±"
        case .percent: return "%"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .add, .subtract, .multiply, .divide, .equals:
            return Color.orange
        case .clear, .plusMinus, .percent:
            return Color(white: 0.4)
        default:
            return Color(white: 0.2)
        }
    }
    
    var foregroundColor: Color {
        return .white
    }
}

extension Notification.Name {
    static let triggerBiometricUnlock = Notification.Name("triggerBiometricUnlock")
}

#Preview {
    CalculatorDecoyView()
}
