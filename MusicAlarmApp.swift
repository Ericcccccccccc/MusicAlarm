import SwiftUI
import CoreData

@main
struct MusicAlarmApp: App {
    @StateObject private var alarmManager = AlarmManager.shared
    @StateObject private var spotifyManager = SpotifyManager.shared
    
    let persistenceManager = PersistenceManager.shared
    let notificationManager = NotificationManager.shared
    let audioManager = AudioManager.shared
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceManager.context)
                .environmentObject(alarmManager)
                .environmentObject(spotifyManager)
                .onAppear {
                    requestNotificationPermissions()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    alarmManager.rescheduleAllAlarms()
                }
        }
    }
    
    private func setupApp() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        notificationManager.setupNotificationCategories()
    }
    
    private func requestNotificationPermissions() {
        Task {
            let granted = await alarmManager.requestNotificationPermission()
            if !granted {
                print("Notification permission not granted")
            }
        }
    }
}