import Foundation
import UIKit

/// Sostituto offline di CloudKitService. Nessuna rete: esiste un solo
/// "amico" fittizio, con codice fisso, usato finché non reintrodurremo
/// una sincronizzazione vera (CloudKit o altro backend).
enum FriendLookupService {

    static let demoFriendCode = "DEMO-0001"

    struct FriendProfile {
        let friendCode: String
        let username: String
        let currentStreak: Int
        let bestStreak: Int
        let lastEntryDate: Date?
        let latestPhoto: UIImage?
    }

    /// Ritorna il profilo fittizio solo se il codice combacia,
    /// altrimenti nil (comportamento identico a "utente non trovato").
    static func lookupFriend(byCode code: String) async -> FriendProfile? {
        guard code == demoFriendCode else { return nil }
        return FriendProfile(
            friendCode: demoFriendCode,
            username: "Amico Demo",
            currentStreak: 5,
            bestStreak: 12,
            lastEntryDate: Date(),
            latestPhoto: nil
        )
    }

    static func refreshFriend(byCode code: String) async -> FriendProfile? {
        try? await Task.sleep(nanoseconds: 300_000_000) // finto delay di rete
        return await lookupFriend(byCode: code)
    }
}
