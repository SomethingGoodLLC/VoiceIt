import SwiftUI

/// Decoy cross-stitch pattern viewer for stealth mode
struct CrossStitchDecoyView: View {
    @Environment(\.authenticationService) private var authService
    @Environment(\.stealthModeService) private var stealthService
    
    @State private var searchText = ""
    @State private var selectedPattern: CrossStitchPattern?
    @State private var patterns = [
        CrossStitchPattern(name: "Floral Garden", difficulty: "Intermediate", size: "120x120", image: "leaf.fill", colors: ["Pink", "Green", "Yellow", "White"], stitchCount: 14400),
        CrossStitchPattern(name: "Geometric Sampler", difficulty: "Beginner", size: "80x80", image: "square.grid.3x3.fill", colors: ["Blue", "Red", "White"], stitchCount: 6400),
        CrossStitchPattern(name: "Vintage Alphabet", difficulty: "Advanced", size: "200x150", image: "textformat", colors: ["Navy", "Gold", "Cream", "Brown"], stitchCount: 30000),
        CrossStitchPattern(name: "Mountain Landscape", difficulty: "Advanced", size: "180x120", image: "mountain.2.fill", colors: ["Blue", "White", "Green", "Brown", "Gray"], stitchCount: 21600),
        CrossStitchPattern(name: "Cute Animals", difficulty: "Beginner", size: "60x60", image: "pawprint.fill", colors: ["Brown", "Pink", "Black", "White"], stitchCount: 3600)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredPatterns) { pattern in
                    NavigationLink(value: pattern) {
                        patternRow(pattern)
                    }
                    // Long-press any pattern row to trigger biometric unlock
                    .onLongPressGesture(minimumDuration: 1.5) {
                        triggerBiometricUnlock()
                    }
                }
            }
            .navigationTitle(Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "My Patterns")
            .navigationDestination(for: CrossStitchPattern.self) { pattern in
                PatternDetailView(pattern: pattern, onBiometricUnlock: triggerBiometricUnlock)
            }
            .searchable(text: $searchText, prompt: "Search patterns")
            .onSubmit(of: .search) {
                checkForUnlock(searchText)
            }
            .onChange(of: searchText) { oldValue, newValue in
                checkForUnlock(newValue)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Action for adding new pattern (decoy)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onEnded { _ in
                                triggerBiometricUnlock()
                            }
                    )
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Action for settings (decoy)
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onEnded { _ in
                                triggerBiometricUnlock()
                            }
                    )
                }
            }
        }
    }
    
    private var filteredPatterns: [CrossStitchPattern] {
        if searchText.isEmpty {
            return patterns
        }
        return patterns.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    @ViewBuilder
    private func patternRow(_ pattern: CrossStitchPattern) -> some View {
        HStack(spacing: 16) {
            Image(systemName: pattern.image)
                .font(.title)
                .foregroundStyle(.purple)
                .frame(width: 50, height: 50)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name)
                    .font(.headline)
                
                HStack {
                    Text(pattern.difficulty)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(pattern.size)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func checkForUnlock(_ text: String) {
        guard text.count >= 4 else { return }
        
        do {
            if try authService.verifyPasscode(text) {
                stealthService.isStealthActive = false
                searchText = ""
            }
        } catch {
            print("Passcode check error: \(error.localizedDescription)")
        }
    }
    
    private func triggerBiometricUnlock() {
        Task {
            do {
                try await authService.authenticateWithBiometrics(reason: "Unlock with \(authService.biometricType.displayName)")
                await MainActor.run {
                    stealthService.isStealthActive = false
                }
            } catch {
                print("Biometric unlock failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Pattern Detail View

struct PatternDetailView: View {
    let pattern: CrossStitchPattern
    let onBiometricUnlock: () -> Void
    
    @State private var selectedTab = 0
    @State private var progress: Double = Double.random(in: 0...0.75)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Pattern Preview
                patternPreview
                
                // Pattern Info
                patternInfo
                
                // Color Palette
                colorPalette
                
                // Stitch Grid Preview
                stitchGridPreview
                
                // Progress Section
                progressSection
            }
            .padding()
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Share action (decoy)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .onEnded { _ in
                            onBiometricUnlock()
                        }
                )
            }
        }
        // Long-press anywhere on the detail view to unlock
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1.5) {
            onBiometricUnlock()
        }
    }
    
    private var patternPreview: some View {
        VStack {
            // Large pattern icon with decorative border
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                // Cross-stitch style border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [6, 3]))
                    .foregroundStyle(.purple.opacity(0.5))
                    .frame(width: 200, height: 200)
                
                Image(systemName: pattern.image)
                    .font(.system(size: 80))
                    .foregroundStyle(.purple)
            }
            
            Text(pattern.name)
                .font(.title2.bold())
                .padding(.top, 8)
            
            Text(pattern.difficulty)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var patternInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Details")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "square.grid.2x2")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text(pattern.size)
                        .font(.caption)
                    Text("Size")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Image(systemName: "number")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("\(pattern.stitchCount)")
                        .font(.caption)
                    Text("Stitches")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Image(systemName: "paintpalette")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("\(pattern.colors.count)")
                        .font(.caption)
                    Text("Colors")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thread Colors")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(pattern.colors, id: \.self) { colorName in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(colorForName(colorName))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text(colorName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var stitchGridPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pattern Preview")
                .font(.headline)
            
            // Simulated cross-stitch grid
            VStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<8, id: \.self) { col in
                            ZStack {
                                Rectangle()
                                    .fill(gridCellColor(row: row, col: col))
                                    .frame(width: 36, height: 36)
                                
                                // X stitch pattern
                                if shouldShowStitch(row: row, col: col) {
                                    CrossStitchShape()
                                        .stroke(stitchColor(row: row, col: col), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
            }
            
            ProgressView(value: progress)
                .tint(.purple)
            
            Text("\(Int(Double(pattern.stitchCount) * progress)) of \(pattern.stitchCount) stitches completed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func colorForName(_ name: String) -> Color {
        switch name.lowercased() {
        case "pink": return .pink
        case "green": return .green
        case "yellow": return .yellow
        case "white": return .white
        case "blue": return .blue
        case "red": return .red
        case "navy": return Color(red: 0, green: 0, blue: 0.5)
        case "gold": return Color(red: 1, green: 0.84, blue: 0)
        case "cream": return Color(red: 1, green: 0.99, blue: 0.82)
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        default: return .purple
        }
    }
    
    private func gridCellColor(row: Int, col: Int) -> Color {
        (row + col) % 2 == 0 ? Color.white : Color.gray.opacity(0.1)
    }
    
    private func shouldShowStitch(row: Int, col: Int) -> Bool {
        // Create a pattern based on the pattern type
        let hash = (row * 8 + col + pattern.name.hashValue) % 3
        return hash != 0
    }
    
    private func stitchColor(row: Int, col: Int) -> Color {
        let index = (row + col) % pattern.colors.count
        return colorForName(pattern.colors[index])
    }
}

// MARK: - Cross Stitch Shape

struct CrossStitchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // First diagonal (bottom-left to top-right)
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        // Second diagonal (top-left to bottom-right)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        
        return path
    }
}

// MARK: - Pattern Model

struct CrossStitchPattern: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let difficulty: String
    let size: String
    let image: String
    let colors: [String]
    let stitchCount: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CrossStitchPattern, rhs: CrossStitchPattern) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    CrossStitchDecoyView()
}
