# HabitFlow — 개인 습관 트래커

## 프로젝트 개요
매일의 습관을 기록하고 잔디(히트맵)로 시각화하는 개인용 앱.
SwiftUI + Firebase Firestore, iOS + macOS 네이티브.

## 기술 스택
- **UI**: SwiftUI (iOS 17+ / macOS 14+)
- **위젯**: WidgetKit
- **데이터**: Firebase Firestore (오프라인 퍼시스턴스 + 실시간 동기화)
- **인증**: Firebase Anonymous Auth
- **테스트**: Swift Testing
- **아키텍처**: MVVM
- **배포**: AltStore (iPhone) / Xcode 직접 빌드 (Mac)

## 개발 원칙

### TDD First
- 모든 기능은 테스트를 먼저 작성한 후 구현한다
- RED → GREEN → REFACTOR 사이클을 따른다
- 테스트 없는 구현은 리뷰를 통과할 수 없다

### 코드 품질 3원칙
1. **쓰지 않는 자원은 없앤다** — 미사용 import, 죽은 코드 즉시 제거
2. **3번 이상 반복되면 메서드로 분리** — 중복 발견 시 공통 유틸로 추출
3. **기능에는 테스트 코드** — ViewModel/Utils 100%, Services Mock 기반 90%+

## 에이전트 팀
- `plan` — 기획 구체화 + PRD 업데이트
- `test` — TDD, 테스트 선행 작성
- `firebase` — Firestore 서비스 레이어
- `ui` — SwiftUI 뷰/컴포넌트
- `deploy` — AltStore/Xcode 빌드 + 배포
- `review` — 코드 품질 + 개발 원칙 체크

## 작업 흐름
```
plan → test(RED) → firebase/ui(GREEN) → review → deploy
```

## PRD
- Obsidian: `010.Work/016.HabitFlow/HabitFlow-PRD.md`

## 빌드 명령어
```bash
# 테스트
xcodebuild test -scheme HabitFlow -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# iOS 빌드
xcodebuild -scheme HabitFlow build

# macOS 빌드
xcodebuild -scheme HabitFlow-macOS -destination 'platform=macOS' build
```
