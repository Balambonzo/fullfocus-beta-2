import SwiftUI
import SwiftData
import PhotosUI

/// Intro a schermate scorrevoli mostrata al primo avvio: spiega cosa fa
/// l'app e raccoglie i dati minimi del profilo (nome, username, foto,
/// obiettivo). Stessa estetica notturna/arancione della Collezione, così
/// l'identità visiva è coerente fin dal primo secondo.
struct OnboardingView: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var modelContext
    @State private var page = 0

    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var goal: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        ZStack {
                StarfieldBackground()

            TabView(selection: $page) {
                introPage(
                    icon: "flame.fill",
                    title: "Full Focus",
                    subtitle: "Un'app che trasforma la costanza in qualcosa che puoi vedere, giorno dopo giorno."
                )
                .tag(0)

                introPage(
                    icon: "camera.fill",
                    title: "Una foto al giorno",
                    subtitle: "Carica una foto di quello su cui hai lavorato per tenere viva la striscia. Nessun recupero, nessuna scorciatoia: un giorno saltato resta un vuoto per sempre."
                )
                .tag(1)

                introPage(
                    icon: "sparkles",
                    title: "Il tuo cielo",
                    subtitle: "Ogni giorno completato accende una stella sul tuo percorso. Guarda la costellazione crescere e collegati (presto) con chi non molla come te."
                )
                .tag(2)

                setupPage
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: page == 3 ? .never : .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .onAppear {
            fullName = profile.fullName
            username = profile.username
            goal = profile.goal ?? ""
        }
    }

    // MARK: - Pagine introduttive

    @ViewBuilder
    private func introPage(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(colors: [.orange, .yellow.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .orange.opacity(0.5), radius: 20)

            Text(title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Spacer()
            Spacer()

            Button {
                withAnimation { page += 1 }
            } label: {
                Text("Avanti")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Pagina di setup profilo

    private var setupPage: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Raccontaci di te")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 40)

                Text("Puoi cambiare tutto in seguito dal tuo profilo.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.orange, .orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 100, height: 100)

                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            selectedImage = uiImage
                        }
                    }
                }

                VStack(spacing: 14) {
                    OnboardingField(placeholder: "Il tuo nome", text: $fullName)
                    OnboardingField(placeholder: "Username (es. alessandro98)", text: $username)
                    OnboardingField(placeholder: "Il tuo obiettivo (es. entrare alla Normale)", text: $goal)
                }
                .padding(.horizontal, 28)

                Button {
                    completeOnboarding()
                } label: {
                    Text("Inizia")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            fullName.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.4) : Color.orange,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
                .disabled(fullName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() {
            profile.fullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedGoal = goal.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.goal = trimmedGoal.isEmpty ? nil : trimmedGoal
            if let selectedImage, let fileName = ImageStore.save(selectedImage) {
                profile.profileImagePath = fileName
            }
            profile.hasCompletedOnboarding = true
            try? modelContext.save()
        }

        /// Verifica che il friend code non sia già in uso da qualcun altro
        /// (evento raro, ma un profilo pubblico deve essere unico) e pubblica
        /// il profilo su CloudKit così è subito ricercabile dagli amici
}

private struct OnboardingField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
            .foregroundStyle(.white)
            .padding()
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .autocorrectionDisabled()
    }
}
