import SwiftUI
import GoogleSignIn

struct SettingsView: View {
    @Environment(AuthService.self) private var authService
    @State private var viewModel: SettingsViewModel
    @State private var summaryDate: Date = Date()
    @State private var isLoaded = false

    @State private var authError: String?
    @State private var isAuthLoading = false

    init(notificationService: NotificationServiceProtocol, habitService: HabitServiceProtocol) {
        _viewModel = State(initialValue: SettingsViewModel(
            notificationService: notificationService,
            habitService: habitService
        ))
    }

    var body: some View {
        AdaptiveNavigation {
            Form {
                accountSection
                notificationSection
                appInfoSection
            }
            .navigationTitle("설정")
            #if os(macOS)
            .formStyle(.grouped)
            #endif
            .task {
                viewModel.loadSettings()
                summaryDate = timeStringToDate(viewModel.settings.dailySummaryTime)
                isLoaded = true
            }
        }
    }

    // MARK: - Account Section

    @ViewBuilder
    private var accountSection: some View {
        if authService.isAnonymous {
            Section("계정") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("게스트 모드")
                        .font(.body)
                        .fontWeight(.medium)
                    Text("Google로 로그인하면 기기 간 동기화가 가능합니다")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        isAuthLoading = true
                        authError = nil
                        do {
                            try await authService.signInWithGoogle()
                        } catch let error as GIDSignInError where error.code == .canceled {
                            // 사용자 취소 — 무시
                        } catch {
                            authError = error.localizedDescription
                        }
                        isAuthLoading = false
                    }
                } label: {
                    HStack {
                        if isAuthLoading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "person.badge.key")
                        }
                        Text("Google로 로그인")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(isAuthLoading)
            }
            .alert("로그인 오류", isPresented: Binding(
                get: { authError != nil },
                set: { if !$0 { authError = nil } }
            )) {
                Button("확인", role: .cancel) {}
            } message: {
                if let error = authError {
                    Text(error)
                }
            }
        } else {
            Section("계정") {
                HStack {
                    Image(systemName: "person.badge.key")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(authService.userEmail ?? "Google 계정")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("기기 간 동기화 활성화됨")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Button("로그아웃", role: .destructive) {
                    do {
                        try authService.signOut()
                    } catch {
                        authError = error.localizedDescription
                    }
                }
            }
        }
    }

    // MARK: - Notification Section

    private var notificationSection: some View {
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
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Text("버전")
                Spacer()
                Text("0.1.0")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func timeStringToDate(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString) ?? Date()
    }
}
