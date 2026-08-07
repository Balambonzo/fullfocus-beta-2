import Foundation

enum DayStatus {
    case completed(StudyEntry)
    case missed
    case todayPending
}

struct DayInfo: Identifiable {
    let date: Date
    let status: DayStatus
    var id: Date { date }
}

struct StreakStats {
    let currentStreak: Int
    let bestStreak: Int
    let todayDone: Bool
}

/// Regola centrale dell'app: un giorno senza foto è "missed" per sempre.
/// Non esiste alcuna funzione per creare una StudyEntry con una data passata:
/// l'unico punto di ingresso (TodayView) crea sempre entry con date = oggi.
enum StreakCalculator {

    static func stats(for entries: [StudyEntry]) -> StreakStats {
        let calendar = Calendar.current
        let entryDates = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: Date())
        let todayDone = entryDates.contains(today)

        // Streak attuale: cammina all'indietro da oggi (o da ieri se oggi non è ancora fatto)
        var current = 0
        var cursor = todayDone ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        while entryDates.contains(cursor) {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        // Record storico: la sequenza consecutiva più lunga mai avuta
        var best = 0
        var running = 0
        var previous: Date?
        for d in entryDates.sorted() {
            if let prev = previous, calendar.date(byAdding: .day, value: 1, to: prev) == d {
                running += 1
            } else {
                running = 1
            }
            best = max(best, running)
            previous = d
        }

        return StreakStats(currentStreak: current, bestStreak: max(best, current), todayDone: todayDone)
    }

    /// Tutti i giorni da quando hai iniziato a oggi, ciascuno con il suo stato.
    /// I buchi restano buchi: è la parte che rende la griglia "rovinabile".
    static func gridDays(for entries: [StudyEntry]) -> [DayInfo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let firstDate = entries.map { calendar.startOfDay(for: $0.date) }.min() ?? today

        var entryByDate: [Date: StudyEntry] = [:]
        for e in entries {
            entryByDate[calendar.startOfDay(for: e.date)] = e
        }

        var days: [DayInfo] = []
        var cursor = firstDate
        while cursor <= today {
            let status: DayStatus
            if let entry = entryByDate[cursor] {
                status = .completed(entry)
            } else if cursor == today {
                status = .todayPending
            } else {
                status = .missed
            }
            days.append(DayInfo(date: cursor, status: status))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return days
    }
}
