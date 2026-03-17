# Swift 스터디 가이드 - HabitFlow 프로젝트 기반

> JS/TS, Python 경험이 있는 개발자를 위한 Swift 입문 가이드.
> 모든 예제는 HabitFlow 프로젝트의 실제 코드를 사용합니다.

---

## 목차

1. [Swift 기본 문법](#1-swift-기본-문법)
2. [Codable & CodingKeys](#2-codable--codingkeys)
3. [Protocol](#3-protocol)
4. [async/await](#4-asyncawait)
5. [SwiftUI 기초](#5-swiftui-기초)
6. [@Observable & @State](#6-observable--state)
7. [@MainActor](#7-mainactor)
8. [Sendable](#8-sendable)
9. [MVVM 패턴](#9-mvvm-패턴)
10. [Swift Testing](#10-swift-testing)
11. [Firebase + SwiftUI](#11-firebase--swiftui)
12. [프로젝트 구조](#12-프로젝트-구조)

---

## 1. Swift 기본 문법

### `struct` vs `class`

Swift에서 데이터 모델을 만들 때 `struct`와 `class` 중 선택해야 한다. 가장 큰 차이는 **값 타입(value type)** vs **참조 타입(reference type)**.

```swift
// HabitFlow/Sources/Models/Habit.swift
struct Habit: Codable, Identifiable, Sendable, Hashable {
    var id: String?
    var name: String
    var icon: String
    var color: String
    var schedule: [Int]
    var targetTime: String?
    var createdAt: Date
    var isArchived: Bool
}
```

- `struct`는 **값 타입** -- 변수에 할당하거나 함수에 전달하면 **복사본**이 만들어진다
- `class`는 **참조 타입** -- 같은 인스턴스를 여러 곳에서 공유한다

```swift
// struct (값 타입) - 복사됨
var habit1 = Habit(name: "러닝")
var habit2 = habit1        // habit1의 복사본
habit2.name = "독서"       // habit1.name은 여전히 "러닝"

// class (참조 타입) - 같은 객체 공유
let vm1 = HabitListViewModel(service: service)
let vm2 = vm1              // 같은 인스턴스를 가리킴
```

**JS/TS 비교:**
```typescript
// JS에서 object는 항상 참조 타입
const obj1 = { name: "러닝" };
const obj2 = obj1;
obj2.name = "독서";  // obj1.name도 "독서"로 변경됨!

// Swift struct는 이런 일이 발생하지 않음
```

**HabitFlow에서의 사용 패턴:**
- `Habit`, `HabitLog`, `TodayHabitItem` -- `struct` (데이터 모델)
- `HabitListViewModel`, `AuthService` -- `class` (상태를 공유해야 하는 객체)

### `let` vs `var`

```swift
let name = "러닝"      // 불변 (JS의 const와 유사)
var count = 0          // 가변 (JS의 let과 유사)
count += 1             // OK
// name = "독서"       // 컴파일 에러!
```

**주의:** JS의 `const`는 객체의 프로퍼티 변경을 허용하지만, Swift의 `let`은 struct의 프로퍼티 변경도 막는다.

```typescript
// JS - const는 프로퍼티 변경 가능
const habit = { name: "러닝" };
habit.name = "독서";  // OK
```

```swift
// Swift - let struct는 프로퍼티 변경 불가
let habit = Habit(name: "러닝")
// habit.name = "독서"  // 컴파일 에러!

var habit = Habit(name: "러닝")
habit.name = "독서"     // OK - var이므로 가능
```

### 옵셔널 (`?`, `!`, `if let`, `guard let`)

Swift의 가장 독특한 특징. **null 안전성**을 타입 시스템에서 강제한다.

```swift
// HabitFlow/Sources/Models/Habit.swift
struct Habit {
    var id: String?        // String 또는 nil (Optional<String>)
    var name: String       // 반드시 String (nil 불가)
    var targetTime: String? // String 또는 nil
}
```

**JS/TS 비교:**
```typescript
// TypeScript
interface Habit {
    id?: string;          // string | undefined
    name: string;
    targetTime?: string;  // string | undefined
}
// 하지만 런타임에 undefined 접근 가능 -> 크래시 위험
```

Swift는 옵셔널 값을 사용하기 전에 반드시 **언래핑(unwrap)**해야 한다:

```swift
// HabitFlow/Sources/Views/Today/TodayView.swift
// if let - 값이 있으면 실행
if let time = item.habit.targetTime {
    Text(time)  // time은 String (non-optional)
}

// HabitFlow/Sources/Services/FirestoreHabitService.swift
// guard let - 값이 없으면 조기 반환
func updateHabit(_ habit: Habit) async throws {
    guard let id = habit.id else { throw HabitServiceError.notFound }
    // 여기서 id는 String (non-optional)
    try habitsCollection.document(id).setData(from: habit, merge: true)
}

// ?? - nil 병합 연산자 (JS의 ?? 와 동일)
var id: String { habit.id ?? UUID().uuidString }
```

**`!` (강제 언래핑) -- 가급적 피할 것:**
```swift
// 값이 nil이면 앱 크래시!
let id = habit.id!  // 위험

// 테스트에서는 허용 -- 실패하면 테스트가 실패해야 하므로
try await service.deleteHabit(created.id!)
```

**Swift 옵셔널 체크 패턴 비교:**

| Swift | JS/TS |
|-------|-------|
| `value?` (타입) | `value?: Type` |
| `if let v = value { }` | `if (value !== undefined) { }` |
| `guard let v = value else { return }` | `if (!value) return;` |
| `value ?? default` | `value ?? default` |
| `value?.method()` | `value?.method()` |

---

## 2. Codable & CodingKeys

### Codable이란?

Swift의 **JSON 직렬화/역직렬화** 프로토콜. JS의 `JSON.parse()` / `JSON.stringify()` 역할을 타입 안전하게 수행한다.

`Codable`은 실제로 `Encodable & Decodable` 두 프로토콜의 합성이다.

```swift
// HabitFlow/Sources/Models/Habit.swift
struct Habit: Codable, Identifiable, Sendable, Hashable {
    var id: String?
    var name: String
    var icon: String          // SF Symbol name
    var color: String         // hex (e.g. "#FF5733")
    var schedule: [Int]       // 반복 요일 (1=일 ~ 7=토)
    var targetTime: String?   // "HH:mm"
    var createdAt: Date
    var isArchived: Bool

    enum CodingKeys: String, CodingKey {
        case name, icon, color, schedule, targetTime, createdAt, isArchived
    }
}
```

**JS/TS 비교:**
```typescript
// JS에서는 수동으로 변환해야 함
interface Habit {
    name: string;
    icon: string;
}

// 직렬화
const json = JSON.stringify(habit);

// 역직렬화 - 타입 보장 없음!
const habit = JSON.parse(json) as Habit;
```

```swift
// Swift Codable - 컴파일러가 자동으로 인코더/디코더 생성
let encoder = JSONEncoder()
let data = try encoder.encode(habit)  // Habit -> JSON Data

let decoder = JSONDecoder()
let habit = try decoder.decode(Habit.self, from: data)  // JSON Data -> Habit
```

### CodingKeys의 역할

`CodingKeys`는 **어떤 프로퍼티를 JSON에 포함할지, 키 이름을 어떻게 매핑할지** 정의한다.

```swift
// HabitFlow/Sources/Models/Habit.swift
enum CodingKeys: String, CodingKey {
    case name, icon, color, schedule, targetTime, createdAt, isArchived
    // 주목: id가 빠져있다!
}
```

**왜 `id`를 CodingKeys에서 제외했는가?**

Firestore에서 문서 ID는 JSON 필드가 아니라 **문서 경로의 일부**이다:
```
users/{userId}/habits/{habitId}  <-- 이 habitId가 id
                       └── { name: "러닝", icon: "..." }  <-- JSON에 id 없음
```

그래서 `id`는 Codable 직렬화에서 제외하고, 별도로 할당한다:
```swift
// HabitFlow/Sources/Services/FirestoreHabitService.swift
func fetchHabits() async throws -> [Habit] {
    let snapshot = try await habitsCollection.getDocuments()
    return snapshot.documents.compactMap { doc in
        var habit = try? doc.data(as: Habit.self)  // JSON -> Habit (id 없이)
        habit?.id = doc.documentID                  // 문서 ID를 별도로 할당
        return habit
    }
}
```

**HabitLog도 같은 패턴:**
```swift
// HabitFlow/Sources/Models/HabitLog.swift
struct HabitLog: Codable, Identifiable, Sendable {
    var id: String?       // 문서 ID = "yyyy-MM-dd"
    var date: String
    var isCompleted: Bool
    var memo: String?
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case date, isCompleted, memo, completedAt
        // id 제외 -- Firestore 문서 ID로 관리
    }
}
```

### CodingKeys로 키 이름 매핑하기

만약 서버 JSON이 snake_case이고 Swift는 camelCase를 쓴다면:
```swift
enum CodingKeys: String, CodingKey {
    case createdAt = "created_at"   // JSON: "created_at" -> Swift: createdAt
    case isArchived = "is_archived"
}
```

HabitFlow에서는 Firestore가 Swift와 같은 camelCase를 쓰기 때문에 매핑 없이 그대로 사용한다.

---

## 3. Protocol

### Protocol이란?

다른 언어의 **interface**와 유사하다. 타입이 구현해야 하는 메서드/프로퍼티의 **계약(contract)**을 정의한다.

```swift
// HabitFlow/Sources/Services/HabitServiceProtocol.swift
protocol HabitServiceProtocol: Sendable {
    // MARK: - Habits
    func createHabit(_ habit: Habit) async throws -> Habit
    func fetchHabits() async throws -> [Habit]
    func updateHabit(_ habit: Habit) async throws
    func deleteHabit(_ habitId: String) async throws

    // MARK: - Logs
    func createLog(_ log: HabitLog, habitId: String) async throws
    func fetchLogs(habitId: String, from: String, to: String) async throws -> [HabitLog]
    func deleteLog(habitId: String, date: String) async throws
}
```

**TypeScript 비교:**
```typescript
interface HabitService {
    createHabit(habit: Habit): Promise<Habit>;
    fetchHabits(): Promise<Habit[]>;
    updateHabit(habit: Habit): Promise<void>;
    deleteHabit(habitId: string): Promise<void>;
}
```

### Protocol 채택 (Conformance)

Protocol을 채택한 타입은 **모든 메서드를 구현해야** 한다:

```swift
// HabitFlow/Sources/Services/FirestoreHabitService.swift
final class FirestoreHabitService: HabitServiceProtocol, @unchecked Sendable {
    func createHabit(_ habit: Habit) async throws -> Habit { /* 실제 Firestore 구현 */ }
    func fetchHabits() async throws -> [Habit] { /* ... */ }
    // ... 모든 메서드 구현 필수
}

// HabitFlow/Sources/Services/MockHabitService.swift
final class MockHabitService: HabitServiceProtocol, @unchecked Sendable {
    func createHabit(_ habit: Habit) async throws -> Habit { /* 메모리 기반 구현 */ }
    func fetchHabits() async throws -> [Habit] { /* ... */ }
    // ... 같은 프로토콜, 다른 구현
}
```

**TypeScript 비교:**
```typescript
class FirestoreHabitService implements HabitService {
    async createHabit(habit: Habit): Promise<Habit> { /* Firestore */ }
}

class MockHabitService implements HabitService {
    async createHabit(habit: Habit): Promise<Habit> { /* 메모리 */ }
}
```

### Protocol을 사용한 의존성 주입

Protocol의 진짜 가치는 **구현체를 교체**할 수 있다는 것:

```swift
// HabitFlow/Sources/ViewModels/HabitListViewModel.swift
final class HabitListViewModel {
    private let service: HabitServiceProtocol  // 프로토콜 타입으로 선언

    init(service: HabitServiceProtocol) {      // 어떤 구현체든 받을 수 있음
        self.service = service
    }
}

// 프로덕션
HabitListViewModel(service: FirestoreHabitService())

// 테스트
HabitListViewModel(service: MockHabitService())

// Preview
ContentView(service: MockHabitService())
```

### Swift의 Protocol이 interface보다 강력한 점

Swift Protocol은 **값 타입(struct)**도 채택할 수 있고, **연산 프로퍼티**, **기본 구현(default implementation)**, **associated type** 등을 지원한다:

```swift
// Identifiable - Swift 표준 프로토콜
protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}

// Habit이 채택
struct Habit: Identifiable {
    var id: String?  // Identifiable 요구사항 충족
}
```

HabitFlow에서 `Habit`이 채택한 프로토콜들:
- `Codable` -- JSON 변환
- `Identifiable` -- SwiftUI의 리스트/반복문에서 각 요소를 구분
- `Sendable` -- 동시성 안전
- `Hashable` -- Dictionary 키나 Set 요소로 사용 가능

---

## 4. async/await

### Swift의 async/await

JS와 매우 유사한 문법이지만 몇 가지 중요한 차이가 있다.

```swift
// HabitFlow/Sources/Services/HabitServiceProtocol.swift
func fetchHabits() async throws -> [Habit]
//                 ^^^^^ ^^^^^^
//                 비동기  에러 가능

// HabitFlow/Sources/ViewModels/HabitListViewModel.swift
func loadHabits() async {
    isLoading = true
    do {
        habits = try await service.fetchHabits()
        //       ^^^ ^^^^^
        //       에러처리 비동기 대기
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

**JS/TS 비교:**
```typescript
// JS - 거의 동일한 구조
async function loadHabits() {
    isLoading = true;
    try {
        habits = await service.fetchHabits();
    } catch (error) {
        errorMessage = error.message;
    }
    isLoading = false;
}
```

### 핵심 차이점

**1. `throws`가 타입 시그니처에 포함됨**

JS에서는 어떤 함수든 에러를 던질 수 있지만, Swift에서는 `throws`를 명시해야 한다:

```swift
// 에러를 던질 수 있는 함수
func createHabit(_ habit: Habit) async throws -> Habit

// 에러를 던지지 않는 함수 (do/catch로 에러를 내부 처리)
func loadHabits() async
```

**2. `try` 키워드 필수**

`throws` 함수를 호출할 때 반드시 `try`를 붙여야 한다:
```swift
let habits = try await service.fetchHabits()
//           ^^^
// "이 호출은 에러가 날 수 있음을 인지하고 있다"는 표시
```

**3. Task로 비동기 컨텍스트 시작**

```swift
// HabitFlow/Sources/Views/HabitList/HabitListView.swift
Button {
    showingForm = true
} label: {
    Image(systemName: "plus")
}

// 동기 컨텍스트에서 비동기 함수를 호출할 때 Task 사용
Button(role: .destructive) {
    if let id = habit.id {
        Task { await viewModel.deleteHabit(id) }
        //     ^^^^^ 비동기 함수를 동기 클로저 안에서 호출
    }
}
```

```typescript
// JS에서는 그냥 호출 가능 (top-level await 등)
button.onClick = async () => {
    await viewModel.deleteHabit(id);
}
```

**4. `.task` modifier -- SwiftUI의 비동기 시작점**

```swift
// HabitFlow/Sources/Views/Today/TodayView.swift
NavigationStack {
    // ... 뷰 내용
}
.task {
    await viewModel.loadToday()
}
```

이것은 React의 `useEffect`와 유사하다:
```typescript
// React 동등 코드
useEffect(() => {
    viewModel.loadToday();
}, []);
```

---

## 5. SwiftUI 기초

### View Protocol

SwiftUI에서 모든 화면은 `View` 프로토콜을 채택한 struct이다.

```swift
// HabitFlow/Sources/Views/ContentView.swift
struct ContentView: View {
    private let service: HabitServiceProtocol

    var body: some View {  // 필수 프로퍼티 -- 화면에 뭘 그릴지 정의
        TabView {
            TodayView(viewModel: TodayViewModel(service: service))
                .tabItem {
                    Label("오늘", systemImage: "checkmark.circle")
                }
            HabitListView(viewModel: HabitListViewModel(service: service))
                .tabItem {
                    Label("습관", systemImage: "list.bullet")
                }
        }
    }
}
```

**React 비교:**
```tsx
// React - JSX 반환
function ContentView({ service }) {
    return (
        <TabView>
            <TodayView viewModel={new TodayViewModel(service)} />
            <HabitListView viewModel={new HabitListViewModel(service)} />
        </TabView>
    );
}
```

### `some View`는 뭔가?

`some View`는 **Opaque Return Type**. "어떤 구체적인 View 타입을 반환하지만, 호출자는 구체 타입을 몰라도 된다"는 의미.

```swift
var body: some View {
    // 실제로는 TabView<TupleView<(ModifiedContent<..., ...>, ...)>> 같은 복잡한 타입
    // some View로 추상화
}
```

### Modifiers (수정자)

SwiftUI는 메서드 체이닝으로 뷰를 꾸민다:

```swift
// HabitFlow/Sources/Views/Today/TodayView.swift
Text(item.habit.name)
    .font(.body)                                          // 폰트
    .fontWeight(.medium)                                  // 굵기
    .strikethrough(item.isCompleted, color: .secondary)   // 취소선
    .foregroundStyle(item.isCompleted ? .secondary : .primary)  // 색상
```

```swift
// HabitFlow/Sources/Views/HabitList/HabitFormView.swift
Image(systemName: iconName)
    .font(.title3)
    .frame(width: 36, height: 36)
    .background(icon == iconName ? Color(hex: color).opacity(0.2) : .clear)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .onTapGesture { icon = iconName }
```

**CSS 비교:**
```css
/* CSS는 선언적이지만 별개의 파일 */
.habit-name {
    font-size: 16px;
    font-weight: 500;
    text-decoration: line-through;
    color: gray;
}
```

SwiftUI는 스타일이 코드에 직접 붙어있어서 컴포넌트와 스타일이 항상 함께 이동한다.

### 조건부 렌더링

```swift
// HabitFlow/Sources/Views/Today/TodayView.swift
Group {
    if viewModel.isLoading {
        ProgressView()
    } else if viewModel.todayHabits.isEmpty {
        emptyState
    } else {
        todayList
    }
}
```

**React 비교:**
```tsx
{isLoading ? (
    <Spinner />
) : todayHabits.length === 0 ? (
    <EmptyState />
) : (
    <TodayList />
)}
```

### 리스트와 반복

```swift
// HabitFlow/Sources/Views/HabitList/HabitListView.swift
List {
    ForEach(viewModel.habits) { habit in
        HabitRow(habit: habit)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    if let id = habit.id {
                        Task { await viewModel.deleteHabit(id) }
                    }
                } label: {
                    Label("삭제", systemImage: "trash")
                }
            }
    }
}
```

`ForEach`가 작동하려면 데이터가 `Identifiable` 프로토콜을 채택해야 한다 -- 그래서 `Habit`에 `Identifiable`이 있는 것.

### `@Environment`와 `dismiss`

```swift
// HabitFlow/Sources/Views/HabitList/HabitFormView.swift
@Environment(\.dismiss) private var dismiss

// 사용
Button("취소") { dismiss() }
```

SwiftUI의 Environment는 React의 Context와 유사한 개념으로, 뷰 계층 전체에서 값을 공유한다.

### Preview

```swift
// HabitFlow/Sources/Views/ContentView.swift
#Preview {
    ContentView(service: MockHabitService())
}
```

Xcode에서 실시간 프리뷰를 볼 수 있다. `MockHabitService`를 주입해서 실제 Firebase 없이 미리보기 가능.

---

## 6. @Observable & @State

### @Observable (iOS 17+)

`@Observable`은 클래스의 프로퍼티 변경을 SwiftUI가 자동으로 감지하게 해준다. React의 **상태 관리 라이브러리**와 비슷한 역할.

```swift
// HabitFlow/Sources/ViewModels/HabitListViewModel.swift
@MainActor
@Observable
final class HabitListViewModel {
    private(set) var habits: [Habit] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    // ...
    // habits, isLoading 등이 변경되면 이 ViewModel을 사용하는 View가 자동 리렌더링
}
```

**React 비교:**
```typescript
// React - 각 상태를 개별 useState로 관리
function useHabitListViewModel() {
    const [habits, setHabits] = useState<Habit[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [errorMessage, setErrorMessage] = useState<string | null>(null);

    // @Observable은 이 모든 것을 자동으로 처리
}
```

### `private(set)`

```swift
private(set) var habits: [Habit] = []
```

- 외부에서 **읽기**는 가능: `viewModel.habits`
- 외부에서 **쓰기**는 불가: `viewModel.habits = []` -- 컴파일 에러
- 클래스 내부에서는 자유롭게 수정 가능

TypeScript에는 정확히 대응하는 기능이 없지만, getter만 노출하는 것과 유사:
```typescript
class ViewModel {
    private _habits: Habit[] = [];
    get habits() { return this._habits; }
}
```

### @State

`@State`는 **View(struct)** 내부의 로컬 상태를 관리한다. React의 `useState`와 가장 유사.

```swift
// HabitFlow/Sources/Views/Today/TodayView.swift
struct TodayView: View {
    @State var viewModel: TodayViewModel       // ViewModel 바인딩
    @State private var memoTarget: TodayHabitItem?  // 로컬 UI 상태
    @State private var memoText = ""               // 로컬 UI 상태
}
```

```swift
// HabitFlow/Sources/Views/HabitList/HabitListView.swift
struct HabitListView: View {
    @State var viewModel: HabitListViewModel
    @State private var showingForm = false      // 시트 표시 여부
    @State private var editingHabit: Habit?     // 수정 중인 습관
}
```

**React 비교:**
```tsx
function TodayView() {
    const [memoTarget, setMemoTarget] = useState<TodayHabitItem | null>(null);
    const [memoText, setMemoText] = useState("");
}
```

### `$` (바인딩)

`$`는 **양방향 바인딩**을 생성한다. React의 controlled component와 비슷하지만 더 간결.

```swift
// HabitFlow/Sources/Views/HabitList/HabitFormView.swift
TextField("습관 이름", text: $name)
//                          ^^^^ name의 바인딩 -- 읽기 + 쓰기

Toggle("시간 설정", isOn: $hasTargetTime)
//                       ^^^^^^^^^^^^^^^^ hasTargetTime 양방향 바인딩

.sheet(isPresented: $showingForm) { ... }
//                  ^^^^^^^^^^^^^ showingForm이 true이면 시트 표시
```

**React 비교:**
```tsx
// React - value + onChange를 수동 연결
<input
    value={name}
    onChange={(e) => setName(e.target.value)}
/>

// SwiftUI - $name 하나로 끝
TextField("습관 이름", text: $name)
```

### @State를 사용한 ViewModel 초기화 패턴

```swift
// HabitFlow/Sources/Views/HabitList/HabitFormView.swift
init(habit: Habit? = nil, onSave: @escaping (Habit) -> Void) {
    self.existingHabit = habit
    self.onSave = onSave
    _name = State(initialValue: habit?.name ?? "")
    _icon = State(initialValue: habit?.icon ?? "star.fill")
    _color = State(initialValue: habit?.color ?? "#4CAF50")
    _schedule = State(initialValue: Set(habit?.schedule ?? [2, 3, 4, 5, 6]))
}
```

`_name`은 `@State` 프로퍼티의 **저장소(wrapper)**에 직접 접근하는 방법. init에서만 이렇게 초기화한다.

---

## 7. @MainActor

### Main Thread가 뭔가?

모든 UI 프레임워크는 **메인 스레드**에서만 UI를 업데이트할 수 있다. JS는 싱글 스레드라 이 문제가 없지만, Swift는 멀티 스레드이므로 주의가 필요.

```
JS/TS:     싱글 스레드 → UI 업데이트 걱정 없음
Swift:     멀티 스레드 → 잘못된 스레드에서 UI 업데이트하면 크래시
```

### @MainActor 사용

`@MainActor`는 "이 클래스의 모든 메서드는 메인 스레드에서 실행하라"는 표시.

```swift
// HabitFlow/Sources/ViewModels/HabitListViewModel.swift
@MainActor       // <-- 모든 프로퍼티/메서드가 메인 스레드에서 실행
@Observable
final class HabitListViewModel {
    private(set) var habits: [Habit] = []      // UI에 바인딩된 상태
    private(set) var isLoading = false         // UI에 바인딩된 상태

    func loadHabits() async {
        isLoading = true  // UI 업데이트 → 메인 스레드 필수
        do {
            habits = try await service.fetchHabits()  // 네트워크 호출
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false  // UI 업데이트
    }
}
```

```swift
// HabitFlow/Sources/Services/AuthService.swift
@MainActor
@Observable
final class AuthService {
    private(set) var userId: String?
    private(set) var isAuthenticated = false
    // isAuthenticated가 변경되면 UI가 반응 → 메인 스레드 필요
}
```

### 왜 HabitFlow의 모든 ViewModel에 @MainActor가 있나?

ViewModel은 **UI 상태를 소유**한다. `habits`, `isLoading`, `errorMessage` 등이 변경되면 SwiftUI가 뷰를 다시 그린다. 이 변경이 메인 스레드 밖에서 일어나면 경고 또는 크래시가 발생.

Swift 6에서는 이를 **컴파일 타임에 검사**한다 -- `@MainActor`를 빼면 컴파일 에러.

### 테스트에서의 @MainActor

```swift
// HabitFlowTests/TodayViewModelTests.swift
@Suite("TodayViewModel Tests")
@MainActor                      // <-- 테스트도 메인 스레드에서 실행
struct TodayViewModelTests {
    // ViewModel이 @MainActor이므로 테스트도 @MainActor여야 함
}
```

---

## 8. Sendable

### Sendable이란?

`Sendable`은 "이 타입의 값을 스레드 간에 안전하게 전달할 수 있다"는 것을 보장하는 프로토콜.

```swift
// HabitFlow/Sources/Models/Habit.swift
struct Habit: Codable, Identifiable, Sendable, Hashable {
    // struct + 모든 프로퍼티가 Sendable 타입 → 자동으로 Sendable
}
```

**JS 비교:**

JS는 싱글 스레드이므로 이 개념 자체가 없다. Swift에서 동시성(concurrency)이 엄격해진 것은 데이터 레이스(data race)를 컴파일 타임에 방지하기 위함.

### `@unchecked Sendable`

```swift
// HabitFlow/Sources/Services/MockHabitService.swift
final class MockHabitService: HabitServiceProtocol, @unchecked Sendable {
    private var habits: [Habit] = []
    private var logs: [String: [HabitLog]] = [:]
}

// HabitFlow/Sources/Services/FirestoreHabitService.swift
final class FirestoreHabitService: HabitServiceProtocol, @unchecked Sendable {
    private let db = Firestore.firestore()
}
```

`@unchecked Sendable`은 "나(개발자)가 이 타입이 스레드 안전하다고 보장한다"는 의미. 컴파일러 검사를 건너뛴다.

**왜 `@unchecked`를 사용하는가?**
- `MockHabitService`는 `var` 프로퍼티를 가지고 있어서 자동 Sendable이 불가
- `FirestoreHabitService`의 `Firestore` 객체가 Sendable이 아님
- 하지만 실제로는 `@MainActor`나 내부 동기화로 안전하게 사용하고 있음

### `@DocumentID`를 제거한 이유

Firebase의 `@DocumentID`는 Sendable을 채택하지 않은 property wrapper. Swift 6의 strict concurrency 모드에서 `@DocumentID`가 포함된 struct는 `Sendable`이 될 수 없다.

```swift
// 이렇게 쓰면 Swift 6에서 에러
import FirebaseFirestore

struct Habit: Sendable {
    @DocumentID var id: String?  // @DocumentID는 Sendable 아님 → 컴파일 에러!
}

// 해결: @DocumentID를 빼고 수동으로 id 할당
struct Habit: Sendable {
    var id: String?  // 일반 프로퍼티로 변경
}

// Firestore에서 문서 가져온 후 수동 할당
var habit = try? doc.data(as: Habit.self)
habit?.id = doc.documentID  // 수동으로 id 설정
```

### Protocol에서의 Sendable

```swift
// HabitFlow/Sources/Services/HabitServiceProtocol.swift
protocol HabitServiceProtocol: Sendable {
    // 이 프로토콜을 채택하는 모든 타입은 Sendable이어야 함
}
```

이렇게 하면 프로토콜을 채택한 서비스가 `async` 컨텍스트에서 안전하게 사용될 수 있다.

### project.yml의 Swift 6 설정

```yaml
# project.yml
settings:
  base:
    SWIFT_VERSION: "6.0"
```

Swift 6는 strict concurrency가 기본. Swift 5에서는 경고였던 것들이 Swift 6에서는 에러가 된다.

---

## 9. MVVM 패턴

### MVVM이란?

**Model - View - ViewModel** 아키텍처. SwiftUI에서 가장 널리 쓰이는 패턴.

```
┌─────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────┐
│  Model  │ ←── │   Service    │ ←── │   ViewModel     │ ←── │   View   │
│         │     │              │     │                 │     │          │
│ Habit   │     │ Firestore    │     │ HabitList       │     │ HabitList│
│ HabitLog│     │ HabitService │     │ ViewModel       │     │ View     │
└─────────┘     └──────────────┘     └─────────────────┘     └──────────┘
  데이터 구조      데이터 CRUD         상태 + 비즈니스 로직      화면 렌더링
```

### HabitFlow의 MVVM 구조

**Model** -- 순수한 데이터 구조:
```swift
// struct, Codable, 비즈니스 로직 없음
struct Habit: Codable, Identifiable, Sendable, Hashable { ... }
struct HabitLog: Codable, Identifiable, Sendable { ... }
```

**Service** -- 데이터 접근 레이어:
```swift
// Protocol로 추상화 → Mock/실제 구현 교체 가능
protocol HabitServiceProtocol: Sendable { ... }
class FirestoreHabitService: HabitServiceProtocol { ... }
class MockHabitService: HabitServiceProtocol { ... }
```

**ViewModel** -- 뷰의 상태 + 비즈니스 로직:
```swift
// HabitFlow/Sources/ViewModels/TodayViewModel.swift
@MainActor
@Observable
final class TodayViewModel {
    private(set) var todayHabits: [TodayHabitItem] = []  // 상태
    private(set) var isLoading = false                    // 상태

    var completionRate: Double {                          // 계산된 상태
        guard !todayHabits.isEmpty else { return 0 }
        let completed = todayHabits.filter(\.isCompleted).count
        return Double(completed) / Double(todayHabits.count)
    }

    func loadToday() async { ... }           // 비즈니스 로직
    func toggleCheck(_ item: ...) async { ... }  // 비즈니스 로직
}
```

**View** -- UI만 담당:
```swift
// HabitFlow/Sources/Views/Today/TodayView.swift
struct TodayView: View {
    @State var viewModel: TodayViewModel  // ViewModel 소유

    var body: some View {
        // viewModel의 상태를 읽어서 UI 렌더링
        // 사용자 액션을 viewModel 메서드로 전달
    }
}
```

**React 비교:**
```
React:   Component = View + (Hook = ViewModel)
SwiftUI: View (struct) + ViewModel (class)

React에서 커스텀 Hook으로 로직을 분리하는 것과 유사
```

### 의존성 주입 흐름

```swift
// HabitFlow/Sources/Views/ContentView.swift
struct ContentView: View {
    private let service: HabitServiceProtocol

    init(service: HabitServiceProtocol = FirestoreHabitService()) {
        self.service = service
    }

    var body: some View {
        TabView {
            // Service → ViewModel → View로 주입
            TodayView(viewModel: TodayViewModel(service: service))
            HabitListView(viewModel: HabitListViewModel(service: service))
        }
    }
}
```

---

## 10. Swift Testing

### XCTest vs Swift Testing

Swift 5.x까지는 `XCTest`를 사용했지만, Swift Testing은 더 현대적인 테스트 프레임워크.

| XCTest (구) | Swift Testing (신) |
|---|---|
| `import XCTest` | `import Testing` |
| `class MyTests: XCTestCase` | `struct MyTests` |
| `func testSomething()` | `@Test func something()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertThrowsError` | `#expect(throws:)` |

### @Test와 @Suite

```swift
// HabitFlowTests/HabitServiceTests.swift
import Testing
@testable import HabitFlow  // 테스트 대상 모듈의 internal 접근

@Suite("HabitService Tests")    // 테스트 그룹 (describe와 유사)
struct HabitServiceTests {
    let service = MockHabitService()  // 각 테스트마다 새 인스턴스 (struct이므로)

    @Test("습관 생성 시 ID가 할당된다")    // 테스트 설명
    func test_createHabit_assignsId() async throws {
        let habit = Habit(name: "러닝", icon: "figure.run", color: "#4CAF50")
        let created = try await service.createHabit(habit)
        #expect(created.id != nil)      // assertion
        #expect(created.name == "러닝") // assertion
    }
}
```

**Jest 비교:**
```typescript
describe("HabitService Tests", () => {
    const service = new MockHabitService();

    test("습관 생성 시 ID가 할당된다", async () => {
        const habit = { name: "러닝", icon: "figure.run", color: "#4CAF50" };
        const created = await service.createHabit(habit);
        expect(created.id).not.toBeNull();
        expect(created.name).toBe("러닝");
    });
});
```

### #expect -- assertion 매크로

```swift
// 기본 비교
#expect(created.id != nil)
#expect(created.name == "러닝")
#expect(habits.count == 1)

// 컬렉션 검사
#expect(habits.contains { $0.name == "독서" })
#expect(!habits.contains { $0.name == "명상" })
#expect(logs.isEmpty)

// 에러 검증
// HabitFlowTests/HabitServiceTests.swift
@Test("존재하지 않는 습관 수정 시 에러가 발생한다")
func test_updateHabit_notFound_throws() async throws {
    let ghost = Habit(id: "nonexistent", name: "없는 습관")
    await #expect(throws: HabitServiceError.self) {
        try await service.updateHabit(ghost)
    }
}
```

### 테스트에서의 async/await

```swift
// HabitFlowTests/TodayViewModelTests.swift
@Suite("TodayViewModel Tests")
@MainActor  // ViewModel이 @MainActor이므로 테스트도 동일하게
struct TodayViewModelTests {
    let service = MockHabitService()

    @Test("체크하면 로그가 생성된다")
    func test_toggleCheck_createsLog() async {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        _ = try? await service.createHabit(Habit(name: "러닝", schedule: [todayWeekday]))

        let vm = makeViewModel()
        await vm.loadToday()
        await vm.toggleCheck(vm.todayHabits[0])
        #expect(vm.todayHabits[0].isCompleted)
    }
}
```

### `@testable import`

```swift
@testable import HabitFlow
```

`@testable`은 모듈의 `internal` 접근 수준을 테스트에서 `public`처럼 사용할 수 있게 해준다. `private`은 여전히 접근 불가.

---

## 11. Firebase + SwiftUI

### FirebaseApp.configure()

```swift
// HabitFlow/Sources/HabitFlowApp.swift
import SwiftUI
import FirebaseCore

@main
struct HabitFlowApp: App {
    @State private var authService = AuthService()

    init() {
        FirebaseApp.configure()  // Firebase 초기화 -- 앱 시작 시 1번만 호출
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)  // 전체 앱에 AuthService 공유
                .task {
                    authService.restoreSession()
                    if !authService.isAuthenticated {
                        try? await authService.signInAnonymously()
                    }
                }
        }
    }
}
```

**JS Firebase 비교:**
```typescript
// JS
import { initializeApp } from "firebase/app";
const app = initializeApp(firebaseConfig);
```

Swift에서는 `GoogleService-Info.plist` 파일이 프로젝트에 포함되어 있으면 `FirebaseApp.configure()`가 자동으로 설정을 읽는다.

### Anonymous Auth

```swift
// HabitFlow/Sources/Services/AuthService.swift
func signInAnonymously() async throws {
    let result = try await Auth.auth().signInAnonymously()
    userId = result.user.uid
    isAuthenticated = true
}

func restoreSession() {
    if let user = Auth.auth().currentUser {
        userId = user.uid
        isAuthenticated = true
    }
}
```

앱 시작 시 흐름:
1. `restoreSession()` -- 이전 세션이 있으면 복원
2. 없으면 `signInAnonymously()` -- 익명 계정 자동 생성
3. 이후 모든 Firestore 요청에 `userId`가 사용됨

### Firestore CRUD

```swift
// HabitFlow/Sources/Services/FirestoreHabitService.swift

// 컬렉션 경로: users/{userId}/habits
private var habitsCollection: CollectionReference {
    db.collection("users").document(userId).collection("habits")
}

// Create
func createHabit(_ habit: Habit) async throws -> Habit {
    let ref = try habitsCollection.addDocument(from: habit)
    // Codable 자동 변환: Habit struct → Firestore document
    var created = habit
    created.id = ref.documentID
    return created
}

// Read
func fetchHabits() async throws -> [Habit] {
    let snapshot = try await habitsCollection
        .whereField("isArchived", isEqualTo: false)  // 쿼리 필터
        .getDocuments()
    return snapshot.documents.compactMap { doc in
        var habit = try? doc.data(as: Habit.self)  // Firestore → Habit
        habit?.id = doc.documentID
        return habit
    }
}

// Update
func updateHabit(_ habit: Habit) async throws {
    guard let id = habit.id else { throw HabitServiceError.notFound }
    try habitsCollection.document(id).setData(from: habit, merge: true)
    // merge: true → 전달된 필드만 업데이트, 나머지 유지
}

// Delete (하위 컬렉션 포함)
func deleteHabit(_ habitId: String) async throws {
    // Firestore는 하위 컬렉션을 자동 삭제하지 않음 → 수동 삭제
    let logSnapshots = try await logsCollection(habitId: habitId).getDocuments()
    for doc in logSnapshots.documents {
        try await doc.reference.delete()
    }
    try await habitsCollection.document(habitId).delete()
}
```

**JS Firestore 비교:**
```typescript
// JS
const ref = await addDoc(collection(db, "users", userId, "habits"), habit);
const snapshot = await getDocs(query(habitsRef, where("isArchived", "==", false)));
```

### `compactMap` -- nil 필터링

```swift
snapshot.documents.compactMap { doc in
    var habit = try? doc.data(as: Habit.self)  // 실패하면 nil
    habit?.id = doc.documentID
    return habit  // nil인 것은 자동 제외
}
```

`compactMap`은 `map` + nil 필터. JS의 `.map().filter(Boolean)`과 동일:
```typescript
// JS 동등 코드
snapshot.docs
    .map(doc => { try { return { ...doc.data(), id: doc.id } } catch { return null } })
    .filter(Boolean)
```

---

## 12. 프로젝트 구조

### XcodeGen과 project.yml

HabitFlow는 **XcodeGen**을 사용하여 `project.yml`에서 Xcode 프로젝트 파일(`.xcodeproj`)을 생성한다.

```yaml
# project.yml
name: HabitFlow
options:
  bundleIdPrefix: com.ethankim
  deploymentTarget:
    iOS: "17.0"                    # 최소 지원 iOS 버전
  generateEmptyDirectories: true

packages:
  firebase-ios-sdk:
    url: https://github.com/firebase/firebase-ios-sdk.git
    from: "11.0.0"                 # SPM 패키지 의존성

targets:
  HabitFlow:
    type: application
    platform: iOS
    sources:
      - path: HabitFlow/Sources    # 소스 코드 디렉토리
      - path: HabitFlow/Resources  # 리소스 (Assets, plist 등)
    settings:
      base:
        SWIFT_VERSION: "6.0"       # Swift 6 사용
    dependencies:
      - package: firebase-ios-sdk
        product: FirebaseAuth
      - package: firebase-ios-sdk
        product: FirebaseFirestore

  HabitFlowTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - path: HabitFlowTests
    dependencies:
      - target: HabitFlow          # 테스트 대상
```

**왜 XcodeGen을 사용하는가?**
- `.xcodeproj`는 XML 기반의 복잡한 파일 → Git 충돌이 빈번
- `project.yml`은 사람이 읽을 수 있는 YAML → 리뷰 & 머지가 쉬움
- 팀원이 `xcodegen generate`만 실행하면 프로젝트 파일 생성

**JS 생태계 비교:**
```
project.yml  ≈  package.json + webpack.config.js
XcodeGen     ≈  create-react-app의 eject 없는 설정
SPM          ≈  npm/yarn
```

### SPM (Swift Package Manager)

Swift의 공식 패키지 매니저. `project.yml`의 `packages` 섹션에서 의존성을 선언.

```yaml
packages:
  firebase-ios-sdk:
    url: https://github.com/firebase/firebase-ios-sdk.git
    from: "11.0.0"   # 11.0.0 이상, 다음 메이저 버전 미만
```

**npm 비교:**
```json
{
    "dependencies": {
        "firebase": "^11.0.0"
    }
}
```

### Asset Catalog

```yaml
settings:
  base:
    ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
```

Asset Catalog(`Assets.xcassets`)은 앱 아이콘, 색상, 이미지 등을 관리하는 Xcode 전용 시스템. JSON + 폴더 구조로 되어 있다.

### 디렉토리 구조

```
HabitFlow/
├── project.yml                    # XcodeGen 설정
├── HabitFlow/
│   ├── Sources/
│   │   ├── HabitFlowApp.swift     # 앱 진입점 (@main)
│   │   ├── Models/
│   │   │   ├── Habit.swift        # 데이터 모델
│   │   │   └── HabitLog.swift     # 데이터 모델
│   │   ├── Services/
│   │   │   ├── HabitServiceProtocol.swift   # 서비스 인터페이스
│   │   │   ├── FirestoreHabitService.swift  # 실제 구현
│   │   │   ├── MockHabitService.swift       # 테스트용 Mock
│   │   │   └── AuthService.swift            # 인증
│   │   ├── ViewModels/
│   │   │   ├── HabitListViewModel.swift     # 습관 목록 VM
│   │   │   └── TodayViewModel.swift         # 오늘 화면 VM
│   │   └── Views/
│   │       ├── ContentView.swift            # 루트 뷰 (TabView)
│   │       ├── Today/
│   │       │   └── TodayView.swift          # 오늘 탭
│   │       └── HabitList/
│   │           ├── HabitListView.swift       # 습관 목록 탭
│   │           └── HabitFormView.swift       # 습관 생성/수정 폼
│   └── Resources/
│       └── Assets.xcassets/                 # 앱 아이콘, 색상 등
├── HabitFlowTests/
│   ├── HabitServiceTests.swift              # 서비스 테스트
│   └── TodayViewModelTests.swift            # ViewModel 테스트
└── docs/
    └── Swift-Study-Guide.md                 # 이 문서
```

### `@main`과 앱 진입점

```swift
// HabitFlow/Sources/HabitFlowApp.swift
@main                          // "여기가 앱의 시작점이다"
struct HabitFlowApp: App {     // App 프로토콜 채택
    var body: some Scene {     // Scene을 반환 (윈도우 단위)
        WindowGroup {
            ContentView()      // 루트 뷰
        }
    }
}
```

**JS 비교:**
```typescript
// React
ReactDOM.createRoot(document.getElementById('root'))
    .render(<App />);

// Next.js
export default function App() { ... }
```

---

## 부록: Swift 문법 치트시트

### 자주 쓰는 타입 변환

| JS/TS | Swift |
|-------|-------|
| `array.map(x => ...)` | `array.map { x in ... }` |
| `array.filter(x => ...)` | `array.filter { x in ... }` |
| `array.find(x => ...)` | `array.first(where: { x in ... })` |
| `array.findIndex(x => ...)` | `array.firstIndex(where: { x in ... })` |
| `array.includes(x)` | `array.contains(x)` |
| `array.some(x => ...)` | `array.contains(where: { x in ... })` |
| `array.sort((a, b) => ...)` | `array.sorted { a, b in ... }` |
| `[...array1, ...array2]` | `array1 + array2` |
| `Object.keys(obj)` | `dictionary.keys` |
| `obj[key] ?? default` | `dictionary[key, default: value]` |
| `str.split(":")` | `str.split(separator: ":")` |
| `str.trim()` | `str.trimmingCharacters(in: .whitespaces)` |
| `String(num)` | `String(num)` |
| `parseInt(str)` | `Int(str)` (반환값이 Optional) |

### 클로저 축약

```swift
// 풀 버전
habits.filter { (habit: Habit) -> Bool in
    return !habit.isArchived
}

// 타입 추론 + return 생략
habits.filter { habit in !habit.isArchived }

// 축약 인자 이름 ($0, $1, ...)
habits.filter { !$0.isArchived }

// KeyPath 축약 (프로퍼티만 접근할 때)
todayHabits.filter(\.isCompleted)
```

### guard vs if let 사용 가이드

```swift
// guard -- 조건 불충족 시 조기 반환 (함수 나머지에서 값 사용)
func toggleCheck(_ item: TodayHabitItem) async {
    guard let habitId = item.habit.id else { return }
    // 여기부터 habitId는 non-optional
    try await service.deleteLog(habitId: habitId, date: todayString)
}

// if let -- 조건 충족 시에만 실행 (좁은 범위에서 값 사용)
if let time = item.habit.targetTime {
    Text(time)
}
```

**경험 법칙:**
- 실패하면 함수를 나가야 한다 → `guard let`
- 성공했을 때만 뭔가 추가로 보여준다 → `if let`
