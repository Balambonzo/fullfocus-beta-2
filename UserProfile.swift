import Foundation
import SwiftData

/// Rappresenta l'utente locale. CloudKit non supporta vincoli di unicità
/// (@Attribute(.unique)), quindi qui l'unicità del friend code è garantita
/// a livello applicativo (vedi CloudKitService + OnboardingView), non dal
/// database.
@Model
final class UserProfile {
    var id: UUID = UUID()
    var fullName: String = ""
    var username: String = ""
    var friendCode: String = ""
    var profileImagePath: String? = nil
    var goal: String? = nil
    var memberSince: Date = Date()
    var totalStudySeconds: Double = 0
    var totalSessions: Int = 0
    var hasCompletedOnboarding: Bool = false

    init(fullName: String = "", username: String = "", friendCode: String) {
        self.id = UUID()
        self.fullName = fullName
        self.username = username
        self.friendCode = friendCode
        self.profileImagePath = nil
        self.goal = nil
        self.memberSince = .now
        self.totalStudySeconds = 0
        self.totalSessions = 0
        self.hasCompletedOnboarding = false
    }
}

enum UserProfileStore {
    @discardableResult
    static func fetchOrCreate(in context: ModelContext) -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile(friendCode: FriendCodeGenerator.generate())
        context.insert(profile)
        try? context.save()
        return profile
    }
}
