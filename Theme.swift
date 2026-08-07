import SwiftUI

/// Palette e stile condivisi da tutta l'app: un solo linguaggio visivo,
/// non colori sparsi in ogni file.
enum Theme {
    static let nightGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.05, blue: 0.11),
            Color(red: 0.08, green: 0.09, blue: 0.18),
            Color(red: 0.05, green: 0.06, blue: 0.13)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let card = Color.white.opacity(0.06)
    static let cardBorder = Color.white.opacity(0.1)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.35)

    static let accent = Color.orange
}

extension View {
    /// Card "a vetro": sfondo traslucido + bordo sottile, lo stile
    /// riusato per ogni riquadro dell'app.
    func glassCard(padding: CGFloat = 16, corner: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
    }
}
