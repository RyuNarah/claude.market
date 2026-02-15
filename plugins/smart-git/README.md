# Smart-Git
Git을 더욱 똑똑하게 사용할 수 있도록 합니다.

## Additional Contexts
### [Branch Details  ](hooks/contexts/branch-details.md)
다음과 같은 Branch 정보를 더욱 정확하게 파악하도록 합니다.
- Merge-Base를 찾을 때 `main`이 아닌 가장 가까운 Branch를 기준으로 찾습니다.
- 현재 Branch에 해당하는 Commit 범위를 계산할 때 이전에 찾은 Merge-Base부터 시작합니다.

### [Branch Info Format](hooks/contexts/branch-info-format.md)
Branch 정보를 정해진 형식으로 표시합니다.

### [Commit Hash Format](hooks/contexts/commit-hash-format.md)
Commit Hash를 앞 7자만 표시합니다.

## Commands
###  `/git:review`
현재 Branch의 작업 내용을 Review 합니다. 적절한 Agent나 Skill이 있다면 사용합니다.