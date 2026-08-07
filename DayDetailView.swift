import SwiftUI

struct DayDetailView: View {
    let date: Date
    let status: DayStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack {
                    if case .completed(let entry) = status, let image = ImageStore.load(entry.imageFileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()
                    }
                    Spacer()
                }
            }
            .navigationTitle(date.formatted(.dateTime.day().month(.wide).year()))
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
}
