import WidgetKit
import SwiftUI

struct StreakLockScreenWidgetView: View {
    var entry: StreakEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                    Text("\(entry.currentStreak)")
                        .font(.headline)
                }
            }
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("\(entry.currentStreak) \(entry.currentStreak == 1 ? "giorno" : "giorni")",
                      systemImage: "flame.fill")
                    .font(.headline)
                Text(entry.motivationalLine)
                    .font(.caption2)
                    .lineLimit(2)
            }
        default:
            Text("\(entry.currentStreak)")
        }
    }
}

struct StreakLockScreenWidget: Widget {
    let kind = "StreakLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak (Lock Screen)")
        .description("Streak e frase motivazionale sulla schermata di blocco.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
