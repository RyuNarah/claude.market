# Atlassian
## MCP Servers
### atlassian
Atlassian 생태계에 접근할 수 있습니다.

> **Note**  
> atlassian MCP는 인증이 필요합니다.  
> Plugin 추가 후 `/mcp` 명령을 사용해 atlassian MCP에 접근하여 인증 해주세요.

## Additional Contexts
### [Issue Key](hooks/contexts/issue-key.md)
Git Branch에서 Jira Issue Key를 찾는 방법을 명시합니다. (e.g. feature/MEDIA-1039-Refactor -> MEDIA-1039)

## Commands
### `/jira:comment`
현재 Branch에 매칭 되는 Jira Issue에 작업 내용을 분석하여 댓글로 남깁니다.  
[smart-git](../smart-git/README.md)과 함께 사용했을 때 더 정확합니다.