# 최종 보고서 형식

통합 테스트 작업의 결과를 정리하는 **Markdown 보고서**의 형식이다. 보고서는 코드를 열어보지 않아도 "어떤 컴포넌트 연동을 왜 검증했고, 어떤 실제 자원·격리 방식을 썼으며, 어떤 리팩터링·개선점이 있었는지"를 이해하게 하는 것이 목적이다.

**보고서는 네가 머릿속에서 만든 개념 분류가 아니라, 실제로 작성한 테스트 코드의 구조를 그대로 비춘다.** 독자가 보고서의 목차를 보고 테스트 프로젝트를 열면 같은 이름의 클래스·메서드를 1:1로 찾을 수 있어야 한다. 그래서 트리의 뼈대는 `Project → Class → Method`이며, 노드 이름은 **실제 테스트 프로젝트명·클래스명·메서드명**을 그대로 쓴다(요약하거나 한국어 별칭으로 바꾸지 않는다). 설명·해석은 각 노드의 **본문**에 단다.

## 저장 위치와 파일명

- 위치: 작성한 테스트와 같은 영역에 둔다. 기본은 해당 통합 테스트 프로젝트 폴더(`Tests/.../Xxx.IntegrationTests/`) 또는 사용자가 지정한 경로.
- 파일명: 범위에 맞춰 명확히. 기본은 `<Project>.Report.md`(예: `MEDIA.VideoAnalysis.SceneDb.IntegrationTests.Report.md`).
- **Windows 파일명 규칙**: 콜론(`:`) 등 금지 문자를 쓰지 않는다. 날짜·시간을 넣을 때 시간 구분은 마침표(`.`)를 쓴다(예: `14.30`).
- 줄 바꿈은 `CRLF`.

## 전체 구조 — Project → Class → Method

헤딩 depth로 **실제 코드 구조**를 그대로 나눈 트리로 작성한다. 맨 위는 **링크된 목차**이며, 목차는 **Method 레벨까지** 펼친다.

| depth | 헤딩 | 노드 이름 | 무엇 |
|---|---|---|---|
| 1 | `#` | (자유) | 보고서 제목 |
| 2 | `##` | **테스트 프로젝트명** | 작성/수정한 통합 테스트 프로젝트 |
| 3 | `###` | **테스트 클래스명** | 그 프로젝트의 각 테스트 클래스 |
| 4 | `####` | **테스트 메서드명** | 그 클래스의 각 `[Fact]`/`[Theory]` 메서드 |

```markdown
# 통합 테스트 보고서 — <대상> (<YYYY-MM-DD>)

<한두 문단의 전체 요약: 무엇을 어떤 실제 자원과 연동해 검증했는지, 테스트 개수·통과 결과·실행 필터.>

## 목차
- [<TestProject>](#testproject-앵커)
  - [<TestClassA>](#testclassa-앵커)
    - [<TestMethod1>](#testmethod1-앵커)
    - [<TestMethod2>](#testmethod2-앵커)
  - [<TestClassB>](#testclassb-앵커)
    - [<TestMethod3>](#testmethod3-앵커)

## <TestProject>
<프로젝트 수준 본문 — 아래 규칙>

### <TestClassA>
<클래스 수준 본문 — 아래 규칙>

#### <TestMethod1>
<메서드 수준 본문 — 아래 규칙>

#### <TestMethod2>
<메서드 수준 본문>
```

- 목차의 각 항목은 해당 헤딩으로 가는 **앵커 링크**다. GitHub 스타일 앵커: 헤딩 텍스트를 소문자화하고 공백을 `-`로 바꾼다. **밑줄(`_`)은 그대로 유지**되므로 `InsertTag_ThenSelectAll_RoundTrips` → `#inserttag_thenselectall_roundtrips`. 같은 텍스트가 중복되면 `-1`, `-2`를 붙인다.
- 목차의 들여쓰기로 Project / Class / Method depth를 표현한다.
- **하나의 시나리오에 메서드가 여럿이면 메서드를 묶지 말고 각각 `####`로 편다.** 묶고 싶은 충동(개념적 그룹핑)이 들더라도, 보고서가 코드와 1:1로 대응하는 가치가 더 크다.
- `[Theory]`+`[InlineData]`처럼 **한 메서드 안에 여러 케이스**가 있는 것은 별개다 — 메서드는 하나의 `####`로 두고, 그 안에서 각 `InlineData` 케이스를 표/목록으로 설명한다(아래 메서드 수준 규칙).
- 대상이 여러 테스트 프로젝트면 `##` 프로젝트 헤딩을 여러 개 둔다.
- `TestBase`/`Fixture`/스키마 헬퍼처럼 `[Fact]`가 없는 보조 클래스는 트리 노드로 넣지 않는다. 그 역할은 프로젝트 또는 클래스 수준 본문에서 "격리·정리"로 설명한다.

## 프로젝트 수준 본문 규칙 (`## <TestProject>`)

이 프로젝트 전체에 걸친 내용을 쓴다. 클래스마다 반복되는 공통 사항은 여기서 한 번에 설명하고, 아래 클래스/메서드에서 되풀이하지 않는다.

- **무엇과 무엇을 연동해 검증하는가**: 실제로 함께 돌린 컴포넌트와, 경계(외부 자원)로 둔 것을 정리한다. 검증의 초점(어떤 경계 계약인지)을 한두 문장으로.
- **공통 격리·정리 전략**: 테스트들이 공유하는 실제 자원·Fixture·`TestBase`, 임시 DB/디렉터리 생성과 정리, 병렬화 설정 등. 잔여 자원이 없음을 확인했으면 명시.
- **프로젝트 전반 리팩터링**: 운영 코드에 가한 변경(예: `InternalsVisibleTo` 추가, seam 확보)이 있으면 **무엇을·왜·어떤 방향으로** 했는지와 **동작 보존 여부**.
- **테스트 구성상의 특이점**: 실제 자원을 끌어오기 위한 비자명한 설정(임베디드 리소스 링크, 네이티브 라이브러리 로딩 등)이 있으면 적는다.
- **개선 제안**: 이번에 다루지 않았지만 보강하면 좋을 경계·자원·구성 위험.

## 클래스 수준 본문 규칙 (`### <TestClass>`)

이 클래스가 묶어서 검증하는 **연동 단위**를 설명한다.

- **이 클래스가 검증하는 경계/계약**: 어떤 컴포넌트 쌍 또는 흐름의 어떤 약속을 이 클래스가 책임지는지(예: "엔티티 ↔ IBatis SQL 매핑 ↔ SQLite 스키마의 컬럼·복합키·정렬 계약").
- **클래스 고유의 자원·격리**: 프로젝트 공통과 다른, 이 클래스만의 Fixture·샘플 파일·setup이 있으면.
- **클래스 단위 리팩터링·개선점**: 이 클래스 대상에 한정된 것이 있으면. 없으면 생략.
- 쓸 내용이 프로젝트 본문과 겹치고 클래스 고유 사항이 없으면, **이 클래스가 무엇을 검증하는지 한 줄**만 두고 바로 메서드로 내려간다.

## 메서드 수준 본문 규칙 (`#### <TestMethod>`)

각 테스트 메서드가 **어떤 연동을 어떻게 검증하는지** 사용자가 코드 없이 이해하도록 쓴다. 메서드명이 이미 의도를 담고 있으니, 본문은 그 너머의 **왜**와 **무엇이 깨지면 무슨 문제인지**에 집중한다. 1~3문장이면 충분하다.

1. **검증 목적**: 이 메서드가 어떤 연동/계약을 보장하며, 그것이 깨지면 실제로 무슨 문제가 생기는지.
2. **상황 → 기대 결과**: 무엇을 입력/실행해 무엇을 단언하는지. 내부 호출 순서가 아니라 **관찰 가능한 결과**(저장된 데이터·왕복 동등성·던진 예외·정리된 자원 상태)로.
3. **여러 케이스(`[InlineData]`/`[MemberData]`)**: 케이스가 여럿이면 각 케이스가 대표하는 입력·설정·실패 상황을 표/목록으로 한 줄씩.
4. **메서드별 자원·격리**: 프로젝트/클래스 공통과 다른 점이 있을 때만(예: 이 메서드만 손상 샘플 파일을 씀).
5. **연동 결함 박제**: 이 메서드가 발견한 연동 결함을 실패로 박제한 것이면 그 사실과 권장 수정 방향을 명시한다.

여러 `InlineData` 케이스가 있는 메서드는 표를 쓰면 읽기 좋다:

| 케이스(InlineData) | 상황 | 기대 결과 |
|---|---|---|
| `IsGpuAnalyzed = 0` | GPU 미분석 플래그 | 0으로 왕복 보존 |
| `IsGpuAnalyzed = 1` | GPU 분석 플래그 | 1로 왕복 보존 |

---

## 작성 예시

````markdown
# 통합 테스트 보고서 — MEDIA.VideoAnalysis.SceneDb (2026-06-18)

`MEDIA.VideoAnalysis.SceneDb`의 데이터 접근 계층을 **실제 SQLite(`:memory:`) + 실제 IBatis SQL맵**과 연동해 검증한다. 24개 테스트 전부 통과, 임시 파일/폴더 생성 0. 실행 필터: `dotnet test --filter "Category=Integration"`.

## 목차
- [MEDIA.VideoAnalysis.SceneDb.IntegrationTests](#mediavideoanalysisscenedbintegrationtests)
  - [SceneMapperConfigurationTests](#scenemapperconfigurationtests)
    - [NewInMemoryScene_LoadsRealSqlMaps_AndRoundTripsMetaInfo](#newinmemoryscene_loadsrealsqlmaps_androundtripsmetainfo)
    - [Dispose_ThenOperations_AreNoOpsWithoutThrowing](#dispose_thenoperations_arenoopswithoutthrowing)
  - [TagRoundTripTests](#tagroundtriptests)
    - [InsertTag_ThenSelectAll_RoundTripsAllColumns](#inserttag_thenselectall_roundtripsallcolumns)
    - [DeleteTag_RemovesRow](#deletetag_removesrow)

## MEDIA.VideoAnalysis.SceneDb.IntegrationTests

`SceneMapper`(IBatis 데이터 접근 계층)를 실제 SQLite·실제 SQL맵과 함께 돌려, 단위 테스트가 각자 Mock으로 가정하던 **엔티티 ↔ SQL 매핑 ↔ SQLite 스키마**의 경계 계약(컬럼명·타입·복합키·정렬·upsert 의미)이 실제로 맞물리는지 검증한다. 외부 네트워크·시계·난수 같은 비결정 경계는 없다.

**격리·정리**: 각 테스트는 `SceneMapperTestBase.NewInMemoryScene()`로 자기만의 `:memory:` DB를 만들고(전체 스키마 포함), `Dispose`에서 연결을 닫아 해제한다. 파일을 만들지 않아 실행 후 잔여 DB/폴더가 없음을 확인했다. 어셈블리 전역 병렬화는 비활성화했다.

**리팩터링**: 운영 코드 동작 변경 없음. `SceneMapper` 생성자가 `internal`이라 `MEDIA.VideoAnalysis.SceneDb.csproj`에 `InternalsVisibleTo`(테스트 어셈블리)만 추가했다(접근 제한자 상향 없음).

> **개선 제안**: `:memory:`는 연결이 닫히면 데이터가 사라져 트랜잭션 커밋/롤백의 영속·폐기 의미를 검증할 수 없다. 이 경계는 파일 기반 DB를 쓰는 별도 통합 테스트로 보강을 권장한다.

### SceneMapperConfigurationTests

매퍼 생성 파이프라인 전체(임베디드 `SqlMap.config` 로드 → `providers.config`·SQL맵 해석 → `:memory:` 연결 → DDL 실행)와 해제 후 가드 동작을 검증한다.

#### NewInMemoryScene_LoadsRealSqlMaps_AndRoundTripsMetaInfo

매퍼 생성→MetaInfo 저장→조회까지 전 파이프라인이 살아 있음을 보장한다. 이게 깨지면 리소스 해석·프로바이더 로딩·스키마 생성 중 하나가 어긋난 것이다. 저장한 Version 값이 그대로 조회되면 통과.

#### Dispose_ThenOperations_AreNoOpsWithoutThrowing

해제 후 작업이 던지지 않고 안전한 기본값(-1/null)을 반환하는 가드를, 반복 `Dispose`까지 포함해 보장한다. 해제 후 우발적 호출이 크래시를 내면 안 된다.

### TagRoundTripTests

태그 테이블과 태그-결과 관계 테이블의 CRUD·정렬·LastId 계약을 검증한다.

#### InsertTag_ThenSelectAll_RoundTripsAllColumns

태그를 저장하고 다시 읽었을 때 Id/Name/Color가 모두 동일함을 보장한다. 매핑이 어긋나면 태그 메타데이터가 유실/왜곡된다.

#### DeleteTag_RemovesRow

지정한 Id의 행만 삭제되고 다른 태그는 보존됨을 보장한다. 삭제 SQL의 WHERE 계약이 깨지면 무관한 태그가 함께 지워진다.
````
