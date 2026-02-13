# Notification
Claude Code가 다음과 같은 경우에 알림을 울립니다.
- 사용자 응답 요청
- 작업 완료

> Note  
> '사용자 응답 요청'에 의한 알림은 약 5초 정도 늦게 발생합니다.  
> 이는 Claude Code가 일정 시간 동안 응답이 없을 때 Hook을 실행하기 때문입니다.