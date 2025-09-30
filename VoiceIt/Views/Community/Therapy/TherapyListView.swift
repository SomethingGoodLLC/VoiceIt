import SwiftUI

/// List of available therapists offering pro bono sessions
@available(iOS 18, *)
struct TherapyListView: View {
    @Environment(\.communityService) private var communityService
    @State private var selectedSpecialization: String?
    @State private var selectedTherapist: Therapist?
    
    var allSpecializations: [String] {
        var specs = Set<String>()
        communityService.therapists.forEach { therapist in
            specs.formUnion(therapist.specializations)
        }
        return Array(specs).sorted()
    }
    
    var filteredTherapists: [Therapist] {
        if let spec = selectedSpecialization {
            return communityService.therapists.filter { $0.specializations.contains(spec) }
        }
        return communityService.therapists
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Info Banner
                infoBanner
                
                // My Sessions
                if !communityService.myTherapySessions.isEmpty {
                    mySessionsSection
                }
                
                // Specialization Filter
                specializationFilter
                
                // Available Therapists
                VStack(spacing: 16) {
                    ForEach(filteredTherapists, id: \.id) { therapist in
                        TherapistCard(therapist: therapist)
                            .onTapGesture {
                                selectedTherapist = therapist
                            }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Free Therapy")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedTherapist) { therapist in
            NavigationStack {
                TherapistDetailView(therapist: therapist)
            }
        }
    }
    
    private var infoBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.title)
                    .foregroundStyle(Color.voiceitPurple)
                
                Text("Pro Bono Therapy Sessions")
                    .font(.headline)
            }
            
            Text("Licensed therapists offering free 30-minute video sessions for survivors.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                Label("Licensed", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Label("Confidential", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                
                Label("Free", systemImage: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(Color.voiceitPurple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var mySessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Sessions")
                .font(.headline)
            
            ForEach(communityService.myTherapySessions.prefix(3), id: \.id) { session in
                SessionRow(session: session)
            }
            
            if communityService.myTherapySessions.count > 3 {
                NavigationLink {
                    AllSessionsView()
                } label: {
                    Text("View all sessions (\(communityService.myTherapySessions.count))")
                        .font(.subheadline)
                        .foregroundStyle(Color.voiceitPurple)
                }
            }
        }
    }
    
    private var specializationFilter: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filter by Specialization")
                .font(.headline)
            
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SimpleFilterChip(
                            title: "All",
                            isSelected: selectedSpecialization == nil
                        ) {
                            selectedSpecialization = nil
                        }
                        
                        ForEach(allSpecializations, id: \.self) { spec in
                            SimpleFilterChip(
                                title: spec,
                                isSelected: selectedSpecialization == spec
                            ) {
                                selectedSpecialization = spec
                            }
                        }
                    }
                }
        }
    }
}

/// Therapist card component
struct TherapistCard: View {
    let therapist: Therapist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile image placeholder
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.gray)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(therapist.name)
                        .font(.headline)
                    
                    Text(therapist.credentials)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(therapist.rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        Text(String(format: "%.1f", therapist.rating))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("(\(therapist.reviewCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if therapist.isAcceptingClients {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Text(therapist.bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Specializations
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(therapist.specializations, id: \.self) { spec in
                        Text(spec)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.voiceitPurple.opacity(0.1))
                            .foregroundStyle(Color.voiceitPurple)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Divider()
            
            HStack {
                Label("\(therapist.yearsOfExperience) years exp", systemImage: "briefcase.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if therapist.languages.count > 1 {
                    Label(therapist.languages.joined(separator: ", "), systemImage: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

/// Session row component
struct SessionRow: View {
    let session: TherapySession
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.title3)
                .foregroundStyle(Color.voiceitPurple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.therapistName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(session.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(session.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(session.status.color).opacity(0.2))
                .foregroundStyle(Color(session.status.color))
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}


/// Placeholder for all sessions view
@available(iOS 18, *)
struct AllSessionsView: View {
    @Environment(\.communityService) private var communityService
    
    var body: some View {
        List(communityService.myTherapySessions, id: \.id) { session in
            SessionRow(session: session)
        }
        .navigationTitle("My Sessions")
    }
}

#Preview {
    NavigationStack {
        TherapyListView()
            .environment(\.communityService, CommunityService())
    }
}
