import SwiftUI

struct ContentView: View {
    private let service: HabitServiceProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        service: HabitServiceProtocol = FirestoreHabitService(),
        notificationService: NotificationServiceProtocol = LocalNotificationService()
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

            HabitListView(viewModel: HabitListViewModel(service: service, notificationService: notificationService))
                .tabItem {
                    Label("습관", systemImage: "list.bullet")
                }

            HeatmapView(service: service)
                .tabItem {
                    Label("잔디", systemImage: "square.grid.3x3")
                }

            SettingsView(notificationService: notificationService, habitService: service)
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
        .task {
            // 알림 권한 요청
            _ = try? await notificationService.requestAuthorization()

            // 앱 실행 시 알림 동적 스케줄링
            if let habits = try? await service.fetchHabits() {
                try? await notificationService.rescheduleAll(habits: habits)
            }
        }
    }
}

#Preview {
    ContentView(service: MockHabitService(), notificationService: MockNotificationService())
}
