import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyEntry.date) private var entries: [StudyEntry]
    @Query private var friends: [Friend]

    @State private var profile: UserProfile?
    @State private var appeared = false
    @State private var copiedFeedback = false
    @State private var photoScale: CGFloat = 1
    @State private var showAddFriend = false
    @State private var selectedFriend: Friend? 

    private var stats: StreakStats {
        StreakCalculator.stats(for: entries)
    }
    
    private func refreshAllFriends() async {
        for friend in friends {
            if let updated = await FriendLookupService.refreshFriend(byCode: friend.friendCode) {
                friend.username = updated.username
                friend.currentStreak = updated.currentStreak
                friend.bestStreak = updated.bestStreak
                friend.lastEntryDate = updated.lastEntryDate
            }
        }
        try? modelContext.save()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        if let profile {
                            header(profile)
                            heroStreak
                            statsGrid
                            achievementsSection
                            friendsSection(profile)
                            settingsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .refreshable {
                                        await refreshAllFriends()
                                    }
                }
            }
            .navigationTitle("Profilo")
            .fontDesign(.rounded)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if profile == nil {
                    profile = UserProfileStore.fetchOrCreate(in: modelContext)
                }
                withAnimation(.easeOut(duration: 0.5)) {
                    appeared = true
                }
            }
            .sheet(isPresented: $showAddFriend) {
                if let profile {
                    AddFriendView(myProfile: profile)
                }
            }
            .sheet(item: $selectedFriend) { friend in
                            FriendDetailView(friend: friend)
                        }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(_ profile: UserProfile) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 116, height: 116)

                Group {
                    if let path = profile.profileImagePath, let uiImage = ImageStore.load(path) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())
                .background(Circle().fill(Color.white.opacity(0.05)))
            }
            .shadow(color: .orange.opacity(0.25), radius: 16, y: 6)
            .scaleEffect(photoScale)
            .onTapGesture {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    photoScale = 0.94
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                        photoScale = 1
                    }
                }
            }

            Text(profile.fullName.isEmpty ? profile.username : profile.fullName)
                .font(.title2.bold())
                .foregroundStyle(Theme.textPrimary)

            if !profile.username.isEmpty {
                Text("@\(profile.username)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }

            Text("Member since \(profile.memberSince.formatted(.dateTime.month(.wide).year()))")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)

            if let goal = profile.goal, !goal.isEmpty {
                Label(goal, systemImage: "target")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
            }

            Button {
                UIPasteboard.general.string = profile.friendCode
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    copiedFeedback = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation { copiedFeedback = false }
                }
            } label: {
                Label(copiedFeedback ? "Copied" : "\(profile.friendCode) · Copy", systemImage: copiedFeedback ? "checkmark" : "doc.on.doc")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.card, in: Capsule())
                    .overlay(Capsule().stroke(Theme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    // MARK: - Hero streak

    private var heroStreak: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundStyle(.orange)
                .shadow(color: .orange.opacity(0.5), radius: 10)

            CountUpNumber(target: stats.currentStreak)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Text("Current Streak")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            Text(MotivationalNotifications.streakIdentityLine(forDays: stats.currentStreak))
                .font(.footnote.italic())
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .glassCard(padding: 0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.easeOut(duration: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Stats grid 2x2

    private var statsGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            StatCard(icon: "trophy.fill", value: "\(stats.bestStreak)", label: "Best Streak")
            StatCard(icon: "clock.fill", value: studyHoursText, label: "Study Time")
            StatCard(icon: "book.fill", value: "\(entries.count)", label: "Sessions")
            StatCard(icon: "checkmark.seal.fill", value: "\(entries.count)", label: "Completed")
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }

    private var studyHoursText: String {
        let hours = Double(entries.count) * 45.0 / 60.0
        return String(format: "%.0f h", hours)
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Achievements")

            HStack(spacing: 0) {
                AchievementBadge(emoji: "🥉", label: "7 days", unlocked: stats.bestStreak >= 7)
                AchievementBadge(emoji: "🥈", label: "30 days", unlocked: stats.bestStreak >= 30)
                AchievementBadge(emoji: "🥇", label: "100 days", unlocked: stats.bestStreak >= 100)
                AchievementBadge(emoji: "💎", label: "365 days", unlocked: stats.bestStreak >= 365)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .glassCard(padding: 0)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)
    }

    // MARK: - Friends

    @ViewBuilder
    private func friendsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Friends")

            if friends.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No friends yet")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    Button {
                        showAddFriend = true
                    } label: {
                        Label("Add Friend", systemImage: "arrow.right")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()
            } else {
                VStack(spacing: 0) {
                                    ForEach(friends.prefix(3)) { friend in
                                        FriendRow(friend: friend)
                                            .contentShape(Rectangle())
                                            .onTapGesture { selectedFriend = friend }
                                        if friend.id != friends.prefix(3).last?.id {
                                            Divider().overlay(Theme.cardBorder).padding(.leading, 56)
                                        }
                                    }
                                }
                                .glassCard(padding: 0)
                HStack {
                    if friends.count > 3 {
                        Button {
                            // TODO: navigazione a una FriendsListView dedicata
                        } label: {
                            Text("See all →")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()

                    Button {
                        showAddFriend = true
                    } label: {
                        Label("Add Friend", systemImage: "person.badge.plus")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Settings")

            VStack(spacing: 0) {
                SettingsRow(icon: "bell.fill", title: "Notifications")
                Divider().overlay(Theme.cardBorder).padding(.leading, 52)
                SettingsRow(icon: "paintbrush.fill", title: "Appearance")
                Divider().overlay(Theme.cardBorder).padding(.leading, 52)
                SettingsRow(icon: "square.and.arrow.up", title: "Export Data")
                Divider().overlay(Theme.cardBorder).padding(.leading, 52)
                SettingsRow(icon: "lock.fill", title: "Privacy")
            }
            .glassCard(padding: 0)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(.easeOut(duration: 0.5).delay(0.25), value: appeared)
    }
}

// MARK: - Componenti riusabili

private struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)
    }
}

private struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

private struct AchievementBadge: View {
    let emoji: String
    let label: String
    let unlocked: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 30))
                .opacity(unlocked ? 1 : 0.2)
                .grayscale(unlocked ? 0 : 1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(unlocked ? Theme.textSecondary : Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55).delay(.random(in: 0...0.2))) {
                appeared = true
            }
        }
    }
}

private struct FriendRow: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.06))
                if let path = friend.profileImagePath, let uiImage = ImageStore.load(path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.username)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("@\(friend.friendCode)")
                    .font(.caption2)
                    .foregroundStyle(Theme.textTertiary)
            }

            Spacer()

            Label("\(friend.currentStreak)", systemImage: "flame.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

private struct CountUpNumber: View {
    let target: Int
    @State private var current: Int = 0

    var body: some View {
        Text("\(current)")
            .onAppear { animate() }
            .onChange(of: target) { _, _ in animate() }
    }

    private func animate() {
        current = 0
        guard target > 0 else { return }
        let steps = min(target, 30)
        let stepValue = max(target / steps, 1)
        var value = 0
        let interval = 0.5 / Double(steps)
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            value += stepValue
            if value >= target {
                current = target
                timer.invalidate()
            } else {
                current = value
            }
        }
    }
}
