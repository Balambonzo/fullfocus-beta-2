import Foundation
import SwiftData

/// Stesso motivo di UserProfile: niente @Attribute(.unique), perché
/// CloudKit (usato per il backup privato) non lo supporta.
@Model
final class StudyEntry {
    var id: UUID = UUID()
    var date: Date = Date()
    var imageFileName: String = ""
    var createdAt: Date = Date()

    init(date: Date, imageFileName: String) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.imageFileName = imageFileName
        self.createdAt = .now
    }
}
