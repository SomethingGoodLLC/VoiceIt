import SwiftUI

/// Decoy weather screen for stealth mode
struct WeatherDecoyView: View {
    @State private var currentTemp = 72
    @State private var conditions = "Partly Cloudy"
    
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
                Spacer()
                
                // Location
                Text("San Francisco, CA")
                    .font(.title2)
                    .foregroundColor(.white)
                
                // Weather icon
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
                    .padding()
                
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
                
                // Hidden unlock instruction
                Text("Swipe down from top to unlock")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.top, 8)
                
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
