# 테스트 가능 구조로의 리팩터링

대상이 테스트 불가능한 구조면, **테스트 작성 전에** 동작을 보존하는 최소 리팩터링을 제안하고 사용자 동의를 받아 적용한다. 제안에는 항상 다음을 포함한다.

1. **왜** 테스트가 막히는지 (어떤 의존성이 결정론/격리를 깨는지)
2. **어떤 방향**으로 바꿀지 (구체적 패턴)
3. **동작 보존** 확인 (관찰 가능한 동작은 그대로)

리팩터링은 테스트화에 필요한 범위로 한정한다. 무관한 구조 개선은 하지 않는다.

---

## A. `ServiceLocator` / 정적 컨테이너 제거 → 생성자 주입

### 문제
타입 내부에서 `ServiceLocator.Current.GetInstance<T>()`(또는 정적 컨테이너/싱글턴)로 의존성을 끌어오면, 테스트에서 가짜 구현으로 바꿔 끼울 수 없다. 전역 상태라 테스트 간 격리도 깨진다.

### 방향
의존성을 **생성자 매개변수**로 받아 필드에 보관한다. 인터페이스 타입으로 받으면 테스트에서 NSubstitute Mock을 주입할 수 있다.

### 전 / 후

```csharp
// 전 — 테스트 불가: 내부에서 전역 컨테이너 조회
public class ThumbnailViewModel
{
    public void Load()
    {
        var repo = ServiceLocator.Current.GetInstance<IFrameRepository>();
        Frames = repo.GetFrames(_caseId);
    }
}
```

```csharp
// 후 — 생성자 주입
public class ThumbnailViewModel
{
    private readonly IFrameRepository _repo;

    public ThumbnailViewModel(IFrameRepository repo)
    {
        _repo = repo;
    }

    public void Load()
    {
        Frames = _repo.GetFrames(_caseId);
    }
}
```

```csharp
// 테스트
var repo = Substitute.For<IFrameRepository>();
repo.GetFrames(42).Returns([frameA, frameB]);

var sut = new ThumbnailViewModel(repo);
sut.Load();

sut.Frames.Should().Equal(frameA, frameB);
```

### 주의
- DI 컨테이너(Unity 등) 등록은 이미 인터페이스→구현으로 돼 있는 경우가 많다. 호출부가 컨테이너로 생성되면, 생성자 인자가 늘어도 컨테이너가 자동 주입하므로 **호출부 변경이 거의 없다**. 직접 `new`로 만들던 곳만 인자를 넘기도록 고친다.
- 의존성이 인터페이스가 아니면(구체 클래스) 먼저 인터페이스를 추출할지 검토한다. 단, 이미 테스트하기 쉬운 순수 데이터/계산 클래스라면 그대로 주입해도 된다.

---

## B. UI 의존성 → 인터페이스 추상화

### 문제
`MessageBox.Show(...)`, 다이얼로그, `Dispatcher`, 또는 "UI 스레드에서만 동작하는 서비스"를 직접 호출하면, 테스트가 UI를 띄우려다 멈추거나 환경에 의존한다.

### 방향
UI 상호작용을 **인터페이스**로 추상화하고 생성자로 주입한다. 테스트는 그 인터페이스의 Mock으로 "어떤 메시지를 띄웠는지"·"확인을 눌렀을 때 어떻게 동작하는지"를 검증한다.

> **금지:** Mock을 만들려고 대상의 메서드를 `virtual`로 바꾸고 서브클래싱으로 가로채는 방식은 쓰지 않는다. 동작을 인터페이스 경계로 분리하는 것이 옳다.

### 전 / 후

```csharp
// 전 — 테스트 불가: MessageBox 직접 호출
public class DeleteEvidenceCommand
{
    public void Execute()
    {
        if (MessageBox.Show("삭제하시겠습니까?", "확인", MessageBoxButton.YesNo) != MessageBoxResult.Yes)
            return;

        _repo.Delete(_id);
    }
}
```

```csharp
// 후 — UI 상호작용을 인터페이스로
public interface IUserDialog
{
    bool Confirm(string message);
    void ShowError(string message);
}

public class DeleteEvidenceCommand
{
    private readonly IUserDialog _dialog;
    private readonly IEvidenceRepository _repo;

    public DeleteEvidenceCommand(IUserDialog dialog, IEvidenceRepository repo)
    {
        _dialog = dialog;
        _repo = repo;
    }

    public void Execute()
    {
        if (!_dialog.Confirm("삭제하시겠습니까?"))
            return;

        _repo.Delete(_id);
    }
}

// 실제 구현(프로덕션) — UI 프로젝트에 둔다
internal sealed class MessageBoxUserDialog : IUserDialog
{
    public bool Confirm(string message)
        => MessageBox.Show(message, "확인", MessageBoxButton.YesNo) == MessageBoxResult.Yes;

    public void ShowError(string message)
        => MessageBox.Show(message, "오류", MessageBoxButton.OK, MessageBoxImage.Error);
}
```

```csharp
// 테스트 — 두 분기를 모두 검증
[Fact]
public void Execute_WhenUserConfirms_DeletesEvidence()
{
    var dialog = Substitute.For<IUserDialog>();
    dialog.Confirm(Arg.Any<string>()).Returns(true);   // 사용자가 "예"
    var repo = Substitute.For<IEvidenceRepository>();

    new DeleteEvidenceCommand(dialog, repo).Execute();

    repo.Received(1).Delete(Arg.Any<int>());
}

[Fact]
public void Execute_WhenUserCancels_DoesNotDelete()
{
    var dialog = Substitute.For<IUserDialog>();
    dialog.Confirm(Arg.Any<string>()).Returns(false);  // 사용자가 "아니오"
    var repo = Substitute.For<IEvidenceRepository>();

    new DeleteEvidenceCommand(dialog, repo).Execute();

    repo.DidNotReceive().Delete(Arg.Any<int>());
}
```

### 이미 인터페이스화된 서비스가 UI에서 동작하는 경우
대상이 쓰는 서비스가 인터페이스(`IModalService` 등)로 주입되고 있으면 추가 추상화 없이 그 인터페이스를 Mock하면 된다. 저장소에는 이런 모달/다이얼로그 서비스 추상화가 이미 존재할 수 있으니 **새로 만들기 전에 기존 인터페이스를 찾는다**.

---

## C. 그 밖의 결정론 깨짐

| 의존 | 추상화 방향 |
|---|---|
| `DateTime.Now` / `Stopwatch` | `IClock`/시간 제공자 주입 (또는 인자로 시각 전달) |
| `new Random()` | 시드 주입 또는 `IRandom` 추상화 |
| 파일시스템(`File`, `Directory`) | `IFileSystem` 류 추상화 주입 |
| DB/네트워크 | 리포지토리/클라이언트 인터페이스 주입 |
| `static` 가변 상태 | 인스턴스 상태로 이동 후 주입 |

핵심은 같다: **부수효과·비결정성을 경계 인터페이스로 밀어내고 생성자로 주입**한다. 그러면 순수 로직만 결정론적으로 테스트된다.
