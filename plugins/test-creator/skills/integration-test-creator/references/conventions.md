# 통합 테스트 프로젝트 규약 (MD-VIDEO 저장소)

> 이 문서는 저장소의 **실제** 테스트 프로젝트들을 분석해 정리한 관례를, 통합 테스트 관점으로 정리한 것이다.
> 단, **`CLAUDE.md`의 지침이 항상 우선**한다. 이 문서와 충돌하면 `CLAUDE.md`를 따른다.

## 목차
1. 위치와 폴더 구조
2. 명명 규칙
3. csproj 템플릿
4. 사용 라이브러리와 버전
5. `InternalsVisibleTo` (internal 진입점 접근)
6. 솔루션 등록
7. 통합 테스트 작성 패턴 (격리·정리·Fixture)
8. TestHelpers / TestData

---

## 1. 위치와 폴더 구조

테스트는 저장소 루트의 **`Tests/`** 아래에 **원본 프로젝트의 폴더 구조를 미러링**해 배치한다.

```
<원본 경로>                         →  Tests/<동일 경로>/<프로젝트>.IntegrationTests/
Modules/MEDIA.Decoder/             →  Tests/Modules/MEDIA.Decoder.IntegrationTests/
MD.MEDIA.VideoAnalysis/MEDIA.VideoAnalysis.Core/
                                   →  Tests/MD.MEDIA.VideoAnalysis/MEDIA.VideoAnalysis.Core.IntegrationTests/
```

테스트 프로젝트 **내부**의 폴더는 검증하는 흐름/컴포넌트 단위로 묶는다(원본 네임스페이스를 따르되, 흐름 중심 폴더도 허용).

```
Tests/MD.MEDIA.Common/MD.VideoRepair.IntegrationTests/
  MD.VideoRepair.IntegrationTests.csproj
  Recovery/
    RecoveryPipelineTests.cs
  TestData/
    sample_corrupt.mp4
```

> **단위 테스트와 분리한다.** 실제 자원을 쓰거나 느린 테스트는 `.IntegrationTests` 프로젝트에 둔다. 단위 프로젝트(`.Tests`)는 빠르고 항상 실행돼야 하기 때문이다. 통합 테스트가 아주 적고 가벼우면 단위 프로젝트 안에서 `[Trait]`로만 구분할 수도 있으나, 실제 DB·파일·외부 자원을 쓰면 별도 프로젝트를 권장한다.

## 2. 명명 규칙

- **프로젝트**: `<대상프로젝트>.IntegrationTests` (예: `MEDIA.VideoAnalysis.Core.IntegrationTests`).
- **네임스페이스**: `<RootNamespace>.<원본 상대 경로 또는 흐름>` (원본 네임스페이스를 기본으로 따라감).
- **클래스**: 검증하는 흐름/컴포넌트 중심 이름. 예: `CaseDbIntegrationTests`, `VideoAnalysisPipelineTests`, `DecoderContainerTests`.
- **메서드**: `Scenario_ExpectedResult`(흐름 중심). 예외 케이스는 결과를 `ThrowsXxx`/`CleansUp` 등으로.
  - 왕복: `SaveThenLoad_RoundTripsEvidence`
  - 실데이터: `Decode_RealSampleFile_ProducesExpectedFrames`
  - 실패 모드: `Open_CorruptFile_ThrowsAndReleasesHandles`
  - 마이그레이션: `Open_LegacySchema_MigratesToCurrentVersion`

## 3. csproj 템플릿

기본 골격은 단위 테스트와 같다(xUnit, AwesomeAssertions, TFM `net9.0`, Nullable/ImplicitUsings). 다만 **통합하려는 실제 의존성**을 참조하고, 필요하면 `TestData/`를 출력에 복사한다.

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
    <RootNamespace>대상프로젝트.IntegrationTests</RootNamespace>
    <AssemblyName>대상프로젝트.IntegrationTests</AssemblyName>
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
    <!-- 실제 자원이 필요할 때만: 예) 실제 SQLite -->
    <!-- <PackageReference Include="Microsoft.Data.Sqlite" Version="..." /> -->
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\상대경로\대상프로젝트.csproj" />
  </ItemGroup>

  <!-- 실제 샘플 파일이 검증의 핵심이면 출력에 복사 -->
  <ItemGroup>
    <None Update="TestData\**" CopyToOutputDirectory="PreserveNewest" />
  </ItemGroup>

</Project>
```

- **기본 TFM은 `net9.0`이다.** 흐름이 WPF 타입이나 Windows 전용 API에 의존할 때만 `TargetFramework`를 `net9.0-windows`로 바꾸고(그 외에는 `net9.0` 유지), WPF 타입을 노출하면 `<UseWPF>true</UseWPF>`, `<Platforms>AnyCPU;x64</Platforms>`, `<PlatformTarget>x64</PlatformTarget>`를 추가한다. 판단은 대상(원본) 프로젝트의 TFM을 따른다.
- 모킹이 진짜 외부 경계에만 필요하면 `NSubstitute` 5.3.0을 추가한다(통합에서는 보통 불필요).

## 4. 사용 라이브러리와 버전

| 라이브러리 | 버전 | 사용 |
|---|---|---|
| xunit | 2.9.2 | 테스트 프레임워크 |
| Microsoft.NET.Test.Sdk | 17.12.0 | 러너 |
| xunit.runner.visualstudio | 2.8.2 | VS 통합 |
| **AwesomeAssertions** | 8.0.2 | 단언(필수). **네임스페이스는 `using FluentAssertions;`** — AwesomeAssertions는 FluentAssertions 포크라 네임스페이스를 유지한다. |
| NSubstitute | 5.3.0 | 모킹. **통합 테스트에서는 최소화** — 실제 협력자를 쓰는 것이 목적이므로 진짜 외부 경계(외부 네트워크 등)에만 쓴다. |
| 실제 자원 라이브러리 | — | 검증에 필요한 실제 의존성(예: `Microsoft.Data.Sqlite`)을 참조한다. |
| Bogus / AutoFixture | — | **현재 저장소 미사용.** 기본은 인라인 데이터/팩토리 헬퍼. |
| coverlet | — | 미사용 |

**원칙: 실제로 쓰는 라이브러리만 참조한다.**

## 5. `InternalsVisibleTo` (internal 진입점 접근)

통합 진입점이 `internal`이면 접근 제한자를 바꾸지 말고, **원본(소스) 프로젝트의 csproj**에 다음을 추가한다.

```xml
  <ItemGroup>
    <InternalsVisibleTo Include="대상프로젝트.IntegrationTests" />
  </ItemGroup>
```

- 어셈블리 이름 문자열만(버전·PublicKey 없음). 저장소의 모든 프로젝트가 이 단순 형태를 쓴다.
- 이미 선언돼 있는지 먼저 확인하고, 없을 때만 추가한다.

## 6. 솔루션 등록

`MD.MEDIA.sln`에는 **`Tests`** 솔루션 폴더가 있고, 모든 테스트 프로젝트가 그 아래에 **원본과 동일한 구조**로 중첩돼 있다. 새 통합 테스트 프로젝트는 이 구조에 맞춰 추가한다.

## 7. 통합 테스트 작성 패턴 (격리·정리·Fixture)

통합 테스트는 실제 협력자를 쓰되, **재현성**을 위해 자원을 격리(임시 DB/디렉터리)하고 끝나면 **정리**한다. xUnit Fixture로 setup/teardown과 자원 수명을 관리한다.

### 7.1 테스트별 임시 자원 — `IDisposable` / `IAsyncLifetime`

각 테스트가 깨끗한 실제 자원을 갖도록 생성·정리한다.

```csharp
using FluentAssertions;
using Xunit;

namespace MD.MEDIA.IntegrationTests.CaseDb;

public sealed class CaseDbIntegrationTests : IDisposable
{
    private readonly string _dbPath;
    private readonly CaseRepository _sut;   // 실제 구현 — Mock 아님

    public CaseDbIntegrationTests()
    {
        // 임시 파일에 실제 SQLite DB 생성 후 스키마 적용
        _dbPath = Path.Combine(Path.GetTempPath(), $"case_{Guid.NewGuid():N}.mcf");
        _sut = CaseRepository.CreateAt(_dbPath);
    }

    public void Dispose()
    {
        _sut.Dispose();
        if (File.Exists(_dbPath)) File.Delete(_dbPath);   // 정리
    }

    /// <summary>저장한 증거물을 다시 읽으면 같은 값이 나온다(실제 SQLite 매핑 왕복 검증).</summary>
    [Fact]
    [Trait("Category", "Integration")]
    public void SaveThenLoad_RoundTripsEvidence()
    {
        var evidence = new Evidence { Id = 1, Name = "clip.mp4" };

        _sut.Save(evidence);
        var loaded = _sut.Load(1);

        loaded.Should().BeEquivalentTo(evidence);
    }
}
```

비동기 초기화/정리가 필요하면 `IAsyncLifetime`의 `InitializeAsync`/`DisposeAsync`를 쓴다.

```csharp
public sealed class PipelineTests : IAsyncLifetime
{
    public async Task InitializeAsync() { /* 비동기 준비 */ }
    public async Task DisposeAsync()    { /* 비동기 정리 */ }
}
```

### 7.2 비싼 자원 공유 — `IClassFixture<T>` / `ICollectionFixture<T>`

생성 비용이 큰 실제 자원(준비된 DB, 디코더 초기화, 샘플 준비)은 클래스/컬렉션 단위로 한 번만 만들어 공유한다.

```csharp
public sealed class SampleMediaFixture : IDisposable
{
    public string SampleDir { get; }
    public SampleMediaFixture() => SampleDir = PrepareSamples();  // TestData 복사/준비
    public void Dispose() { /* 정리 */ }
}

public class DecoderIntegrationTests : IClassFixture<SampleMediaFixture>
{
    private readonly SampleMediaFixture _fixture;
    public DecoderIntegrationTests(SampleMediaFixture fixture) => _fixture = fixture;

    /// <summary>실제 샘플 파일을 디코딩하면 기대한 프레임 수가 나온다(디코더+컨테이너 연동).</summary>
    [Fact]
    [Trait("Category", "Integration")]
    public void Decode_RealSampleFile_ProducesExpectedFrames()
    {
        var path = Path.Combine(_fixture.SampleDir, "sample.mp4");
        // ...
    }
}
```

여러 테스트 클래스가 한 자원을 공유하거나 **직렬 실행**이 필요하면(파일/DB 경합 방지) `[Collection]` + `ICollectionFixture<T>`를 쓴다.

```csharp
[CollectionDefinition("SharedDb")]
public sealed class SharedDbCollection : ICollectionFixture<SharedDbFixture> { }

[Collection("SharedDb")]
public class EvidenceFlowTests { /* SharedDbFixture를 생성자로 주입받음 */ }
```

### 7.3 분류 — `[Trait]`

모든 통합 테스트에 `[Trait("Category", "Integration")]`을 붙여 빠른 단위 실행과 분리한다.

```csharp
[Fact]
[Trait("Category", "Integration")]
public void Scenario_ExpectedResult() { /* ... */ }
```

`dotnet test --filter "Category!=Integration"`로 단위만, `--filter "Category=Integration"`으로 통합만 실행할 수 있다.

### 7.4 실패 모드 재현

실제 자원이 실패하는 상황을 실제로 일으켜 검증한다(Mock으로 흉내내지 않는다).

```csharp
/// <summary>손상된 파일을 열면 명확한 예외를 던지고 파일 핸들을 해제한다(부분 입력 방어).</summary>
[Fact]
[Trait("Category", "Integration")]
public void Open_CorruptFile_ThrowsAndReleasesHandles()
{
    var corrupt = Path.Combine(_fixture.SampleDir, "sample_corrupt.mp4");

    var act = () => _sut.Open(corrupt);

    act.Should().Throw<InvalidDataException>();
    // 핸들 해제 검증: 같은 파일을 다시 열거나 삭제 가능해야 함
    var reopen = () => File.OpenWrite(corrupt);
    reopen.Should().NotThrow();
}
```

> 통합 테스트의 핵심 원칙: **실제 협력자로 검증하되, 임시 자원으로 격리하고 반드시 정리한다.** 테스트 간 상태가 새면 통합 테스트는 신뢰할 수 없다.

## 8. TestHelpers / TestData

- **헬퍼/Fixture**
  - 프로젝트 전용: `Tests/Xxx.IntegrationTests/TestHelpers/`
  - 공용: `Tests/TestHelpers/`
  - 패턴: `namespace <RootNamespace>.TestHelpers;` 의 `internal static class XxxFactory`/Fixture 클래스로 자원 준비·정리를 캡슐화.
- **샘플 파일**
  - 프로젝트 전용: `Tests/Xxx.IntegrationTests/TestData/`
  - 공용: `Tests/TestData/`
  - 통합 테스트는 실제 샘플 파일(영상·컨테이너·DB 등)이 검증의 핵심인 경우가 많아 `TestData/`를 적극 사용한다. csproj에서 `CopyToOutputDirectory="PreserveNewest"`로 출력에 복사하고, 테스트는 출력 경로 기준으로 접근한다. 용량이 큰 바이너리는 **꼭 필요한 최소 샘플**만 둔다.
  - 가변 자원(DB·작업 디렉터리)은 TestData 원본을 직접 쓰지 말고 **임시 위치로 복사한 사본**을 쓴다 — 원본이 더럽혀지지 않게.
