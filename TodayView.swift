import SwiftUI
import SwiftData
import UIKit
import WidgetKit   // in cima al file

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @Query private var profiles: [UserProfile]
    @State private var showCamera = false
    @State private var appeared = false
    
    private var stats: StreakStats {
        StreakCalculator.stats(for: entries)
    }
    
    private var greetingName: String {
        profiles.first?.fullName ?? ""
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                
                VStack(spacing: 28) {
                    if !greetingName.isEmpty {
                        Text("Ciao, \(greetingName)")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Theme.cardBorder, lineWidth: 14)
                            .frame(width: 224, height: 224)
                        
                        Circle()
                            .trim(from: 0, to: stats.todayDone ? 1 : 0.001)
                            .stroke(
                                stats.todayDone ? Color.green.opacity(0.7) : Color.orange.opacity(0.7),
                                style: StrokeStyle(lineWidth: 14, lineCap: .round)
                            )
                            .frame(width: 224, height: 224)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(stats.todayDone ? .green : .orange)
                            Text("\(stats.currentStreak)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text(stats.currentStreak == 1 ? "giorno" : "giorni")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: stats.currentStreak)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    
                    VStack(spacing: 8) {
                        Text(stats.todayDone ? "Oggi è già andata." : "Non hai ancora caricato oggi.")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                        Text("Record: \(stats.bestStreak) \(stats.bestStreak == 1 ? "giorno" : "giorni")")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .opacity(appeared ? 1 : 0)
                    
                    Spacer()
                    
                    if !stats.todayDone {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Scatta la foto di oggi", systemImage: "camera.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                                .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
                                .shadow(color: .orange.opacity(0.35), radius: 14, y: 6)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        Label("Fatto per oggi", systemImage: "checkmark.seal.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Oggi")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                    appeared = true
                }
                let line = MotivationalNotifications.streakIdentityLine(forDays: stats.currentStreak)
                WidgetSnapshotStore.save(
                    StreakSnapshot(
                        currentStreak: stats.currentStreak,
                        bestStreak: stats.bestStreak,
                        todayDone: stats.todayDone,
                        motivationalLine: line,
                        updatedAt: Date()
                    )
                )
                WidgetCenter.shared.reloadAllTimelines()
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in
                    save(image)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    private func save(_ image: UIImage) {
        guard let fileName = ImageStore.save(image) else { return }
        let entry = StudyEntry(date: Date(), imageFileName: fileName)
        modelContext.insert(entry)
        try? modelContext.save()
        NotificationScheduler.shared.refreshSchedule()
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        updateWidgetSnapshot(newEntry: entry)
    }

    private func updateWidgetSnapshot(newEntry: StudyEntry) {
        let updatedStats = StreakCalculator.stats(for: entries + [newEntry])
        let line = MotivationalNotifications.streakIdentityLine(forDays: updatedStats.currentStreak)

        WidgetSnapshotStore.save(
            StreakSnapshot(
                currentStreak: updatedStats.currentStreak,
                bestStreak: updatedStats.bestStreak,
                todayDone: updatedStats.todayDone,
                motivationalLine: line,
                updatedAt: Date()
            )
        )
        WidgetCenter.shared.reloadAllTimelines()
    }
}
