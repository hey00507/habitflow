import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var summaryDate: Date = Date()
    @State private var isLoaded = false

    init(notificationService: NotificationServiceProtocol, habitService: HabitServiceProtocol) {
        _viewModel = State(initialValue: SettingsViewModel(
            notificationService: notificationService,
            habitService: habitService
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("알림") {
                    Toggle("전체 알림", isOn: $viewModel.settings.masterEnabled)
                        .onChange(of: viewModel.settings.masterEnabled) { _, newValue in
                            guard isLoaded else { return }
                            Task { await viewModel.saveMasterEnabled(newValue) }
                        }

                    Picker("미완료 알림", selection: $viewModel.settings.overdueDelay) {
                        Text("30분 후").tag(30)
                        Text("1시간 후").tag(60)
                        Text("2시간 후").tag(120)
                    }
                    .disabled(!viewModel.settings.masterEnabled)
                    .onChange(of: viewModel.settings.overdueDelay) { _, newValue in
                        guard isLoaded else { return }
                        Task { await viewModel.saveOverdueDelay(newValue) }
                    }

                    DatePicker("종합 알림 시간", selection: $summaryDate, displayedComponents: .hourAndMinute)
                        .disabled(!viewModel.settings.masterEnabled)
                        .onChange(of: summaryDate) { _, newValue in
                            guard isLoaded else { return }
                            let formatter = DateFormatter()
                            formatter.dateFormat = "HH:mm"
                            let timeString = formatter.string(from: newValue)
                            Task { await viewModel.saveDailySummaryTime(timeString) }
                        }
                }

                Section("앱 정보") {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("0.1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
            .task {
                viewModel.loadSettings()
                summaryDate = timeStringToDate(viewModel.settings.dailySummaryTime)
                isLoaded = true
            }
        }
    }

    private func timeStringToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }
}
