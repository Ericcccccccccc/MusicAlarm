import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            NavigationStack {
                AlarmListView()
            }
            .tabItem {
                Image(systemName: "alarm")
                Text("Alarms")
            }
            
            NavigationStack {
                SpotifySearchView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
        .tint(.appPrimary)
    }
}

#Preview {
    MainView()
}