# JIRA 이슈 번호 추출 방법
아래 방법은 Git 환경일 때만 사용합니다.

## Branch 이름에서 JIRA 이슈 번호 추출 형식
- Branch 이름의 앞에서부터 / 앞의 내용은 무시하고, 두 번째 - 전까지를 이슈 번호로 취급한다.
- e.g. feature/MEDIA-1039-Refactor -> MEDIA-1039