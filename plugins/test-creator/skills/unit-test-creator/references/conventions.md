# 테스트 프로젝트 규약 (MD-VIDEO 저장소)

> 이 문서는 저장소의 **실제** 테스트 프로젝트들을 분석해 정리한 관례다.
> 단, **`CLAUDE.md`의 지침이 항상 우선**한다. 이 문서와 충돌하면 `CLAUDE.md`를 따른다.

## 목차
1. 위치와 폴더 구조
2. 명명 규칙
3. csproj 템플릿
4. 사용 라이브러리와 버전
5. `InternalsVisibleTo` (internal 대상 접근)
6. 솔루션 등록
7. 테스트 코드 작성 패턴
8. TestHelpers / TestData

---

## 1. 위치와 폴더 구조

테스트는 저장소 루트의 **`Tests/`** 아래에 **원본 프로젝트의 폴더 구조를 미러링**해 배치한다.

```
<원본 경로>                         →  Tests/<동일 경로>/<프로젝트>.Tests/
Modules/MEDIA.Decoder/             →  Tests/Modules/MEDIA.Decoder.Tests/
MD.MEDIA.Common/MD.VideoRepair/    →  Tests/MD.MEDIA.Common/MD.VideoRepair.Tests/
MD.MEDIA.VideoAnalysis/MEDIA.VideoAnalysis.Core/
                                   →  Tests/MD.MEDIA.VideoAnalysis/MEDIA.VideoAnalysis.Core.Tests/
```

테스트 프로젝트 **내부**의 폴더는 원본의 **네임스페이스 구조**를 미러링한다.

```
Tests/MD.MEDIA.Common/MD.VideoRepair.Tests/
  MD.VideoRepair.Tests.csproj
  Codec/
    BitReaderTests.cs           # MD.VideoRepair.Codec.BitReader 대응
  Container/
  Infra/
```

## 2. 명명 규칙

- **프로젝트**: `<대상프로젝트>.Tests` (예: `MD.VideoRepair.Tests`). 단위 테스트와 분리된 통합 테스트는 `.IntegrationTests`.
- **네임스페이스**: `<RootNamespace>.<원본 상대 경로>` (원본 네임스페이스를 그대로 따라감).
- **클래스**: `<대상클래스>Tests` (예: `BitReaderTests`).
- **메서드**: `Method_Scenario_ExpectedResult`.
  - 값 반환: `GetConverter_KnownType_ReturnsMatchingConverter`, `Convert_Null_Null`
  - 예외 발생: `Extract_WithNullInput_ThrowsArgumentNullException` (결과를 `ThrowsXxx`로)

## 3. csproj 템플릿

### 기본 (TFM `net9.0`, 모킹 없음)

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
    <RootNamespace>대상프로젝트.Tests</RootNamespace>
    <AssemblyName>대상프로젝트.Tests</AssemblyName>
    <GenerateAssemblyInfo>true</GenerateAssemblyInfo>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />
    <PackageReference Include="xunit" Version="2.9.2" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.8.2">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="AwesomeAssertions" Version="8.0.2" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\상대경로\대상프로젝트.csproj" />
  </ItemGroup>

</Project>
```

### WPF / Windows 전용 API 의존 프로젝트

기본 TFM은 `net9.0`이다. **대상이 WPF 타입이나 Windows 전용 API(예: `System.Windows`, WinForms, Win32 P/Invoke)에 의존할 때만** `TargetFramework`를 `net9.0-windows`로 바꾼다. 그 외에는 `net9.0`을 유지한다(불필요하게 Windows에 묶지 않는다). WPF 타입을 노출하면 `UseWPF` 등도 함께 둔다.

```xml
    <TargetFramework>net9.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Platforms>AnyCPU;x64</Platforms>
    <PlatformTarget>x64</PlatformTarget>
```

> 판단 기준: 대상 프로젝트(원본)의 TFM을 따라간다. 원본이 `net9.0-windows`이거나 WPF/Windows 전용 타입을 테스트에서 직접 다뤄야 하면 `net9.0-windows`, 아니면 `net9.0`.

### 모킹이 필요할 때

`ItemGroup`에 NSubstitute를 추가한다(필요한 프로젝트만).

```xml
    <PackageReference Include="NSubstitute" Version="5.3.0" />
```

## 4. 사용 라이브러리와 버전

| 라이브러리 | 버전 | 사용 |
|---|---|---|
| xunit | 2.9.2 | 테스트 프레임워크 |
| Microsoft.NET.Test.Sdk | 17.12.0 | 러너 |
| xunit.runner.visualstudio | 2.8.2 | VS 통합 |
| **AwesomeAssertions** | 8.0.2 | 단언(필수). **네임스페이스는 `using FluentAssertions;`** — AwesomeAssertions는 FluentAssertions 포크라 네임스페이스를 유지한다. |
| NSubstitute | 5.3.0 | 모킹(필요할 때만 참조) |
| Bogus / AutoFixture | — | **현재 저장소 미사용.** 기본은 인라인 데이터/팩토리 헬퍼. 대량 랜덤 데이터가 정말 필요할 때만 패키지를 추가한다. |
| coverlet | — | 미사용 |

**원칙: 실제로 쓰는 라이브러리만 참조한다.** 모킹이 없으면 NSubstitute를 넣지 않는다.

## 5. `InternalsVisibleTo` (internal 대상 접근)

대상이 `internal`이면 접근 제한자를 바꾸지 말고, **원본(소스) 프로젝트의 csproj**에 다음을 추가한다.

```xml
  <ItemGroup>
    <InternalsVisibleTo Include="대상프로젝트.Tests" />
  </ItemGroup>
```

- 어셈블리 이름 문자열만(버전·PublicKey 없음). 저장소의 모든 프로젝트가 이 단순 형태를 쓴다.
- 이미 선언돼 있는지 먼저 확인하고, 없을 때만 추가한다.

## 6. 솔루션 등록

`MD.MEDIA.sln`에는 **`Tests`** 솔루션 폴더가 있고, 모든 테스트 프로젝트가 그 아래에 **원본과 동일한 구조**로 중첩돼 있다. 새 테스트 프로젝트는 이 구조에 맞춰 추가한다.

## 7. 테스트 코드 작성 패턴

### 7.1 단순 SUT — 필드 직접 생성

의존성이 없으면 SUT를 필드로 직접 만든다.

```csharp
using System.Globalization;
using FluentAssertions;
using MD.MEDIA.Converters;
using Xunit;

namespace MD.MEDIA.Tests.Converters;

public class DataUnitConverterTests
{
    private readonly DataUnitConverter _sut = new();

    /// <summary>변환할 값이 null이면 null을 그대로 돌려준다(바인딩 초기 상태 보호).</summary>
    [Fact]
    public void Convert_Null_Null()
    {
        var result = _sut.Convert(null, typeof(string), null, CultureInfo.InvariantCulture);

        result.Should().BeNull();
    }
}
```

### 7.2 의존성 있는 SUT — `CreateSut` 팩토리

생성자 의존성이 있으면 기본값을 채우는 `CreateSut` 헬퍼를 둔다. 각 테스트는 관심 있는 의존성만 교체한다.

```csharp
private FileManagementViewModel CreateSut(
    VideoAnalysisCore? core = null,
    IModalService? modalService = null,
    VideoAnalysisService? videoAnalysisService = null)
{
    core ??= new VideoAnalysisCore();
    modalService ??= Substitute.For<IModalService>();
    videoAnalysisService ??= new VideoAnalysisService();

    return new FileManagementViewModel(core, modalService, videoAnalysisService);
}
```

### 7.3 NSubstitute 모킹·검증

```csharp
var modal = Substitute.For<IModalService>();
modal.Confirm(Arg.Any<string>()).Returns(true);   // 스텁

var sut = CreateSut(modalService: modal);
sut.DeleteCommand.Execute(null);

// 동작 검증: 결과·상태·의존성 호출
modal.Received(1).Confirm(Arg.Is<string>(m => m.Contains("삭제")));
modal.DidNotReceive().ShowError(Arg.Any<string>());
```

### 7.4 stub 내부 클래스 (추상/가상 경로 검증)

Mock 라이브러리로 다루기 어려운 추상 베이스의 흐름은 `private sealed` stub으로 검증한다.

```csharp
private sealed class StubConverter : VideoConverterBase
{
    public int PlayableCalls;
    public override Stream? ToPlayableStream(Stream s, CancellationTokenSource? ct = null)
    {
        PlayableCalls++;
        return Output;
    }
}
```

### 7.5 비동기 테스트

```csharp
[Fact]
public async Task ExecuteAsync_WhenBusy_DoesNotRunTwice()
{
    // ...
    await ((AsyncCommand)sut.Command).ExecuteAsync(null!);
    // ...
}
```

### 7.6 예외 단언

```csharp
[Fact]
public void Parse_WithNullInput_ThrowsArgumentNullException()
{
    var act = () => _sut.Parse(null!);

    act.Should().Throw<ArgumentNullException>();
}
```

## 8. TestHelpers / TestData

- **헬퍼/Fixture**
  - 프로젝트 전용: `Tests/Xxx.Tests/TestHelpers/`
  - 공용: `Tests/TestHelpers/`
  - 패턴: `namespace <RootNamespace>.TestHelpers;` 의 `internal static class XxxFactory`/`XxxHelper`로 복잡한 객체 생성을 캡슐화.
- **샘플 파일**
  - 프로젝트 전용: `Tests/Xxx.Tests/TestData/`
  - 공용: `Tests/TestData/`
  - 단, 현재 저장소는 테스트 데이터를 대부분 **인라인 바이트 배열/객체 리터럴**이나 팩토리로 만든다. 외부 파일이 꼭 필요할 때만 `TestData/`를 쓴다.
