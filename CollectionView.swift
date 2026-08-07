import SwiftUI
import SwiftData

struct CollectionView: View {
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @State private var selectedDay: DayInfo?
    @State private var appeared = false

    private var days: [DayInfo] {
        StreakCalculator.gridDays(for: entries)
    }

    private var stats: StreakStats {
        StreakCalculator.stats(for: entries)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    if entries.isEmpty {
                        ContentUnavailableView(
                            "Il cielo è ancora vuoto",
                            systemImage: "sparkles",
                            description: Text("La prima foto di oggi accende la prima stella.")
                        )
                        .padding(.top, 100)
                    } else {
                        header
                        pathCanvas
                            .padding(.bottom, 60)
                    }
                }
                .background(StarfieldBackground())
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) { appeared = true }
                    if let last = days.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .navigationTitle("Il tuo percorso")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(item: $selectedDay) { day in
                DayDetailView(date: day.date, status: day.status)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("\(stats.currentStreak) \(stats.currentStreak == 1 ? "notte" : "notti") di fila")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text("\(entries.count) stelle accese · record \(stats.bestStreak)")
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 12)
        .opacity(appeared ? 1 : 0)
    }

    private var pathCanvas: some View {
        GeometryReader { outerGeo in
            let width = outerGeo.size.width
            let points = ConstellationPath.points(count: days.count)
            let totalHeight = (points.last?.y ?? 0) + 140

            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for i in 0..<max(days.count - 1, 0) {
                        guard case .completed = days[i].status,
                              case .completed = days[i + 1].status else { continue }
                        let p1 = points[i]
                        let p2 = points[i + 1]
                        var path = Path()
                        path.move(to: CGPoint(x: p1.x * width, y: p1.y + 40))
                        path.addLine(to: CGPoint(x: p2.x * width, y: p2.y + 40))
                        context.stroke(
                            path,
                            with: .color(Color.orange.opacity(0.35)),
                            lineWidth: 1.5
                        )
                    }
                }
                .frame(width: width, height: totalHeight)

                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    let point = points[index]
                    StarNode(day: day, isLatest: index == days.count - 1)
                        .position(x: point.x * width, y: point.y + 40)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.4)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.65)
                                .delay(Double(index) * 0.03),
                            value: appeared
                        )
                        .onTapGesture {
                            if case .completed = day.status {
                                selectedDay = day
                            }
                        }
                        .id(day.id)
                }
            }
            .frame(width: width, height: totalHeight)
        }
        .frame(height: (ConstellationPath.points(count: days.count).last?.y ?? 0) + 180)
    }
}

private struct StarNode: View {
    let day: DayInfo
    let isLatest: Bool

    var body: some View {
        switch day.status {
        case .completed(let entry):
            CompletedStar(entry: entry, isLatest: isLatest)
        case .missed:
            MissedGap()
        case .todayPending:
            PendingStar()
        }
    }
}

private struct CompletedStar: View {
    let entry: StudyEntry
    let isLatest: Bool
    @State private var glow = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(glow ? 0.45 : 0.25))
                .frame(width: isLatest ? 54 : 44, height: isLatest ? 54 : 44)
                .blur(radius: 8)

            if let uiImage = ImageStore.load(entry.imageFileName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: isLatest ? 40 : 32, height: isLatest ? 40 : 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [.orange, .yellow.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isLatest ? 2.5 : 1.5
                        )
                    )
            }
        }
        .shadow(color: .orange.opacity(0.5), radius: isLatest ? 10 : 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}

private struct MissedGap: View {
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            .frame(width: 22, height: 22)
            .overlay(
                Image(systemName: "moon.zzz")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.2))
            )
    }
}

private struct PendingStar: View {
    @State private var pulse = false

    var body: some View {
        Circle()
            .stroke(Color.orange.opacity(0.6), lineWidth: 2)
            .frame(width: 30, height: 30)
            .scaleEffect(pulse ? 1.25 : 1.0)
            .opacity(pulse ? 0 : 1)
            .overlay(
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 30, height: 30)
            )
            .onAppear {
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    pulse = true
                }
            }
    }
}
