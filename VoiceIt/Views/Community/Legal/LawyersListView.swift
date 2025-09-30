import SwiftUI

/// List of pro bono lawyers offering legal consultations
@available(iOS 18, *)
struct LawyersListView: View {
    @Environment(\.communityService) private var communityService
    @State private var selectedJurisdiction: String?
    @State private var selectedSpecialization: LegalSpecialization?
    @State private var selectedLawyer: Lawyer?
    
    var allJurisdictions: [String] {
        var juris = Set<String>()
        communityService.lawyers.forEach { lawyer in
            juris.formUnion(lawyer.jurisdictions)
        }
        return Array(juris).sorted()
    }
    
    var filteredLawyers: [Lawyer] {
        communityService.lawyers.filter { lawyer in
            let jurisdictionMatch = selectedJurisdiction == nil || lawyer.jurisdictions.contains(selectedJurisdiction!)
            let specializationMatch = selectedSpecialization == nil || lawyer.specializations.contains(selectedSpecialization!)
            return jurisdictionMatch && specializationMatch
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Info Banner
                infoBanner
                
                // My Consultations
                if !communityService.myConsultations.isEmpty {
                    myConsultationsSection
                }
                
                // Filters
                filtersSection
                
                // Available Lawyers
                VStack(spacing: 16) {
                    if filteredLawyers.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredLawyers, id: \.id) { lawyer in
                            LawyerCard(lawyer: lawyer)
                                .onTapGesture {
                                    selectedLawyer = lawyer
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Legal Help")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedLawyer) { lawyer in
            NavigationStack {
                LawyerDetailView(lawyer: lawyer)
            }
        }
    }
    
    private var infoBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.voiceitPurple)
                
                Text("Pro Bono Legal Consultations")
                    .font(.headline)
            }
            
            Text("Connect with experienced lawyers offering free initial consultations.")
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
    
    private var myConsultationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Consultations")
                .font(.headline)
            
            ForEach(communityService.myConsultations.prefix(3), id: \.id) { consultation in
                ConsultationRow(consultation: consultation)
            }
            
            if communityService.myConsultations.count > 3 {
                NavigationLink {
                    AllConsultationsView()
                } label: {
                    Text("View all consultations (\(communityService.myConsultations.count))")
                        .font(.subheadline)
                        .foregroundStyle(Color.voiceitPurple)
                }
            }
        }
    }
    
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Jurisdiction Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Filter by State")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SimpleFilterChip(title: "All States", isSelected: selectedJurisdiction == nil) {
                            selectedJurisdiction = nil
                        }
                        
                        ForEach(allJurisdictions, id: \.self) { jurisdiction in
                            SimpleFilterChip(title: jurisdiction, isSelected: selectedJurisdiction == jurisdiction) {
                                selectedJurisdiction = jurisdiction
                            }
                        }
                    }
                }
            }
            
            // Specialization Filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Filter by Practice Area")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        SimpleFilterChip(title: "All Areas", isSelected: selectedSpecialization == nil) {
                            selectedSpecialization = nil
                        }
                        
                        ForEach(LegalSpecialization.allCases, id: \.self) { spec in
                            SimpleFilterChip(title: spec.rawValue, isSelected: selectedSpecialization == spec) {
                                selectedSpecialization = spec
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No lawyers found")
                .font(.headline)
            
            Text("Try adjusting your filters to see more results.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

/// Lawyer card component
struct LawyerCard: View {
    let lawyer: Lawyer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Profile image placeholder
                Image(systemName: "person.crop.circle.badge.checkmark.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.voiceitPurple, .green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(lawyer.name)
                        .font(.headline)
                    
                    Text(lawyer.firm)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(lawyer.rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                        }
                        Text(String(format: "%.1f", lawyer.rating))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("(\(lawyer.reviewCount))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if lawyer.isAcceptingConsultations {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Text(lawyer.bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            
            // Specializations
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(lawyer.specializations, id: \.self) { spec in
                        HStack(spacing: 4) {
                            Image(systemName: spec.icon)
                                .font(.caption2)
                            Text(spec.rawValue)
                                .font(.caption)
                        }
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
                Label("\(lawyer.yearsOfExperience) years", systemImage: "briefcase.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(lawyer.jurisdictions.joined(separator: ", "), systemImage: "map.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

/// Consultation row component
struct ConsultationRow: View {
    let consultation: LegalConsultation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3)
                .foregroundStyle(Color.voiceitPurple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(consultation.lawyerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(consultation.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(consultation.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(consultation.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(consultation.status.color).opacity(0.2))
                .foregroundStyle(Color(consultation.status.color))
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Placeholder for all consultations view
@available(iOS 18, *)
struct AllConsultationsView: View {
    @Environment(\.communityService) private var communityService
    
    var body: some View {
        List(communityService.myConsultations, id: \.id) { consultation in
            ConsultationRow(consultation: consultation)
        }
        .navigationTitle("My Consultations")
    }
}

#Preview {
    NavigationStack {
        LawyersListView()
            .environment(\.communityService, CommunityService())
    }
}
