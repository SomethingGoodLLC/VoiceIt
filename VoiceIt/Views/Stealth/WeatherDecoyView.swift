import SwiftUI

/// Decoy weather screen for stealth mode
struct WeatherDecoyView: View {
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    @State private var currentTemp = 72
    @State private var conditions = "Partly Cloudy"
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Search bar (hidden passcode entry)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    
                    TextField("Search city...", text: $searchText)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .onChange(of: searchText) { _, newValue in
                            checkForUnlock(newValue)
                        }
                }
                .padding(10)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 40) // Push down from status bar
                
                // Toolbar with refresh button
                HStack {
                    Spacer()
                    Button {
                        // Decoy refresh action
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    // Long-press to trigger biometric unlock
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onEnded { _ in
                                triggerBiometricUnlock()
                            }
                    )
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Location
                Text("San Francisco, CA")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // Weather icon - long press to unlock
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
                    .padding()
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onEnded { _ in
                                triggerBiometricUnlock()
                            }
                    )
                
                // Temperature
                Text("\(currentTemp)°")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(.white)
                
                // Conditions
                Text(conditions)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                // Weekly forecast
                VStack(spacing: 16) {
                    ForEach(weeklyForecast, id: \.day) { forecast in
                        HStack {
                            Text(forecast.day)
                                .frame(width: 60, alignment: .leading)
                                .foregroundColor(.white)
                            
                            Image(systemName: forecast.icon)
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 30)
                            
                            Spacer()
                            
                            Text("\(forecast.low)°")
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("\(forecast.high)°")
                                .foregroundColor(.white)
                                .frame(width: 40, alignment: .trailing)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.vertical, 20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(15)
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    private var weeklyForecast: [DayForecast] {
        [
            DayForecast(day: "Mon", icon: "sun.max.fill", low: 65, high: 78),
            DayForecast(day: "Tue", icon: "cloud.sun.fill", low: 63, high: 75),
            DayForecast(day: "Wed", icon: "cloud.fill", low: 60, high: 72),
            DayForecast(day: "Thu", icon: "cloud.rain.fill", low: 58, high: 68),
            DayForecast(day: "Fri", icon: "sun.max.fill", low: 62, high: 76)
        ]
    }
    
    private func checkForUnlock(_ text: String) {
        // Check if text matches passcode
        Task {
            do {
                if try authService.verifyPasscode(text) {
                    await MainActor.run {
                        stealthService.isStealthActive = false
                        // Clear text for next time
                        searchText = ""
                    }
                }
            } catch {
                // Ignore errors
            }
        }
    }
    
    private func triggerBiometricUnlock() {
        Task {
            do {
                // Try biometrics ONLY first (no passcode fallback)
                try await authService.authenticateWithBiometrics(reason: "Unlock with \(authService.biometricType.displayName)")
                // If successful, deactivate stealth mode
                await MainActor.run {
                    stealthService.isStealthActive = false
                }
            } catch {
                // If biometrics fail, silently stay in stealth mode
                print("Biometric unlock failed: \(error.localizedDescription)")
            }
        }
    }
}

struct DayForecast {
    let day: String
    let icon: String
    let low: Int
    let high: Int
}

#Preview {
    WeatherDecoyView()
}
