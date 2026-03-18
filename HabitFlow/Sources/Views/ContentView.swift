import SwiftUI

struct ContentView: View {
    private let service: HabitServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        service: HabitServiceProtocol = FirestoreHabitService(),
        notificationService: NotificationServiceProtocol = MockNotificationService() // TODO: UNNotificationService로 교체 (실기기 배포 시)
    ) {
        self.service = service
        self.notificationService = notificationService
    }

    var body: some View {
        TabView {
            TodayView(viewModel: TodayViewModel(service: service))
                .tabItem {
                    Label("오늘", systemImage: "checkmark.circle")
                }

            HabitListView(viewModel: HabitListViewModel(service: service))
                .tabItem {
                    Label("습관", systemImage: "list.bullet")
                }

            SettingsView(notificationService: notificationService, habitService: service)
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView(service: MockHabitService(), notificationService: MockNotificationService())
}
