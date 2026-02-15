# Windows Bash 환경 주의사항
- Git Bash에서 `> nul`을 사용하면 Windows NUL 디바이스가 아닌 실제 `nul` 파일이 생성되므로 반드시 `> /dev/null 2>&1`을 사용한다.