# 실제 연결을 위한 리팩터링

통합 대상이 **실제 협력자를 연결하고 자원을 임시로 격리**할 수 없는 구조면, **테스트 작성 전에** 동작을 보존하는 최소 리팩터링을 제안하고 사용자 동의를 받아 적용한다. 제안에는 항상 다음을 포함한다.

1. **왜** 실제 연결/격리가 막히는지
2. **어떤 방향**으로 바꿀지 (구체적 패턴)
3. **동작 보존** 확인 (관찰 가능한 동작은 그대로)

## 통합 테스트의 seam — 실제를 꽂는 자리

리팩터링의 본질은 **의존성을 교체 가능한 경계(seam)로 만드는 것**이다. 단위 테스트는 이 자리에 Mock을 꽂지만, **통합 테스트는 같은 자리에 실제 구현을 꽂는다.** 따라서:

- 통합하려는 협력자(리포지토리·디코더·파이프라인 단계 등)는 **실제 구현을 주입**한다 — 그게 검증 목적이므로 Mock하지 않는다.
- **파일시스템·DB는 검증 대상 그 자체**이므로 가짜로 대체하지 않는다. 대신 **임시 경로/임시 DB로 격리**해 재현성과 정리를 확보한다(→ `references/conventions.md` §7).
- **외부 네트워크·실시간 시계·난수**처럼 통합 대상이 아니면서 재현성을 깨는 경계만 추상화해 고정한다.

즉, 아래 A·B는 두 종류의 테스트 모두에 필요한 리팩터링이지만(전역 상태·UI 직접 호출 제거), 채워 넣는 것은 통합에서는 **실제 구현**이다.

---

## A. 자원 경로 하드코딩 제거 → 주입 가능하게

### 문제
DB 경로·작업 디렉터리·출력 경로가 내부에 하드코딩되어 있으면, 테스트에서 임시 위치로 바꿔 끼울 수 없어 실제 운영 자원을 더럽히거나 테스트 간 격리가 깨진다.

### 방향
경로/자원 위치를 **생성자 또는 팩토리 인자**로 받게 한다. 그러면 테스트는 `Path.GetTempPath()` 아래 고유 경로를 주입해 격리하고, 끝나면 삭제한다.

```csharp
// 전 — 테스트 불가: 고정 경로
public class CaseRepository
{
    private readonly string _dbPath = @"C:\ProgramData\MD\case.mcf";  // 하드코딩
    public CaseRepository() { /* _dbPath로 연결 */ }
}
```

```csharp
// 후 — 경로 주입(팩토리)
public class CaseRepository : IDisposable
{
    private readonly string _dbPath;
    private CaseRepository(string dbPath) { _dbPath = dbPath; /* 연결 */ }

    public static CaseRepository CreateAt(string dbPath) => new(dbPath);   // 테스트는 임시 경로 주입
    public static CaseRepository CreateDefault() => new(DefaultPath);      // 운영 기본값
    public void Dispose() { /* 연결 해제 */ }
}
```

```csharp
// 통합 테스트 — 실제 SQLite를 임시 경로에 만들고 정리
var dbPath = Path.Combine(Path.GetTempPath(), $"case_{Guid.NewGuid():N}.mcf");
using var repo = CaseRepository.CreateAt(dbPath);   // 실제 구현
// ... 검증 ...
// Dispose 후 File.Delete(dbPath)
```

---

## B. `ServiceLocator` / 정적 컨테이너 제거 → 생성자 주입

### 문제
흐름 안의 타입이 `ServiceLocator.Current.GetInstance<T>()`(또는 정적 싱글턴)로 협력자를 끌어오면, 통합 테스트에서 **실제 협력자들을 원하는 구성으로 조립**할 수 없고 전역 상태로 테스트 간 격리가 깨진다.

### 방향
협력자를 **생성자 매개변수**로 받게 한다. 통합 테스트는 여기에 (Mock이 아니라) **실제 구현**을 주입해 흐름을 조립한다.

```csharp
// 전 — 전역 조회
public class RecoveryPipeline
{
    public Result Run(string path)
    {
        var decoder = ServiceLocator.Current.GetInstance<IDecoder>();
        var writer  = ServiceLocator.Current.GetInstance<IFrameWriter>();
        // ...
    }
}
```

```csharp
// 후 — 생성자 주입
public class RecoveryPipeline
{
    private readonly IDecoder _decoder;
    private readonly IFrameWriter _writer;
    public RecoveryPipeline(IDecoder decoder, IFrameWriter writer)
    {
        _decoder = decoder;
        _writer = writer;
    }
    public Result Run(string path) { /* _decoder, _writer 사용 */ }
}

// 통합 테스트 — 실제 구현으로 조립
var pipeline = new RecoveryPipeline(new FfmpegDecoder(), new SqliteFrameWriter(tempDb));
```

> DI 컨테이너(Unity 등)가 인터페이스→구현을 등록하고 있으면, 운영 호출부는 컨테이너가 자동 조립하므로 변경이 거의 없다. 직접 `new`로 만들던 곳만 인자를 넘기게 고친다.

---

## C. UI / 외부·비결정 경계 → 인터페이스 추상화

### 문제
흐름에 `MessageBox.Show(...)`·다이얼로그·`Dispatcher`가 끼어 있거나, 외부 네트워크·`DateTime.Now`·`new Random()`이 결과를 좌우하면 통합 테스트가 멈추거나 재현 불가능해진다.

### 방향
이런 **외부·비결정·UI 경계**를 인터페이스로 추상화해 생성자로 주입한다. 통합 테스트에서는 이 경계만 고정(테스트용 구현/Mock)하고, **나머지 협력자와 자원(파일·DB)은 실제로** 쓴다.

> **금지:** Mock을 만들려고 대상의 메서드를 `virtual`로 바꾸고 서브클래싱으로 가로채는 방식은 쓰지 않는다. 동작을 인터페이스 경계로 분리하는 것이 옳다.

```csharp
// UI 상호작용을 인터페이스로
public interface IUserDialog
{
    bool Confirm(string message);
    void ShowError(string message);
}

// 비결정 경계도 동일하게: IClock, IRandom 등으로 주입해 통합 테스트에서 고정
```

| 경계 | 통합 테스트에서의 처리 |
|---|---|
| `MessageBox`/다이얼로그/`Dispatcher` | 인터페이스로 추상화 → 테스트용 구현 주입(자동 확인 등) |
| 외부 네트워크/서드파티 API | 인터페이스로 추상화 → 고정 응답(통합 대상이 아니므로) |
| `DateTime.Now` / `Stopwatch` | `IClock` 주입해 시각 고정 |
| `new Random()` | 시드 주입 또는 `IRandom` 추상화 |
| **파일시스템 / DB** | **추상화하지 않는다 — 실제로 쓰되 임시 경로/임시 DB로 격리**(검증 대상) |
| `static` 가변 상태 | 인스턴스 상태로 이동 후 주입 |

핵심: **통합하려는 협력자·자원은 실제로 연결하고, 통합 대상이 아닌 외부·비결정 경계만 seam으로 분리해 고정**한다. 그래야 "실제 연동"을 검증하면서도 테스트가 재현 가능해진다.
