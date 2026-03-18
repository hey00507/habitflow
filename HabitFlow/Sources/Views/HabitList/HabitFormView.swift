import SwiftUI

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var schedule: Set<Int>
    @State private var targetTime: Date?
    @State private var hasTargetTime: Bool
    @State private var isNotificationEnabled: Bool

    private let existingHabit: Habit?
    private let onSave: (Habit) -> Void

    private let availableIcons = [
        "figure.run", "book.fill", "laptopcomputer", "brain.head.profile",
        "drop.fill", "bed.double.fill", "fork.knife", "heart.fill",
        "paintbrush.fill", "music.note", "dumbbell.fill", "leaf.fill",
        "pencil.and.outline", "globe", "star.fill", "cup.and.saucer.fill"
    ]

    private let availableColors = [
        "#4CAF50", "#2196F3", "#FF5722", "#9C27B0",
        "#FF9800", "#00BCD4", "#E91E63", "#607D8B"
    ]

    private let dayNames = ["일", "월", "화", "수", "목", "금", "토"]

    init(habit: Habit? = nil, onSave: @escaping (Habit) -> Void) {
        self.existingHabit = habit
        self.onSave = onSave
        _name = State(initialValue: habit?.name ?? "")
        _icon = State(initialValue: habit?.icon ?? "star.fill")
        _color = State(initialValue: habit?.color ?? "#4CAF50")
        _schedule = State(initialValue: Set(habit?.schedule ?? [2, 3, 4, 5, 6]))
        _hasTargetTime = State(initialValue: habit?.targetTime != nil)
        _isNotificationEnabled = State(initialValue: habit?.isNotificationEnabled ?? true)

        if let timeStr = habit?.targetTime {
            let parts = timeStr.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 {
                var components = DateComponents()
                components.hour = parts[0]
                components.minute = parts[1]
                _targetTime = State(initialValue: Calendar.current.date(from: components))
            } else {
                _targetTime = State(initialValue: nil)
            }
        } else {
            _targetTime = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                iconSection
                colorSection
                scheduleSection
                timeSection
                notificationSection
            }
            .navigationTitle(existingHabit == nil ? "새 습관" : "습관 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("이름") {
            TextField("습관 이름", text: $name)
        }
    }

    private var iconSection: some View {
        Section("아이콘") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                ForEach(availableIcons, id: \.self) { iconName in
                    Image(systemName: iconName)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(icon == iconName ? Color(hex: color).opacity(0.2) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture { icon = iconName }
                }
            }
        }
    }

    private var colorSection: some View {
        Section("색상") {
            HStack(spacing: 12) {
                ForEach(availableColors, id: \.self) { hex in
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if color == hex {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .onTapGesture { color = hex }
                }
            }
        }
    }

    private var scheduleSection: some View {
        Section("반복 요일") {
            HStack(spacing: 8) {
                ForEach(Array(dayNames.enumerated()), id: \.offset) { index, day in
                    let dayNumber = index + 1 // 1=일 ~ 7=토
                    Text(day)
                        .font(.callout)
                        .fontWeight(.medium)
                        .frame(width: 36, height: 36)
                        .background(schedule.contains(dayNumber) ? Color(hex: color) : Color(.systemGray5))
                        .foregroundStyle(schedule.contains(dayNumber) ? .white : .primary)
                        .clipShape(Circle())
                        .onTapGesture {
                            if schedule.contains(dayNumber) {
                                schedule.remove(dayNumber)
                            } else {
                                schedule.insert(dayNumber)
                            }
                        }
                }
            }
        }
    }

    private var timeSection: some View {
        Section("목표 시간") {
            Toggle("시간 설정", isOn: $hasTargetTime)
            if hasTargetTime {
                DatePicker(
                    "시간",
                    selection: Binding(
                        get: { targetTime ?? Calendar.current.startOfDay(for: .now) },
                        set: { targetTime = $0 }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var notificationSection: some View {
        Section("알림") {
            Toggle("알림 받기", isOn: $isNotificationEnabled)
        }
    }

    // MARK: - Save

    private func save() {
        let timeString: String? = if hasTargetTime, let time = targetTime {
            String(format: "%02d:%02d",
                   Calendar.current.component(.hour, from: time),
                   Calendar.current.component(.minute, from: time))
        } else {
            nil
        }

        var habit = existingHabit ?? Habit(name: name)
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.icon = icon
        habit.color = color
        habit.schedule = schedule.sorted()
        habit.targetTime = timeString
        habit.isNotificationEnabled = isNotificationEnabled

        onSave(habit)
        dismiss()
    }
}
