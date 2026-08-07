import Foundation
import SwiftData

/// Un unico ModelContainer, interamente locale. Nessun backup su iCloud:
/// StudyEntry, UserProfile e Friend vivono solo sul dispositivo.
enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([StudyEntry.self, UserProfile.self, Friend.self])
        let config = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Impossibile creare il ModelContainer: \(error)")
        }
    }()
}
