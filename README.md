# HabitFlow

매일의 습관을 기록하고, GitHub 스타일 잔디(히트맵)로 시각화하는 개인용 습관 트래커.

## Tech Stack

| 항목 | 선택 |
|------|------|
| Framework | Next.js 15 (App Router) |
| Language | TypeScript |
| Styling | Tailwind CSS 4 |
| Database | Firebase Firestore (오프라인 + 실시간 동기화) |
| Auth | Firebase Anonymous Auth |
| Test | Vitest + Testing Library |
| Deploy | Vercel |
| PWA | Service Worker + manifest.json |

## Features

- 습관 등록/수정/삭제 (이름, 아이콘, 색상, 반복 요일)
- 일별 완료 체크 (탭 한 번)
- GitHub 스타일 잔디 히트맵 (12주/1년)
- 연속 기록(Streak) 추적
- 오프라인 지원 (Firestore 오프라인 퍼시스턴스)
- PWA — Safari "홈 화면에 추가"로 네이티브 앱처럼 사용

## Development

```bash
npm install
npm run dev       # http://localhost:3000
npm test          # Vitest (watch mode)
npm run test:run  # Vitest (single run)
npm run build     # Production build
npm run lint      # ESLint
```

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
| `ui` | 컴포넌트 + 페이지 개발 |
| `deploy` | Vercel 배포 + PWA 검증 |
| `review` | 코드 품질 + 개발 원칙 체크 |

### Workflow
```
plan → test(RED) → firebase/ui(GREEN) → review → deploy
```

각 기능의 테스트 통과 + 리뷰 완료 시점에 커밋합니다.

## Project Structure

```
src/
├── app/              # Next.js App Router
├── components/       # UI 컴포넌트
├── services/         # Firebase 서비스 레이어
├── hooks/            # 커스텀 훅
├── types/            # TypeScript 타입
└── utils/            # 유틸리티 (잔디 계산, 스트릭 등)
__tests__/            # Vitest 테스트
.claude/agents/       # Claude Agent 팀 정의
```
