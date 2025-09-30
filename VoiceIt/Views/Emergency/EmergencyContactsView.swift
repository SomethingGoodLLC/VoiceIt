import SwiftUI
import SwiftData

/// View for managing emergency contacts
struct EmergencyContactsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EmergencyContact.priority) private var contacts: [EmergencyContact]
    
    @State private var showAddSheet = false
    @State private var editingContact: EmergencyContact?
    @State private var showTestAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if contacts.isEmpty {
                    emptyState
                } else {
                    contactsList
                }
                
                testModeSection
            }
            .navigationTitle("Emergency Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEmergencyContactView()
            }
            .sheet(item: $editingContact) { contact in
                EditEmergencyContactView(contact: contact)
            }
            .alert("Test Mode", isPresented: $showTestAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Send Test Alert") {
                    sendTestAlert()
                }
            } message: {
                Text("This will send a test message to all auto-notify contacts. They will know this is a test.")
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Emergency Contacts")
                .font(.headline)
            
            Text("Add trusted contacts who will be notified in case of emergency")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showAddSheet = true
            } label: {
                Label("Add Contact", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
    
    private var contactsList: some View {
        ForEach(contacts) { contact in
            EmergencyContactRow(contact: contact)
                .contentShape(Rectangle())
                .onTapGesture {
                    editingContact = contact
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        callContact(contact)
                    } label: {
                        Label("Call", systemImage: "phone.fill")
                    }
                    .tint(.green)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteContact(contact)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
        .onMove { from, to in
            var reorderedContacts = contacts
            reorderedContacts.move(fromOffsets: from, toOffset: to)
            
            // Update priorities
            for (index, contact) in reorderedContacts.enumerated() {
                contact.priority = index
            }
        }
    }
    
    private var testModeSection: some View {
        Section {
            Button {
                showTestAlert = true
            } label: {
                Label("Test Emergency Alert", systemImage: "testtube.2")
                    .foregroundColor(.orange)
            }
        } footer: {
            Text("Send a test alert to all auto-notify contacts to verify your setup works correctly.")
                .font(.caption)
        }
    }
    
    // MARK: - Actions
    
    private func callContact(_ contact: EmergencyContact) {
        let phoneNumber = contact.phoneNumber.filter { $0.isNumber }
        guard let url = URL(string: "tel://\(phoneNumber)") else { return }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            contact.lastContacted = Date()
        }
    }
    
    private func deleteContact(_ contact: EmergencyContact) {
        modelContext.delete(contact)
    }
    
    private func sendTestAlert() {
        let testContacts = contacts.filter { $0.autoNotify }
        
        for contact in testContacts {
            let message = "TEST ALERT from Voice It app. This is a test of the emergency notification system. No action needed."
            
            let phoneNumber = contact.phoneNumber.filter { $0.isNumber }
            
            // Encode message for URL
            guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { continue }
            
            // Use correct SMS URL format: sms:phoneNumber&body=message (no ? needed)
            guard let url = URL(string: "sms:\(phoneNumber)&body=\(encodedMessage)") else { continue }
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Emergency Contact Row

struct EmergencyContactRow: View {
    let contact: EmergencyContact
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: contact.icon)
                .font(.title2)
                .foregroundColor(.voiceitPurple)
                .frame(width: 40, height: 40)
                .background(Color.voiceitPurple.opacity(0.1))
                .cornerRadius(8)
            
            // Contact info
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                
                Text(contact.relationship)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Badges
            VStack(alignment: .trailing, spacing: 4) {
                if contact.isPrimary {
                    Text("PRIMARY")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.voiceitPurple)
                        .cornerRadius(4)
                }
                
                if contact.autoNotify {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                        Text("Auto")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Contact View

struct AddEmergencyContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var relationship = "Friend"
    @State private var email = ""
    @State private var notes = ""
    @State private var autoNotify = false
    @State private var isPrimary = false
    
    private let relationships = ["Friend", "Family", "Partner", "Lawyer", "Therapist", "Doctor", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("Relationship", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel).tag(rel)
                        }
                    }
                }
                
                Section("Optional Details") {
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Auto-notify in emergency", isOn: $autoNotify)
                    Toggle("Primary contact", isOn: $isPrimary)
                } header: {
                    Text("Emergency Settings")
                } footer: {
                    Text("Auto-notify contacts will receive SMS alerts automatically when panic button is activated. Primary contact will be called first.")
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !phoneNumber.isEmpty
    }
    
    private func saveContact() {
        let contact = EmergencyContact(
            name: name,
            phoneNumber: phoneNumber,
            relationship: relationship,
            autoNotify: autoNotify,
            isPrimary: isPrimary,
            email: email.isEmpty ? nil : email,
            notes: notes.isEmpty ? nil : notes,
            priority: 0
        )
        
        modelContext.insert(contact)
        dismiss()
    }
}

// MARK: - Edit Contact View

struct EditEmergencyContactView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: EmergencyContact
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var relationship: String
    @State private var email: String
    @State private var notes: String
    @State private var autoNotify: Bool
    @State private var isPrimary: Bool
    
    private let relationships = ["Friend", "Family", "Partner", "Lawyer", "Therapist", "Doctor", "Other"]
    
    init(contact: EmergencyContact) {
        self.contact = contact
        _name = State(initialValue: contact.name)
        _phoneNumber = State(initialValue: contact.phoneNumber)
        _relationship = State(initialValue: contact.relationship)
        _email = State(initialValue: contact.email ?? "")
        _notes = State(initialValue: contact.notes ?? "")
        _autoNotify = State(initialValue: contact.autoNotify)
        _isPrimary = State(initialValue: contact.isPrimary)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    
                    Picker("Relationship", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel).tag(rel)
                        }
                    }
                }
                
                Section("Optional Details") {
                    TextField("Email (optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Emergency Settings") {
                    Toggle("Auto-notify in emergency", isOn: $autoNotify)
                    Toggle("Primary contact", isOn: $isPrimary)
                }
            }
            .navigationTitle("Edit Contact")
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
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !phoneNumber.isEmpty
    }
    
    private func saveChanges() {
        contact.name = name
        contact.phoneNumber = phoneNumber
        contact.relationship = relationship
        contact.email = email.isEmpty ? nil : email
        contact.notes = notes.isEmpty ? nil : notes
        contact.autoNotify = autoNotify
        contact.isPrimary = isPrimary
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EmergencyContactsView()
    }
    .modelContainer(for: EmergencyContact.self)
}
