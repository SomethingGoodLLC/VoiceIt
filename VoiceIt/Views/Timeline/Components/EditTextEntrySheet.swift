import SwiftUI

/// Sheet for editing text entries while preserving change history
struct EditTextEntrySheet: View {
    // MARK: - Properties
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let textEntry: TextEntry
    
    @State private var editedText: String = ""
    @State private var changeDescription: String = ""
    @State private var hasChanges = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Original content comparison
                if hasChanges {
                    changeComparisonView
                }
                
                // Text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $editedText)
                        .font(.body)
                        .frame(minHeight: 200)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: editedText) { oldValue, newValue in
                            hasChanges = newValue != textEntry.bodyText
                        }
                }
                
                // Optional change description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Change Description (Optional)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Describe what you changed...", text: $changeDescription)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Word count
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if hasChanges {
                        Text("(\(wordCountDifference) words)")
                            .font(.caption)
                            .foregroundStyle(wordCountDifference >= 0 ? .green : .red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Text Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!hasChanges || editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editedText = textEntry.bodyText
            }
        }
    }
    
    // MARK: - Change Comparison View
    
    private var changeComparisonView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Color.voiceitPurple)
                Text("You've made changes")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            // Show preview of changes
            VStack(alignment: .leading, spacing: 8) {
                // Original (abbreviated)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Original:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(textEntry.bodyText.prefix(100) + (textEntry.bodyText.count > 100 ? "..." : ""))
                        .font(.caption)
                        .lineLimit(3)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                
                // New (abbreviated)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Updated:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(editedText.prefix(100) + (editedText.count > 100 ? "..." : ""))
                        .font(.caption)
                        .lineLimit(3)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Computed Properties
    
    private var wordCount: Int {
        editedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }
    
    private var wordCountDifference: Int {
        wordCount - textEntry.wordCount
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        let trimmedText = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedText.isEmpty else { return }
        guard trimmedText != textEntry.bodyText else {
            dismiss()
            return
        }
        
        // Update the text entry with change tracking
        let description = changeDescription.isEmpty ? nil : changeDescription
        textEntry.updateBodyText(trimmedText, description: description)
        
        // Save context
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    EditTextEntrySheet(
        textEntry: TextEntry(
            bodyText: "This is the original text that can be edited.",
            isQuickNote: false
        )
    )
    .modelContainer(for: [TextEntry.self], inMemory: true)
}
