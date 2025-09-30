import SwiftUI

/// Detail view for a lawyer with consultation booking
@available(iOS 18, *)
struct LawyerDetailView: View {
    let lawyer: Lawyer
    @Environment(\.dismiss) private var dismiss
    @Environment(\.communityService) private var communityService
    
    @State private var selectedTimeSlot: ConsultationTimeSlot?
    @State private var showBookingConfirmation = false
    @State private var showDocumentSharing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profile Header
                profileHeader
                
                // Bio
                bioSection
                
                // Specializations
                specializationsSection
                
                // Bar Admissions
                barAdmissionsSection
                
                // Available Time Slots
                availableSlotsSection
                
                // Book Button
                if let slot = selectedTimeSlot {
                    bookButton(for: slot)
                }
            }
            .padding()
        }
        .navigationTitle(lawyer.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Consultation Booked", isPresented: $showBookingConfirmation) {
            Button("Share Documents") {
                showDocumentSharing = true
            }
            Button("Set Reminder") {
                if let consultation = communityService.myConsultations.last {
                    communityService.setSessionReminder(
                        TherapySession(
                            therapistId: consultation.id,
                            therapistName: consultation.lawyerName,
                            date: consultation.date
                        ),
                        enabled: true
                    )
                }
                dismiss()
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            if let slot = selectedTimeSlot {
                Text("Your consultation with \(lawyer.name) is scheduled for \(slot.date.formatted(date: .long, time: .shortened)).\n\nYou can securely share documents before your meeting.")
            }
        }
        .sheet(isPresented: $showDocumentSharing) {
            DocumentSharingView(lawyerName: lawyer.name)
        }
    }
    
    private var profileHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.checkmark.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.voiceitPurple, .green)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(lawyer.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(lawyer.firm)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(lawyer.rating) ? "star.fill" : "star")
                            .font(.subheadline)
                            .foregroundStyle(.yellow)
                    }
                    Text(String(format: "%.1f", lawyer.rating))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("(\(lawyer.reviewCount))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Label("\(lawyer.yearsOfExperience) years of experience", systemImage: "briefcase.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(lawyer.bio)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var specializationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Practice Areas")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(lawyer.specializations, id: \.self) { spec in
                    HStack {
                        Image(systemName: spec.icon)
                            .foregroundStyle(Color.voiceitPurple)
                        Text(spec.rawValue)
                            .font(.subheadline)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private var barAdmissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bar Admissions & Jurisdictions")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(lawyer.barAdmissions, id: \.self) { bar in
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text(bar)
                            .font(.subheadline)
                    }
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(Color.voiceitPurple)
                    Text("Licensed in: \(lawyer.jurisdictions.joined(separator: ", "))")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var availableSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Time Slots")
                .font(.headline)
            
            if lawyer.availableSlots.isEmpty {
                Text("No available slots at this time. Please check back later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(lawyer.availableSlots) { slot in
                    ConsultationTimeSlotCard(
                        slot: slot,
                        isSelected: selectedTimeSlot?.id == slot.id
                    ) {
                        selectedTimeSlot = slot
                    }
                }
            }
        }
    }
    
    private func bookButton(for slot: ConsultationTimeSlot) -> some View {
        Button {
            communityService.bookLegalConsultation(lawyer: lawyer, timeSlot: slot)
            showBookingConfirmation = true
        } label: {
            HStack {
                Image(systemName: "calendar.badge.plus")
                Text("Book Consultation")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.voiceitPurple)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

/// Consultation time slot card component
struct ConsultationTimeSlotCard: View {
    let slot: ConsultationTimeSlot
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(slot.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(slot.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("\(slot.duration) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.voiceitPurple : .gray)
            }
            .padding()
            .background(isSelected ? Color.voiceitPurple.opacity(0.1) : Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.voiceitPurple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Document sharing view
@available(iOS 18, *)
struct DocumentSharingView: View {
    let lawyerName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.badge.arrow.up")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.voiceitPurple)
                
                Text("Share Documents Securely")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You can securely share your evidence exports with \(lawyerName).")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button {
                        // Share PDF export
                    } label: {
                        Label("Share PDF Export", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.voiceitPurple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        // Share Word export
                    } label: {
                        Label("Share Word Document", systemImage: "doc.richtext.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.voiceitPurple)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Share Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LawyerDetailView(
            lawyer: Lawyer(
                name: "Jennifer Williams",
                firm: "Legal Aid Society",
                barAdmissions: ["New York State Bar", "New Jersey State Bar"],
                specializations: [.domesticViolence, .restrainingOrders, .familyLaw],
                bio: "Dedicated to protecting survivors' rights with over 20 years of experience in family law.",
                yearsOfExperience: 20,
                rating: 4.9,
                reviewCount: 156,
                jurisdictions: ["NY", "NJ"],
                availableSlots: [
                    ConsultationTimeSlot(date: Date().addingTimeInterval(86400), duration: 30),
                    ConsultationTimeSlot(date: Date().addingTimeInterval(172800), duration: 30)
                ]
            )
        )
        .environment(\.communityService, CommunityService())
    }
}
