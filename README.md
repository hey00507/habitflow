# HabitFlow

매일의 습관을 기록하고, GitHub 스타일 잔디(히트맵)로 시각화하는 개인용 습관 트래커.

[마이루틴](https://myroutine.today)에서 아이디어를 착안했으며, [Claude Code](https://claude.com/claude-code) Agent Team을 활용하여 개발합니다.

## Tech Stack

| 항목 | 선택 |
|------|------|
| UI | SwiftUI (iOS 17+ / macOS 14+) |
| Widget | WidgetKit |
| Database | Firebase Firestore (오프라인 + 실시간 동기화) |
| Auth | Firebase Anonymous Auth |
| Test | Swift Testing |
| Architecture | MVVM |
| Deploy | AltStore (iPhone) / Xcode (Mac) |

## Features

- 습관 등록/수정/삭제 (이름, SF Symbol, 색상, 반복 요일)
- 일별 완료 체크 (탭 한 번)
- GitHub 스타일 잔디 히트맵 (12주 / 1년)
- 연속 기록(Streak) 추적
- 홈화면 위젯 (오늘 진행률 + 미니 잔디)
- Mac ↔ iPhone 실시간 동기화
- 오프라인 지원

## Milestones

자세한 마일스톤은 [PRD](docs/PRD.md)를 참조하세요.

| Phase | 이름 | 핵심 목표 |
|-------|------|----------|
| **1a** | 기본 동작 | Xcode 셋업 + Firebase 연동 + 습관 CRUD + 체크 |
| **1b** | 잔디 뷰 | GitHub 스타일 히트맵 + Streak 계산 |
| **1c** | 위젯 | WidgetKit (오늘 진행률 + 미니 잔디) |
| **2** | 알림 | 습관별 로컬 푸시 알림 |
| **3** | 통계 | 주간/월간 완료율 차트 + 성취 뱃지 |

## Development

### TDD First

모든 기능은 테스트를 먼저 작성한 후 구현합니다.

```
RED → GREEN → REFACTOR
```

### Claude Agent Team

| Agent | Role |
|-------|------|
| `plan` | 기획 구체화 + PRD 업데이트 |
| `test` | TDD — 테스트 선행 작성 |
| `firebase` | Firestore 서비스 레이어 |
| `ui` | SwiftUI 뷰/컴포넌트 |
| `deploy` | AltStore/Xcode 배포 |
| `review` | 코드 품질 + 개발 원칙 체크 |

### Workflow

```
plan → test(RED) → firebase/ui(GREEN) → review → deploy
```

## Project Structure

```
HabitFlow/
├── Shared/              # iOS + macOS 공유 코드
│   ├── Models/          # Firestore 데이터 모델 (Codable)
│   ├── Views/           # SwiftUI 뷰
│   │   ├── HabitList/   # 습관 목록/CRUD
│   │   ├── Heatmap/     # 잔디 히트맵
│   │   ├── Dashboard/   # 통계 (Phase 3)
│   │   └── Settings/    # 설정
│   ├── ViewModels/      # MVVM 뷰모델
│   ├── Services/        # Firebase 서비스 레이어
│   └── Utilities/       # 헬퍼 (날짜, 스트릭, 히트맵 계산)
├── HabitFlowWidget/     # WidgetKit Extension
├── HabitFlowTests/      # Swift Testing
├── HabitFlow-iOS/       # iOS 타겟
└── HabitFlow-macOS/     # macOS 타겟
```

## Setup

### Firebase 설정 (필수)

이 프로젝트는 `GoogleService-Info.plist`가 필요합니다 (보안상 Git에 포함되지 않음).

1. [Firebase Console](https://console.firebase.google.com)에서 프로젝트 생성
2. iOS 앱 등록 — Bundle ID: `com.ethankim.HabitFlow`
3. `GoogleService-Info.plist` 다운로드 → 프로젝트 루트에 배치
4. Firestore Database 생성 (테스트 모드)
5. Authentication → 익명(Anonymous) 로그인 활성화

### 빌드

```bash
# 테스트
xcodebuild test -scheme HabitFlow -destination 'platform=iOS Simulator,name=iPhone 16'

# iOS 빌드
xcodebuild -scheme HabitFlow-iOS build

# macOS 빌드
xcodebuild -scheme HabitFlow-macOS -destination 'platform=macOS' build
```

## Deploy

| Device | Method | Renewal |
|--------|--------|---------|
| iPhone | AltStore sideloading | Auto (same Wi-Fi) |
| Mac | Xcode direct build | 7 days |

## License

Personal project. Not intended for App Store distribution.
