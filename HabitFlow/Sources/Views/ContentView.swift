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
        #if os(macOS)
        MacContentView(service: service, notificationService: notificationService)
        #else
        TabView {
            TodayView(viewModel: TodayViewModel(service: service, notificationService: notificationService))
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
            _ = try? await notificationService.requestAuthorization()
            if let habits = try? await service.fetchHabits() {
                try? await notificationService.rescheduleAll(habits: habits)
            }
        }
        #endif
    }
}

#if os(macOS)
private enum MacTab: String, CaseIterable, Identifiable {
    case today = "오늘"
    case habits = "습관"
    case heatmap = "잔디"
    case settings = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: "checkmark.circle"
        case .habits: "list.bullet"
        case .heatmap: "square.grid.3x3"
        case .settings: "gearshape"
        }
    }
}

struct MacContentView: View {
    let service: HabitServiceProtocol
    let notificationService: NotificationServiceProtocol
    @State private var selectedTab: MacTab? = .today

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(MacTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selectedTab {
            case .today:
                TodayView(viewModel: TodayViewModel(service: service, notificationService: notificationService))
            case .habits:
                HabitListView(viewModel: HabitListViewModel(service: service, notificationService: notificationService))
            case .heatmap:
                HeatmapView(service: service)
            case .settings:
                SettingsView(notificationService: notificationService, habitService: service)
            case nil:
                TodayView(viewModel: TodayViewModel(service: service, notificationService: notificationService))
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .task {
            _ = try? await notificationService.requestAuthorization()
            if let habits = try? await service.fetchHabits() {
                try? await notificationService.rescheduleAll(habits: habits)
            }
        }
    }
}
#endif

#Preview {
    ContentView(service: MockHabitService(), notificationService: MockNotificationService())
}
