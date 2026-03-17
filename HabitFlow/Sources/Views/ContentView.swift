import SwiftUI

struct ContentView: View {
    var body: some View {
        HabitListView(viewModel: HabitListViewModel(service: FirestoreHabitService()))
    }
}

#Preview {
    HabitListView(viewModel: HabitListViewModel(service: MockHabitService()))
}
