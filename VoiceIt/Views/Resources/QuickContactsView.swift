import SwiftUI
import SwiftData

/// Quick access emergency contacts view for Resources tab
struct QuickContactsView: View {
    // MARK: - Properties
    
    @Query(sort: \EmergencyContact.name)
    private var allContacts: [EmergencyContact]
    
    private var contacts: [EmergencyContact] {
        // Sort by isPrimary first, then by name
        allContacts.sorted { lhs, rhs in
            if lhs.isPrimary != rhs.isPrimary {
                return lhs.isPrimary
            }
            return lhs.name < rhs.name
        }
    }
    
    @State private var showingFullContactsList = false
    
    // MARK: - Body
    
    var body: some View {
        List {
            // National hotlines
            Section {
                NationalHotlineRow(
                    name: "National Domestic Violence Hotline",
                    phone: "1-800-799-7233",
                    description: "24/7 confidential support",
                    icon: "phone.circle.fill",
                    color: .voiceitPurple
                )
                
                NationalHotlineRow(
                    name: "Crisis Text Line",
                    phone: "741741",
                    description: "Text START to 88788",
                    icon: "message.circle.fill",
                    color: .blue,
                    isTextLine: true
                )
                
                NationalHotlineRow(
                    name: "911 Emergency",
                    phone: "911",
                    description: "Immediate danger only",
                    icon: "exclamationmark.triangle.fill",
                    color: .voiceitError
                )
            } header: {
                Text("Emergency Hotlines")
            } footer: {
                Text("These numbers are available 24/7")
                    .font(.caption)
            }
            
            // User's emergency contacts
            if !contacts.isEmpty {
                Section {
                    ForEach(contacts.prefix(5)) { contact in
                        UserContactRow(contact: contact)
                    }
                    
                    if contacts.count > 5 {
                        Button {
                            showingFullContactsList = true
                        } label: {
                            HStack {
                                Text("View All Contacts (\(contacts.count))")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("My Emergency Contacts")
                        Spacer()
                        Button {
                            showingFullContactsList = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.caption)
                        }
                    }
                }
            } else {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("No Emergency Contacts")
                            .font(.headline)
                        
                        Text("Add trusted contacts for quick access")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            showingFullContactsList = true
                        } label: {
                            Text("Add Contacts")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.voiceitPurple)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .listRowBackground(Color.clear)
            }
            
            // Privacy notice
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.title2)
                        .foregroundStyle(Color.voiceitPurple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Privacy Matters")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Location data never leaves your device. All information is stored securely and encrypted.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Emergency Contacts")
        .sheet(isPresented: $showingFullContactsList) {
            NavigationStack {
                EmergencyContactsView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        QuickContactsView()
            .modelContainer(for: [EmergencyContact.self], inMemory: true)
    }
}
