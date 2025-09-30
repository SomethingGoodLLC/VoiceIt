import SwiftUI

/// Decoy notes screen for stealth mode
struct NotesDecoyView: View {
    @State private var notes = [
        Note(title: "Grocery List", date: Date(), preview: "Milk, eggs, bread, cheese..."),
        Note(title: "Meeting Notes", date: Date().addingTimeInterval(-86400), preview: "Discussed project timeline..."),
        Note(title: "Ideas", date: Date().addingTimeInterval(-172800), preview: "New app concept for productivity...")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack {
                    List {
                        ForEach(notes) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(note.title)
                                        .font(.headline)
                                    Spacer()
                                    Text(note.date, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(note.preview)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Hidden unlock instruction
                    Text("Swipe down from top to unlock")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.5))
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Do nothing
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

struct Note: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let preview: String
}

#Preview {
    NotesDecoyView()
}
