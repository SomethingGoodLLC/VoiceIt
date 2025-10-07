import SwiftUI

/// View displaying the change history timeline for evidence
struct ChangeHistoryView: View {
    // MARK: - Properties
    
    let changeHistory: [ChangeHistory]
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title3)
                    .foregroundStyle(Color.voiceitPurple)
                
                Text("Change History")
                    .font(.headline)
                
                Spacer()
                
                Text("\(changeHistory.count) changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 8)
            
            // Timeline
            if changeHistory.isEmpty {
                Text("No changes recorded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sortedHistory) { change in
                        changeRow(for: change)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Sorted History
    
    private var sortedHistory: [ChangeHistory] {
        changeHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    // MARK: - Change Row
    
    @ViewBuilder
    private func changeRow(for change: ChangeHistory) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot and line
            VStack(spacing: 0) {
                Image(systemName: change.changeType.icon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(colorForChangeType(change.changeType))
                    )
                
                if change.id != sortedHistory.last?.id {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            // Change details
            VStack(alignment: .leading, spacing: 6) {
                // Change type and timestamp
                HStack {
                    Text(change.changeType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(change.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                // Description
                if let description = change.changeDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Show previous and new content for modifications
                if change.changeType == .contentModified || change.changeType == .noteModified {
                    VStack(alignment: .leading, spacing: 8) {
                        if let previous = change.previousContent, !previous.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Previous:")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Text(previous)
                                    .font(.caption)
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
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(change.previousContent != nil ? "Updated to:" : "Content:")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            Text(change.newContent)
                                .font(.caption)
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
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func colorForChangeType(_ type: ChangeType) -> Color {
        switch type.color {
        case "green":
            return .green
        case "blue":
            return .blue
        case "purple":
            return Color.voiceitPurple
        case "orange":
            return .orange
        case "red":
            return .red
        case "gray":
            return .gray
        default:
            return Color.voiceitPurple
        }
    }
}

#Preview {
    ScrollView {
        ChangeHistoryView(changeHistory: [
            ChangeHistory(
                changeType: .created,
                newContent: "Initial text entry",
                fieldChanged: "bodyText",
                changeDescription: "Initial creation"
            ),
            ChangeHistory(
                changeType: .contentModified,
                previousContent: "Initial text entry",
                newContent: "Updated text entry with more details",
                fieldChanged: "bodyText",
                changeDescription: "Content updated"
            ),
            ChangeHistory(
                changeType: .noteAdded,
                newContent: "This is an important note",
                fieldChanged: "notes"
            )
        ])
        .padding()
    }
}
