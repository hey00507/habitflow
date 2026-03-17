import SwiftUI

struct ContentView: View {
    private let service: HabitServiceProtocol

    init(service: HabitServiceProtocol = FirestoreHabitService()) {
        self.service = service
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
        }
    }
}

#Preview {
    ContentView(service: MockHabitService())
}
