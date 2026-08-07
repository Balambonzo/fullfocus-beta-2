import SwiftUI
import SwiftData

struct AddFriendView: View {
    let myProfile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingFriends: [Friend]

    @State private var code: String = ""
    @State private var errorMessage: String?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                Form {
                    Section {
                        Text("Il tuo codice")
                            .foregroundStyle(Theme.textSecondary)
                        HStack {
                            Text(myProfile.friendCode)
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Button {
                                UIPasteboard.general.string = myProfile.friendCode
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    .listRowBackground(Theme.card)

                    Section("Aggiungi un amico") {
                        TextField("Codice amico (es. MXQ-4185)", text: $code)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .foregroundStyle(Theme.textPrimary)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button {
                            addFriend()
                        } label: {
                            if isSearching {
                                ProgressView()
                            } else {
                                Text("Aggiungi")
                            }
                        }
                        .disabled(code.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                        .tint(.orange)
                    }
                    .listRowBackground(Theme.card)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { dismiss() }
                        .tint(.orange)
                }
            }
        }
    }

    private func addFriend() {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard trimmed != myProfile.friendCode else {
            errorMessage = "Non puoi aggiungere te stesso."
            return
        }
        guard !existingFriends.contains(where: { $0.friendCode == trimmed }) else {
            errorMessage = "Hai già aggiunto questo amico."
            return
        }

        errorMessage = nil
        isSearching = true

        Task {
            guard let found = await FriendLookupService.lookupFriend(byCode: trimmed) else {
                await MainActor.run {
                    errorMessage = "Nessun utente ha questo codice."
                    isSearching = false
                }
                return
            }

            let friend = Friend(username: found.username, friendCode: found.friendCode)
            friend.currentStreak = found.currentStreak
            friend.bestStreak = found.bestStreak
            friend.lastEntryDate = found.lastEntryDate

            await MainActor.run {
                modelContext.insert(friend)
                try? modelContext.save()
                dismiss()
            }
        }
    }
}
