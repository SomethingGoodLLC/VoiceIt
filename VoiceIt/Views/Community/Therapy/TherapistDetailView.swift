import SwiftUI

/// Detail view for a therapist with booking capability
@available(iOS 18, *)
struct TherapistDetailView: View {
    let therapist: Therapist
    @Environment(\.dismiss) private var dismiss
    @Environment(\.communityService) private var communityService
    
    @State private var selectedTimeSlot: TherapyTimeSlot?
    @State private var showBookingConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profile Header
                profileHeader
                
                // Bio
                bioSection
                
                // Specializations
                specializationsSection
                
                // Available Time Slots
                availableSlotsSection
                
                // Book Button
                if let slot = selectedTimeSlot {
                    bookButton(for: slot)
                }
            }
            .padding()
        }
        .navigationTitle(therapist.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Session Booked", isPresented: $showBookingConfirmation) {
            Button("Set Reminder") {
                if let session = communityService.myTherapySessions.last {
                    communityService.setSessionReminder(session, enabled: true)
                }
                dismiss()
            }
            Button("Done") {
                dismiss()
            }
        } message: {
            if let slot = selectedTimeSlot {
                Text("Your 30-minute session with \(therapist.name) is scheduled for \(slot.date.formatted(date: .long, time: .shortened)).\n\nYou'll receive a discreet reminder before your session.")
            }
        }
    }
    
    private var profileHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.gray)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(therapist.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(therapist.credentials)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(therapist.rating) ? "star.fill" : "star")
                            .font(.subheadline)
                            .foregroundStyle(.yellow)
                    }
                    Text(String(format: "%.1f", therapist.rating))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("(\(therapist.reviewCount))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Label("\(therapist.yearsOfExperience) years of experience", systemImage: "briefcase.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            
            Text(therapist.bio)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var specializationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Specializations")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(therapist.specializations, id: \.self) { spec in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(spec)
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
    
    private var availableSlotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Time Slots")
                .font(.headline)
            
            if therapist.availableSlots.isEmpty {
                Text("No available slots at this time. Please check back later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(therapist.availableSlots) { slot in
                    TimeSlotCard(
                        slot: slot,
                        isSelected: selectedTimeSlot?.id == slot.id
                    ) {
                        selectedTimeSlot = slot
                    }
                }
            }
        }
    }
    
    private func bookButton(for slot: TherapyTimeSlot) -> some View {
        Button {
            communityService.bookTherapySession(therapist: therapist, timeSlot: slot)
            showBookingConfirmation = true
        } label: {
            HStack {
                Image(systemName: "calendar.badge.plus")
                Text("Book Session")
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

/// Time slot card component
struct TimeSlotCard: View {
    let slot: TherapyTimeSlot
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

#Preview {
    NavigationStack {
        TherapistDetailView(
            therapist: Therapist(
                name: "Dr. Emily Martinez",
                credentials: "PhD, LMFT",
                bio: "Specializing in trauma-informed care with 15 years of experience helping survivors rebuild their lives.",
                specializations: ["Trauma", "PTSD", "Domestic Violence", "Anxiety"],
                yearsOfExperience: 15,
                languages: ["English", "Spanish"],
                rating: 4.9,
                reviewCount: 127,
                availableSlots: [
                    TherapyTimeSlot(date: Date().addingTimeInterval(86400), duration: 30),
                    TherapyTimeSlot(date: Date().addingTimeInterval(172800), duration: 30)
                ]
            )
        )
        .environment(\.communityService, CommunityService())
    }
}
