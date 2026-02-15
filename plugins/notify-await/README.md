# Notify Await
Claude Code가 사용자 응답을 대기할 때 알림을 울립니다.

> Note  
> Claude가 대기하기 시작한 후 약 5초 정도 늦게 알림이 발생합니다.  
> 이는 Claude Code가 일정 시간 동안 응답이 없을 때 Hook을 실행하기 때문입니다.
> 즉, 빠르게 답하면 알림이 울리지 않습니다.

## Requirements
`bash` 명령을 사용할 수 있어야 합니다. Windows 환경이라면 환경 변수에 `%Git%/bin` 경로를 추가하세요.  
일반적으로 `C:\Programfiles\Git\bin` 경로를 추가하면 됩니다.