# 최종 보고서 형식

단위 테스트 작업의 결과를 정리하는 **Markdown 보고서**의 형식이다. 보고서는 코드를 열어보지 않아도 "무엇을 왜 테스트했고, 어떤 리팩터링·개선점이 있었는지"를 이해하게 하는 것이 목적이다.

## 저장 위치와 파일명

- 위치: 작성한 테스트와 같은 영역에 둔다. 기본은 해당 테스트 프로젝트 폴더(`Tests/.../Xxx.Tests/`) 또는 사용자가 지정한 경로.
- 파일명: 범위에 맞춰 명확히. 예) 단일 클래스 → `<Class>Tests.Report.md`, 프로젝트 단위 → `<Project>.Tests.Report.md`.
- **Windows 파일명 규칙**: 콜론(`:`) 등 금지 문자를 쓰지 않는다. 날짜·시간을 넣을 때 시간 구분은 마침표(`.`)를 쓴다(예: `14.30`).
- 줄 바꿈은 `CRLF`.

## 전체 구조

`Project → Class → Method`를 헤딩 depth로 나눈 트리로 작성한다. 맨 위는 **링크된 목차**다.

```markdown
# 단위 테스트 보고서 — <대상> (<YYYY-MM-DD>)

## 목차
- [<Project>](#project-앵커)
  - [<Class>](#class-앵커)
    - [<Method>](#method-앵커)
    - [<Method>](#method-앵커)
  - [<Class>](#class-앵커)
    - ...

## <Project>

### <Class>
<클래스 수준 본문 — 아래 규칙. 없으면 헤딩만 두고 본문 생략>

#### <Method>
<메서드 수준 본문 — 아래 규칙>
```

- 목차의 각 항목은 해당 헤딩으로 가는 **앵커 링크**다. 헤딩 텍스트를 소문자화하고 공백을 `-`로 바꾼 GitHub 스타일 앵커를 쓴다(같은 이름이 중복되면 `-1`, `-2`가 붙는다). 헤딩에 시그니처 같은 특수문자가 있으면 앵커 생성 규칙에 맞게 조정한다.
- 들여쓰기로 Project/Class/Method depth를 표현한다.
- 대상이 여러 프로젝트면 Project 헤딩을 여러 개 둔다. 한 클래스만 작업했어도 동일 구조(Project 1개 → Class 1개)를 유지한다.

## Class 수준 본문 규칙

`### <Class>` 아래에는 **클래스 단위**의 내용만 쓴다.

- **클래스 수준 리팩터링이 있었다면**: 무엇을 바꿨는지, **왜 필요했는지**(테스트가 막힌 이유 등), **어떤 방향으로** 작업했는지를 설명한다. 동작 보존 여부도 언급한다.
- **추가 개선 제안**: 지금 당장 하지 않았더라도 개선하면 좋을 점(설계·책임 분리·네이밍 등)이 있으면 적는다.
- **둘 다 없으면**: 헤딩만 두고 본문은 비운다(바로 메서드로 내려간다).

## Method 수준 본문 규칙

`#### <Method>` 아래에는 다음을 사용자가 이해할 수 있게 쓴다.

1. **테스트 목적**: 이 메서드가 무슨 동작을 보장해야 하며, 그것이 깨지면 무슨 문제가 생기는지.
2. **테스트 케이스 설명**: 각 테스트 케이스(또는 `[InlineData]` 묶음)가 **어떤 경우를 검증하는지**를 표나 목록으로 정리한다. 구현 용어가 아니라 "어떤 상황 → 어떤 기대 결과" 형태로.
3. **대상 함수 리팩터링(했다면)**: 테스트를 위해 대상 메서드를 고쳤다면 그 **이유와 작업 방향**.
4. **대상 함수 개선점(있다면)**: 케이스를 만들며 발견한 결함·위험(처리 안 된 분기, 경계 오류, 삼킨 예외 등)과 권장 수정 방향. 테스트가 실패로 박제한 결함이면 그 사실을 명시.

테스트 케이스 정리는 표를 권장한다.

| 테스트 케이스 | 검증하는 경우 | 기대 결과 |
|---|---|---|
| ... | ... | ... |

---

## 작성 예시

````markdown
# 단위 테스트 보고서 — MEDIA.VideoConverter (2026-06-18)

## 목차
- [MEDIA.VideoConverter](#mediavideoconverter)
  - [VideoConverterFactory](#videoconverterfactory)
    - [GetConverter](#getconverter)
  - [DeleteEvidenceCommand](#deleteevidencecommand)
    - [Execute](#execute)

## MEDIA.VideoConverter

### VideoConverterFactory

클래스 수준 리팩터링은 없었다. 모든 멤버가 정적 순수 매핑이라 추가 의존성 없이 그대로 테스트 가능했다.

> 개선 제안: 포맷 enum이 추가될 때 `switch`에 케이스를 빠뜨리면 조용히 `DefaultConverter`로 떨어진다. enum→Converter 매핑을 사전(dictionary)으로 두고 미등록 값에 진단 로그를 남기면 누락을 더 빨리 발견할 수 있다.

#### GetConverter

**테스트 목적**: 미디어 스트림 타입(enum)을 알맞은 구체 Converter로 1:1 매핑하는 것을 보장한다. 이 매핑이 어긋나면 특정 포맷 증거물이 잘못된 디코딩 경로를 타 재생·썸네일이 깨진다.

| 테스트 케이스 | 검증하는 경우 | 기대 결과 |
|---|---|---|
| `GetConverter_KnownType_ReturnsMatchingConverter` | 정의된 각 포맷 enum 전부 | 약속된 전용 Converter 타입 반환 |
| `GetConverter_TatTypes_ReturnsTatConverter` | TAT16/TAT32(muxer만 다름) | 같은 `TatConverter`로 수렴 |
| `GetConverter_RepairedH264_ReturnsRepairedH264Converter` | codec 인자를 쓰는 유일한 분기 | `RepairedH264Converter` 반환 |
| `GetConverter_UnknownOrNoneType_ReturnsDefaultConverter` | None·Undefined·범위 밖 enum | `default` 분기로 `DefaultConverter` |

대상 함수 리팩터링: 없음.

### DeleteEvidenceCommand

**클래스 수준 리팩터링**: `Execute()`가 `MessageBox.Show(...)`를 직접 호출해 테스트 시 UI가 떠 멈추는 구조였다. 사용자 상호작용을 `IUserDialog` 인터페이스로 분리하고 생성자로 주입하도록 바꿨다(프로덕션은 `MessageBoxUserDialog` 구현). 동작은 동일하며, 테스트는 Mock으로 "확인/취소" 분기를 모두 검증할 수 있게 됐다. 메서드를 `virtual`로 열어 가로채는 방식은 쓰지 않았다.

#### Execute

**테스트 목적**: 삭제 확인 대화의 사용자 선택에 따라 증거물을 삭제하거나 삭제하지 않음을 보장한다. 이 분기가 깨지면 사용자가 취소했는데도 증거물이 삭제되는 치명적 동작이 가능하다.

| 테스트 케이스 | 검증하는 경우 | 기대 결과 |
|---|---|---|
| `Execute_WhenUserConfirms_DeletesEvidence` | 사용자가 "예"를 선택 | 리포지토리의 `Delete`가 1회 호출 |
| `Execute_WhenUserCancels_DoesNotDelete` | 사용자가 "아니오"를 선택 | `Delete`가 호출되지 않음 |

**대상 함수 리팩터링**: 위 클래스 수준 설명 참조(UI 의존성 → `IUserDialog` 추상화).

**개선점**: `Delete` 호출이 예외를 던질 때의 처리가 없다. 삭제 실패 시 사용자에게 알리도록 `IUserDialog.ShowError`로 보고하는 경로를 추가하면 좋다(현재는 예외가 상위로 전파됨).
````
