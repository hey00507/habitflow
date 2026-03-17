import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("HabitFlow")
                .font(.largeTitle)
                .fontWeight(.bold)
                .navigationTitle("HabitFlow")
        }
    }
}

#Preview {
    ContentView()
}
