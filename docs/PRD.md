# HabitFlow — PRD (Product Requirements Document)

> 매일의 작은 습관을 기록하고, 잔디로 시각화하는 개인용 습관 트래커

## Overview

| 항목 | 내용 |
|------|------|
| 프로젝트명 | HabitFlow |
| 목적 | 러닝, 공부, 개발 등 일상 습관을 트래킹하고 시각화 |
| 대상 사용자 | 본인 (개인 사용) |
| 플랫폼 | iOS + macOS (SwiftUI, 코드 공유) |
| 기술 스택 | SwiftUI, WidgetKit, Firebase Firestore |
| 배포 | iPhone: AltStore / Mac: Xcode 직접 빌드 |
| 데이터 동기화 | Firebase Firestore (오프라인 퍼시스턴스 + 실시간 동기화) |
| Apple 계정 | 무료 개발자 계정 |

---

## Milestones

### Phase 1a — 기본 동작 (CRUD + 체크)

> 최소 동작하는 앱. Firebase 연동으로 습관을 등록하고 체크할 수 있다.

#### M1. 프로젝트 초기화

| # | 작업 | 상세 |
|---|------|------|
| 1 | Xcode 프로젝트 생성 | iOS + macOS 멀티플랫폼 타겟, SwiftUI, Bundle ID: `com.ethankim.HabitFlow` |
| 2 | Firebase SDK 설치 | SPM으로 `firebase-ios-sdk` 추가 (Firestore, Auth) |
| 3 | `GoogleService-Info.plist` 연동 | 앱 시작 시 `FirebaseApp.configure()` 호출 |
| 4 | Firestore 오프라인 퍼시스턴스 활성화 | `FirestoreSettings.cachePolicy` 설정 |
| 5 | PWA 잔재 제거 | `next-env.d.ts` 등 삭제 |

**완료 기준:** 앱 빌드 성공 + Firebase 콘솔에서 연결 확인

#### M2. 데이터 모델 + 서비스 레이어

| # | 작업 | 상세 |
|---|------|------|
| 1 | `Habit` 모델 정의 | name, icon (SF Symbol), color (hex), schedule ([Int] 요일), targetTime, createdAt, isArchived |
| 2 | `HabitLog` 모델 정의 | date, isCompleted, memo, completedAt |
| 3 | `HabitServiceProtocol` 정의 | CRUD 인터페이스 추상화 |
| 4 | `FirestoreHabitService` 구현 | Firestore CRUD + 실시간 리스너 (`snapshotListener`) |
| 5 | `MockHabitService` 구현 | 테스트/프리뷰용 Mock |
| 6 | 테스트 작성 | `test_createHabit`, `test_deleteHabit_deletesLogs`, `test_createLog_setsCompletedAt` |

**Firestore 컬렉션 구조:**

```
users/{userId}/habits/{habitId}
├── name: String
├── icon: String (SF Symbol name)
├── color: String (hex)
├── schedule: [Int] (1=일 ~ 7=토)
├── targetTime: String? ("HH:mm")
├── createdAt: Timestamp
└── isArchived: Bool

users/{userId}/habits/{habitId}/logs/{date}
├── date: String ("yyyy-MM-dd")
├── isCompleted: Bool
├── memo: String?
└── completedAt: Timestamp?
```

**완료 기준:** Mock 기반 서비스 테스트 전체 통과

#### M3. 인증

| # | 작업 | 상세 |
|---|------|------|
| 1 | `AuthService` 구현 | Firebase Anonymous Auth 자동 로그인 |
| 2 | 앱 시작 시 자동 인증 | `Auth.auth().signInAnonymously()` |
| 3 | userId 관리 | 인증 후 userId를 Firestore 경로에 사용 |
| 4 | Firestore 보안 규칙 | 본인 uid만 읽기/쓰기 허용 |

**완료 기준:** 앱 실행 시 자동 로그인 + Firestore에 userId 기반 데이터 격리 확인

#### M4. 습관 CRUD UI

| # | 작업 | 상세 |
|---|------|------|
| 1 | `HabitListView` | 등록된 습관 목록 표시 |
| 2 | `HabitFormView` | 습관 등록/수정 폼 (이름, SF Symbol 피커, 색상, 반복 요일, 목표 시간대) |
| 3 | `HabitListViewModel` | 목록 로딩, 삭제, 아카이브 처리 |
| 4 | 스와이프 삭제 | 목록에서 스와이프로 삭제/아카이브 |
| 5 | 테스트 작성 | ViewModel 로직 테스트 |

**완료 기준:** 습관 등록 → 목록 표시 → 수정 → 삭제 전체 플로우 동작

#### M5. 오늘의 습관 + 체크

| # | 작업 | 상세 |
|---|------|------|
| 1 | `TodayView` | 오늘 해당하는 습관만 필터링하여 표시 |
| 2 | 요일 필터링 | 현재 요일에 해당하는 습관만 표시 |
| 3 | 시간순 정렬 | targetTime 기준 오름차순 |
| 4 | 완료 체크 | 탭 한 번으로 체크/체크해제 토글 |
| 5 | 선택적 메모 | 체크 시 간단한 메모 입력 (optional) |
| 6 | `TodayViewModel` | 필터링, 정렬, 체크 토글 로직 |
| 7 | 테스트 작성 | `test_todayHabits_filtersCorrectWeekday`, `test_toggleCheck_createsLog`, `test_todayHabits_sortsByTargetTime` |

**완료 기준:** 실기기에서 습관 등록 → 체크 → 체크 해제 동작 + Mac↔iPhone Firestore 동기화 확인

---

### Phase 1b — 잔디 뷰 (Heatmap + Streak)

> 체크한 기록을 시각화한다.

#### M6. 히트맵

| # | 작업 | 상세 |
|---|------|------|
| 1 | `HeatmapView` | GitHub 스타일 잔디, 최근 12주 표시 |
| 2 | 색상 강도 | 하루 완료 습관 수에 따라 4단계 (0~4) 진하기 변화 |
| 3 | 습관별 필터 | 전체 또는 특정 습관만 필터링 |
| 4 | 1년 뷰 | 스크롤로 전체 1년 히트맵 확인 |
| 5 | `HeatmapViewModel` | 날짜별 완료 횟수 집계, 색상 매핑 |
| 6 | 테스트 작성 | `test_heatmapData_emptyLogs_allZero`, `test_heatmapData_multipleHabits_sumsPerDay`, `test_colorIntensity_0to4_mapsCorrectly` |

**완료 기준:** 2주 이상 체크 데이터를 넣고 잔디가 정확히 표시된다

#### M7. Streak

| # | 작업 | 상세 |
|---|------|------|
| 1 | Streak 계산 유틸리티 | 연속 완료 일수 계산 로직 |
| 2 | 현재 Streak 표시 | TodayView에 현재 연속 일수 뱃지 |
| 3 | 최장 Streak 기록 | 역대 최장 연속 기록 저장/표시 |
| 4 | 테스트 작성 | `test_streak_consecutiveDays_returnsCount`, `test_streak_gapInMiddle_resetsToRecent`, `test_streak_todayNotCompleted_excludesToday`, `test_streak_noLogs_returnsZero` |

**완료 기준:** Streak 숫자가 체크 기록과 정확히 일치

---

### Phase 1c — 위젯 (WidgetKit)

> 홈화면/데스크톱 위젯으로 빠르게 확인.

#### M8. 위젯

| # | 작업 | 상세 |
|---|------|------|
| 1 | WidgetKit Extension 타겟 추가 | iOS + macOS 위젯 지원 |
| 2 | App Group 설정 | 앱 ↔ 위젯 데이터 공유 |
| 3 | 오늘의 습관 위젯 (Small) | 진행률 표시 (예: 3/5) |
| 4 | 잔디 위젯 (Medium) | 최근 4주 미니 히트맵 |
| 5 | 위젯 갱신 타이밍 | 체크 시 + 시간 기반 자동 갱신 |
| 6 | 테스트 작성 | 위젯 데이터 프로바이더 테스트 |

**완료 기준:** 위젯에서 오늘 진행률 확인 + 앱에서 체크하면 위젯 갱신

---

### Phase 2 — 알림 (Notifications)

> 습관 시간에 알림을 받아 실행을 유도하고, 미완료 습관을 리마인드한다.

#### 알림 종류

| 유형 | 트리거 | 메시지 형식 | 조건 |
|------|--------|------------|------|
| **사전 알림** | targetTime 10분 전 | "{습관명} 할 시간입니다" | targetTime 있는 습관만 |
| **미완료 개별** | targetTime + N시간 후 (사용자 설정) | "아직 {습관명}을(를) 하지 않았습니다" | targetTime 있고 미체크 시 |
| **미완료 종합** | 하루 끝 (사용자 설정 시간) | "오늘 아직 N개 습관을 완료하지 않았습니다" | 미체크 습관이 1개 이상일 때 |

#### 알림 조건

- **targetTime 없는 습관**: 사전/개별 미완료 알림 안 보냄, 종합 알림에만 포함
- **이미 체크한 습관**: 미완료 알림 스킵
- **해당 요일 아닌 습관**: 모든 알림 스킵
- **알림 off 습관**: 해당 습관의 모든 알림 스킵

#### M9a. NotificationService + 사전 알림

| # | 작업 | 상세 |
|---|------|------|
| 1 | `NotificationService` 구현 | UNUserNotificationCenter 기반, 권한 요청 |
| 2 | `NotificationServiceProtocol` 정의 | 테스트용 추상화 |
| 3 | `MockNotificationService` 구현 | 테스트/프리뷰용 Mock |
| 4 | 사전 알림 스케줄링 | targetTime - 10분, `UNCalendarNotificationTrigger` (요일 반복) |
| 5 | Habit 모델 변경 | `isNotificationEnabled: Bool` 추가 |
| 6 | 습관 CRUD 시 알림 재스케줄링 | 등록/수정/삭제 시 알림 업데이트 |
| 7 | 테스트 작성 | 스케줄링 로직, 조건 필터링, CRUD 연동 |

**완료 기준:** 습관 등록 → 10분 전 알림 수신 + 습관 삭제 시 알림도 삭제

#### M9b. 미완료 리마인드 알림

| # | 작업 | 상세 |
|---|------|------|
| 1 | 미완료 개별 알림 | targetTime + overdueDelay 후 미체크 시 알림 |
| 2 | 미완료 종합 알림 | dailySummaryTime에 미체크 습관 카운트 알림 |
| 3 | 체크 시 알림 취소 | 완료 체크하면 해당 습관 미완료 알림 제거 |
| 4 | 테스트 작성 | 체크 후 알림 취소, 종합 알림 카운트 |

**완료 기준:** 미체크 시 개별+종합 리마인드 수신 + 체크 시 알림 취소

#### M9c. 알림 설정 UI

| # | 작업 | 상세 |
|---|------|------|
| 1 | HabitFormView 알림 토글 | 습관별 알림 on/off |
| 2 | Settings 탭 신규 | 전체 알림 마스터 스위치 |
| 3 | 미완료 개별 알림 시간 설정 | 30분/1시간/2시간 선택 (기본 1시간) |
| 4 | 종합 알림 시간 설정 | TimePicker (기본 21:00) |
| 5 | `SettingsViewModel` | 설정 로드/저장 (UserDefaults) |
| 6 | 테스트 작성 | 설정 변경 시 알림 재스케줄링 |

**완료 기준:** Settings에서 시간 변경 → 알림 스케줄 즉시 반영

#### 데이터 모델 변경

```
Habit (기존 필드에 추가)
├── isNotificationEnabled: Bool (기본 true)

NotificationSettings (UserDefaults)
├── masterEnabled: Bool (기본 true)
├── overdueDelay: Int (분 단위, 기본 60)
├── dailySummaryTime: String ("HH:mm", 기본 "21:00")
```

#### 기술 결정사항

- **플랫폼**: iOS + macOS 양쪽 알림 지원 (중복 감수)
- **동적 스케줄링**: 앱 실행 시마다 등록된 알림 확인 → 부족하면 다음 7일치 채움 (64개 제한 대응)
- **종합 알림 메시지**: "오늘 아직 3개 습관을 완료하지 않았습니다 (독서, 러닝, 영어)" 형식
- **설정 저장**: UserDefaults (알림은 기기 로컬이라 Firestore 동기화 불필요)
- **알림 식별자 규칙**: `{habitId}-{type}-{weekday}` (type: pre/overdue/summary)

---

### Phase 3 — 통계 (Analytics)

> 습관 데이터를 분석하고 인사이트를 제공한다.

#### M10. 통계 대시보드

| # | 작업 | 상세 |
|---|------|------|
| 1 | 주간/월간 완료율 차트 | Swift Charts 기반 |
| 2 | 습관별 통계 | 개별 스트릭, 평균 완료율 |
| 3 | 요일별 패턴 | 어떤 요일에 잘 지키는지 히트맵 |
| 4 | 트렌드 | 시간에 따른 완료율 변화 추이 |

#### M11. 성취 시스템

| # | 작업 | 상세 |
|---|------|------|
| 1 | 마일스톤 알림 | 7일/30일/100일 연속 달성 시 축하 |
| 2 | 뱃지 시스템 | 연속 기록, 총 완료 횟수 기반 뱃지 |

#### M12. 데이터 내보내기

| # | 작업 | 상세 |
|---|------|------|
| 1 | CSV 내보내기 | 전체 습관 로그를 CSV로 다운로드 |
| 2 | 잔디 스크린샷 공유 | 히트맵 이미지 생성 + 공유 시트 |

**완료 기준:** 통계 대시보드에서 주간/월간 차트 확인 + 뱃지 수여 동작

---

## 테스트 전략

### TDD 사이클

```
1. RED    — 실패하는 테스트 작성
2. GREEN  — 테스트를 통과하는 최소 구현
3. REFACTOR — 코드 정리 (테스트는 계속 통과해야 함)
```

### 테스트 레이어

| 레이어 | 대상 | 커버리지 목표 |
|--------|------|-------------|
| Service | Firestore CRUD | Mock 기반 90%+ |
| ViewModel | 비즈니스 로직 | 100% |
| Utilities | 스트릭/히트맵 계산 | 100% |
| Notification | 스케줄링/취소 로직 | Mock 기반 90%+ |
| Widget | 데이터 프로바이더 | 필수 케이스 |
| View | UI 스냅샷 | 추후 (낮음) |

### 테스트 네이밍

```
test_[대상]_[상황]_[기대결과]
```

---

## 기술 아키텍처

```
HabitFlow/
├── Shared/                    # iOS + macOS 공유 코드
│   ├── Models/                # Firestore 데이터 모델 (Codable)
│   │   ├── Habit.swift
│   │   └── HabitLog.swift
│   ├── Views/
│   │   ├── HabitList/         # 습관 목록/CRUD
│   │   │   ├── HabitListView.swift
│   │   │   └── HabitFormView.swift
│   │   ├── Today/             # 오늘의 습관
│   │   │   └── TodayView.swift
│   │   ├── Heatmap/           # 잔디 히트맵
│   │   │   └── HeatmapView.swift
│   │   ├── Dashboard/         # 통계 (Phase 3)
│   │   └── Settings/          # 알림 설정 (Phase 2)
│   │       └── SettingsView.swift
│   ├── ViewModels/
│   │   ├── HabitListViewModel.swift
│   │   ├── TodayViewModel.swift
│   │   ├── HeatmapViewModel.swift
│   │   └── SettingsViewModel.swift     # Phase 2
│   ├── Services/
│   │   ├── HabitServiceProtocol.swift
│   │   ├── FirestoreHabitService.swift
│   │   ├── MockHabitService.swift
│   │   ├── AuthService.swift
│   │   └── NotificationService.swift  # Phase 2
│   └── Utilities/
│       ├── StreakCalculator.swift
│       └── HeatmapDataBuilder.swift
├── HabitFlowWidget/           # WidgetKit Extension (Phase 1c)
├── HabitFlowTests/            # Swift Testing
├── HabitFlow-iOS/             # iOS 타겟
└── HabitFlow-macOS/           # macOS 타겟
```

---

## 비기능 요구사항

- **오프라인 우선**: 네트워크 없이도 모든 핵심 기능 동작
- **최소 입력**: 습관 체크는 탭 한 번으로 완료
- **빠른 실행**: 앱 실행 → 체크까지 2탭 이내
- **개인정보**: 모든 데이터는 Firebase 개인 프로젝트에만 저장 (Anonymous Auth)
- **Mac↔iPhone 동기화**: Firestore 실시간 동기화로 기기 간 즉시 반영

---

## 배포

| 기기 | 방식 | 갱신 |
|------|------|------|
| iPhone | AltStore 사이드로딩 | Auto (같은 Wi-Fi) |
| Mac | Xcode 직접 빌드 | 7일마다 |

### 제약사항 (무료 개발자 계정)
- 동시 3개 앱 제한
- CloudKit 사용 불가 → Firebase Firestore로 대체
- Mac 앱은 AltStore 미지원 → Xcode 직접 빌드
