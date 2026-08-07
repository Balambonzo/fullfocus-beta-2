import SwiftUI

struct ContentView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Oggi", systemImage: "flame.fill")
                }
            CollectionView()
                .tabItem {
                    Label("Collezione", systemImage: "square.grid.3x3.fill")
                }
            ProfileView()
                .tabItem {
                    Label("Profilo", systemImage: "person.crop.circle.fill")
                }
        }
        .tint(.orange)
    }
}
