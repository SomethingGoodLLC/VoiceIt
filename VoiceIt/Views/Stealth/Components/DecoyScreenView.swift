import SwiftUI

/// Renders the selected decoy screen for stealth lock or transient privacy shield.
struct DecoyScreenView: View {
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    let decoyType: DecoyScreenType
    
    var body: some View {
        switch decoyType {
        case .calculator:
            CalculatorDecoyView()
                .environment(\.authenticationService, authService)
                .environment(\.stealthModeService, stealthService)
        case .weather:
            WeatherDecoyView()
                .environment(\.authenticationService, authService)
                .environment(\.stealthModeService, stealthService)
        case .notes:
            NotesDecoyView()
                .environment(\.authenticationService, authService)
                .environment(\.stealthModeService, stealthService)
        case .crossStitch:
            CrossStitchDecoyView()
                .environment(\.authenticationService, authService)
                .environment(\.stealthModeService, stealthService)
        case .voiceChanger:
            VoiceChangerDecoyView()
                .environment(\.authenticationService, authService)
                .environment(\.stealthModeService, stealthService)
        }
    }
}

#Preview {
    DecoyScreenView(decoyType: .calculator)
        .environment(\.stealthModeService, StealthModeService())
}
