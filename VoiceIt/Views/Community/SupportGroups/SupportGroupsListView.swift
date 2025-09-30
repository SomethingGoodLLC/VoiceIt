import SwiftUI

/// List of anonymous support groups
@available(iOS 18, *)
struct SupportGroupsListView: View {
    @Environment(\.communityService) private var communityService
    @State private var selectedCategory: SupportGroupCategory?
    @State private var selectedGroup: SupportGroup?
    
    var filteredGroups: [SupportGroup] {
        if let category = selectedCategory {
            return communityService.supportGroups.filter { $0.category == category }
        }
        return communityService.supportGroups
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Privacy Notice
                privacyNotice
                
                // Category Filter
                categoryFilter
                
                // Support Groups List
                VStack(spacing: 16) {
                    ForEach(filteredGroups, id: \.id) { group in
                        SupportGroupCard(group: group)
                            .onTapGesture {
                                selectedGroup = group
                            }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Support Groups")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedGroup) { group in
            NavigationStack {
                SupportGroupDetailView(group: group)
            }
        }
    }
    
    private var privacyNotice: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your identity is never shared")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("All discussions are anonymous and moderated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "circle.grid.3x3.fill",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(SupportGroupCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

/// Support group card component
struct SupportGroupCard: View {
    let group: SupportGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: group.category.icon)
                    .font(.title2)
                    .foregroundStyle(Color.voiceitPurple)
                    .frame(width: 50, height: 50)
                    .background(Color.voiceitPurple.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.topic)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Label("\(group.memberCount) members", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if group.privacyLevel == .anonymous {
                    Image(systemName: "eye.slash.fill")
                        .foregroundStyle(.green)
                }
            }
            
            // Description
            Text(group.groupDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            Divider()
            
            // Footer
            HStack {
                Label(group.moderator, systemImage: "checkmark.shield.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if group.isAcceptingMembers {
                    Text("Open")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                } else {
                    Text("Full")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

/// Category chip component
struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.voiceitPurple : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    NavigationStack {
        SupportGroupsListView()
            .environment(\.communityService, CommunityService())
    }
}
