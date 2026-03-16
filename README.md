# HabitFlow

매일의 습관을 기록하고, GitHub 스타일 잔디(히트맵)로 시각화하는 개인용 습관 트래커.

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
- GitHub 스타일 잔디 히트맵 (12주/1년)
- 연속 기록(Streak) 추적
- 홈화면 위젯 (오늘 진행률 + 미니 잔디)
- Mac ↔ iPhone 실시간 동기화 (Firebase Firestore)
- 오프라인 지원

## Development Methodology

### TDD First
모든 기능은 테스트를 먼저 작성한 후 구현합니다.
```
RED → GREEN → REFACTOR
```

### Claude Agents
이 프로젝트는 [Claude Code](https://claude.com/claude-code)의 **Agent Team**을 활용하여 개발합니다.

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

각 기능의 테스트 통과 + 리뷰 완료 시점에 커밋합니다.

## Project Structure

```
HabitFlow/
├── Models/          # Firestore 데이터 모델
├── Views/           # SwiftUI 뷰
├── ViewModels/      # MVVM 뷰모델
├── Services/        # Firebase 서비스 레이어
├── Utilities/       # 헬퍼 (스트릭, 히트맵 계산)
├── HabitFlowWidget/ # WidgetKit Extension
└── HabitFlowTests/  # Swift Testing
```

## Deploy

| Device | Method | Renewal |
|--------|--------|---------|
| iPhone | AltStore sideloading | Auto (same Wi-Fi) |
| Mac | Xcode direct build | 7 days (automated via Claude) |
