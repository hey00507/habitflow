# HabitFlow — 개인 습관 트래커 (PWA)

## 프로젝트 개요
매일의 습관을 기록하고 잔디(히트맵)로 시각화하는 개인용 웹앱.
Next.js + TypeScript + Tailwind CSS + Firebase Firestore.

## 기술 스택
- **프레임워크**: Next.js 15 (App Router)
- **언어**: TypeScript (strict mode)
- **스타일링**: Tailwind CSS 4
- **데이터**: Firebase Firestore (오프라인 퍼시스턴스)
- **인증**: Firebase Anonymous Auth
- **테스트**: Vitest + Testing Library
- **배포**: Vercel
- **PWA**: Service Worker + manifest.json

## 개발 원칙

### TDD First
- 모든 기능은 테스트를 먼저 작성한 후 구현한다
- RED → GREEN → REFACTOR 사이클을 따른다
- 테스트 없는 구현은 리뷰를 통과할 수 없다

### 코드 품질 3원칙
1. **쓰지 않는 자원은 없앤다** — 미사용 import, 죽은 코드, 빈 디렉토리 즉시 제거
2. **3번 이상 반복되면 메서드로 분리** — 중복 발견 시 공통 유틸/훅으로 추출
3. **기능에는 테스트 코드** — hooks/utils 100%, services Mock 기반 90%+

## 에이전트 팀
- `plan` — 기획 구체화 + PRD 업데이트
- `test` — TDD, 테스트 선행 작성
- `firebase` — Firestore 서비스 레이어
- `ui` — 컴포넌트 + 페이지 개발
- `deploy` — Vercel 배포 + PWA 검증
- `review` — 코드 품질 + 개발 원칙 체크

## 작업 흐름
```
plan → test(RED) → firebase/ui(GREEN) → review → deploy
```

## PRD
- `prd.md` 참조 (Phase 1a/1b/1c → Phase 2 → Phase 3)

## 명령어
```bash
npm run dev       # 개발 서버 (localhost:3000)
npm run build     # 프로덕션 빌드
npm test          # Vitest 테스트 실행
npm run lint      # ESLint
```
