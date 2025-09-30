import Foundation
import Observation

/// Service for managing community features with privacy-first design
/// Uses @Observable for modern Swift 6 state management
@available(iOS 18, *)
@Observable
final class CommunityService {
    // MARK: - Published State
    
    var supportGroups: [SupportGroup] = []
    var therapists: [Therapist] = []
    var lawyers: [Lawyer] = []
    var articles: [CommunityArticle] = []
    var myTherapySessions: [TherapySession] = []
    var myConsultations: [LegalConsultation] = []
    var myPseudonym: String
    
    // MARK: - Privacy Settings
    
    var isAnonymousModeEnabled: Bool {
        didSet {
            savePrivacySettings()
        }
    }
    
    // MARK: - Initialization
    
    init() {
        // Generate random pseudonym for anonymous mode
        self.myPseudonym = Self.generatePseudonym()
        self.isAnonymousModeEnabled = true
        
        // Load mock data
        loadMockData()
    }
    
    // MARK: - Support Groups
    
    func joinSupportGroup(_ group: SupportGroup) {
        // In real implementation, this would call backend API
        print("✅ Joined support group: \(group.topic)")
    }
    
    func leaveSupportGroup(_ group: SupportGroup) {
        print("👋 Left support group: \(group.topic)")
    }
    
    func reportContent(postId: UUID, reason: String) {
        // Report harmful content to moderators
        print("🚨 Content reported: \(postId) - \(reason)")
    }
    
    // MARK: - Therapy Sessions
    
    func bookTherapySession(therapist: Therapist, timeSlot: TherapyTimeSlot) {
        let session = TherapySession(
            therapistId: therapist.id,
            therapistName: therapist.name,
            date: timeSlot.date,
            duration: timeSlot.duration
        )
        myTherapySessions.append(session)
        print("✅ Booked therapy session with \(therapist.name)")
    }
    
    func cancelTherapySession(_ session: TherapySession) {
        session.status = .cancelled
        print("❌ Cancelled therapy session")
    }
    
    func setSessionReminder(_ session: TherapySession, enabled: Bool) {
        session.reminderSet = enabled
        // In real implementation, schedule local notification
    }
    
    // MARK: - Legal Consultations
    
    func bookLegalConsultation(lawyer: Lawyer, timeSlot: ConsultationTimeSlot) {
        let consultation = LegalConsultation(
            lawyerId: lawyer.id,
            lawyerName: lawyer.name,
            date: timeSlot.date,
            duration: timeSlot.duration
        )
        myConsultations.append(consultation)
        print("✅ Booked legal consultation with \(lawyer.name)")
    }
    
    func cancelLegalConsultation(_ consultation: LegalConsultation) {
        consultation.status = .cancelled
        print("❌ Cancelled legal consultation")
    }
    
    func shareDocument(with consultation: LegalConsultation, documentURL: String) {
        consultation.documentsShared.append(documentURL)
        print("📄 Document shared with lawyer")
    }
    
    // MARK: - Resource Library
    
    func markArticleAsRead(_ article: CommunityArticle) {
        article.viewCount += 1
    }
    
    func downloadResource(_ article: CommunityArticle) {
        guard let downloadURL = article.downloadURL else { return }
        print("⬇️ Downloading resource: \(downloadURL)")
    }
    
    // MARK: - Privacy
    
    func deleteMyActivity() {
        // Clear all user activity and reset pseudonym
        myPseudonym = Self.generatePseudonym()
        print("🗑️ All community activity deleted")
    }
    
    private func savePrivacySettings() {
        // Save to UserDefaults or Keychain
        UserDefaults.standard.set(isAnonymousModeEnabled, forKey: "community.anonymousMode")
    }
    
    // MARK: - Mock Data
    
    private func loadMockData() {
        loadMockSupportGroups()
        loadMockTherapists()
        loadMockLawyers()
        loadMockArticles()
    }
    
    private func loadMockSupportGroups() {
        supportGroups = [
            SupportGroup(
                topic: "First Steps: Breaking Free",
                groupDescription: "A safe space for those beginning their journey to safety and independence.",
                moderator: "Dr. Sarah Chen, LCSW",
                memberCount: 247,
                category: .firstSteps,
                schedule: "Weekly on Mondays at 7 PM EST"
            ),
            SupportGroup(
                topic: "Legal Journey Support",
                groupDescription: "Navigate the legal system with others who understand your challenges.",
                moderator: "Attorney Maria Rodriguez",
                memberCount: 189,
                category: .legalJourney,
                schedule: "Bi-weekly on Thursdays at 6 PM EST"
            ),
            SupportGroup(
                topic: "Healing & Recovery Circle",
                groupDescription: "Focus on emotional healing and rebuilding your life with compassion.",
                moderator: "Dr. James Williams, PhD",
                memberCount: 312,
                category: .healingRecovery,
                schedule: "Daily check-ins, Weekly meetings Saturdays 10 AM EST"
            ),
            SupportGroup(
                topic: "Single Parents United",
                groupDescription: "Support for parents navigating co-parenting and custody challenges.",
                moderator: "Lisa Thompson, MSW",
                memberCount: 156,
                category: .parentingSupport,
                schedule: "Weekly on Sundays at 8 PM EST"
            ),
            SupportGroup(
                topic: "Financial Independence Workshop",
                groupDescription: "Learn budgeting, job skills, and financial planning for independence.",
                moderator: "Michael Chen, CFP",
                memberCount: 203,
                category: .financialIndependence,
                schedule: "Monthly workshops, 1st Saturday at 2 PM EST"
            )
        ]
    }
    
    private func loadMockTherapists() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        therapists = [
            Therapist(
                name: "Dr. Emily Martinez",
                credentials: "PhD, LMFT",
                bio: "Specializing in trauma-informed care with 15 years of experience helping survivors rebuild their lives.",
                specializations: ["Trauma", "PTSD", "Domestic Violence", "Anxiety"],
                yearsOfExperience: 15,
                languages: ["English", "Spanish"],
                rating: 4.9,
                reviewCount: 127,
                availableSlots: [
                    TherapyTimeSlot(date: tomorrow, duration: 30),
                    TherapyTimeSlot(date: nextWeek, duration: 30)
                ]
            ),
            Therapist(
                name: "Dr. Michael Thompson",
                credentials: "PsyD",
                bio: "Compassionate care focused on healing from emotional abuse and rebuilding self-esteem.",
                specializations: ["Emotional Abuse", "Depression", "Self-Esteem", "Relationships"],
                yearsOfExperience: 12,
                rating: 4.8,
                reviewCount: 94,
                availableSlots: [
                    TherapyTimeSlot(date: tomorrow, duration: 30)
                ]
            ),
            Therapist(
                name: "Sarah Johnson",
                credentials: "LCSW, CASAC",
                bio: "Expert in substance abuse recovery and domestic violence with a holistic approach.",
                specializations: ["Substance Abuse", "Domestic Violence", "Dual Diagnosis"],
                yearsOfExperience: 10,
                languages: ["English", "French"],
                rating: 4.7,
                reviewCount: 82,
                availableSlots: [
                    TherapyTimeSlot(date: nextWeek, duration: 30)
                ]
            )
        ]
    }
    
    private func loadMockLawyers() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        lawyers = [
            Lawyer(
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
                    ConsultationTimeSlot(date: tomorrow, duration: 30),
                    ConsultationTimeSlot(date: nextWeek, duration: 30)
                ]
            ),
            Lawyer(
                name: "Robert Chen",
                firm: "Family Justice Center",
                barAdmissions: ["California State Bar"],
                specializations: [.childCustody, .divorce, .restrainingOrders],
                bio: "Compassionate legal advocacy for families seeking safety and stability.",
                yearsOfExperience: 15,
                rating: 4.8,
                reviewCount: 112,
                jurisdictions: ["CA"],
                availableSlots: [
                    ConsultationTimeSlot(date: tomorrow, duration: 30)
                ]
            ),
            Lawyer(
                name: "Maria Rodriguez",
                firm: "Immigrant Rights Legal Clinic",
                barAdmissions: ["Texas State Bar", "Federal Courts"],
                specializations: [.immigration, .domesticViolence, .housing],
                bio: "Bilingual attorney specializing in immigration issues for domestic violence survivors.",
                yearsOfExperience: 12,
                rating: 5.0,
                reviewCount: 203,
                jurisdictions: ["TX", "Federal"],
                availableSlots: [
                    ConsultationTimeSlot(date: nextWeek, duration: 30)
                ]
            )
        ]
    }
    
    private func loadMockArticles() {
        articles = [
            CommunityArticle(
                title: "Understanding Restraining Orders",
                summary: "A comprehensive guide to obtaining and enforcing protective orders.",
                content: "Detailed content about restraining orders, types, process, and enforcement...",
                category: .legal,
                contentType: .guide,
                author: "Legal Aid Society",
                readingTime: 12,
                tags: ["Legal", "Protection", "Court"],
                isFeatured: true
            ),
            CommunityArticle(
                title: "Safety Planning 101",
                summary: "Create a comprehensive safety plan for you and your children.",
                content: "Step-by-step guide to creating an effective safety plan...",
                category: .safety,
                contentType: .checklist,
                author: "National DV Hotline",
                readingTime: 8,
                tags: ["Safety", "Planning", "Emergency"],
                isFeatured: true,
                downloadURL: "https://example.com/safety-plan.pdf"
            ),
            CommunityArticle(
                title: "Court Preparation Guide",
                summary: "What to expect and how to prepare for your court appearance.",
                content: "Detailed guide on court procedures, what to bring, and how to present your case...",
                category: .legal,
                contentType: .article,
                author: "Attorney Jennifer Williams",
                readingTime: 15,
                tags: ["Legal", "Court", "Preparation"]
            ),
            CommunityArticle(
                title: "Healing from Trauma: A Survivor's Journey",
                summary: "Personal story of recovery and finding strength after abuse.",
                content: "A powerful story of resilience and healing...",
                category: .stories,
                contentType: .story,
                author: "Anonymous Survivor",
                readingTime: 10,
                tags: ["Healing", "Story", "Hope"],
                isFeatured: true
            ),
            CommunityArticle(
                title: "Financial Independence Checklist",
                summary: "Steps to achieve financial freedom and security.",
                content: "Practical checklist for managing finances independently...",
                category: .financial,
                contentType: .checklist,
                author: "Financial Freedom Coalition",
                readingTime: 6,
                tags: ["Financial", "Independence", "Budget"],
                downloadURL: "https://example.com/financial-checklist.pdf"
            ),
            CommunityArticle(
                title: "Explaining Divorce to Children",
                summary: "Age-appropriate ways to talk to your kids about separation.",
                content: "Expert advice on communicating with children during difficult transitions...",
                category: .childcare,
                contentType: .guide,
                author: "Dr. Sarah Chen, LCSW",
                readingTime: 9,
                tags: ["Children", "Communication", "Parenting"]
            )
        ]
    }
    
    // MARK: - Helpers
    
    private static func generatePseudonym() -> String {
        let adjectives = ["Brave", "Strong", "Resilient", "Hopeful", "Courageous", "Determined"]
        let nouns = ["Phoenix", "Warrior", "Survivor", "Star", "Spirit", "Heart"]
        let randomNum = Int.random(in: 100...999)
        return "\(adjectives.randomElement()!)\(nouns.randomElement()!)\(randomNum)"
    }
}
