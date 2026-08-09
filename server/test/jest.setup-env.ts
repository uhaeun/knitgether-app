// e2e 스펙은 자신이 명시적으로 스텁한 환경 변수만 봐야 한다 (DEF-007 참고).
// ConfigModule은 ignoreEnvFile로 막았지만, @prisma/client가 import 시점에
// server/.env를 process.env로 자동 주입하는 우회 경로가 있다.
// dotenv는 이미 존재하는 키를 덮어쓰지 않으므로, 스펙 import 전에 실행되는
// 이 setupFile에서 키를 선점해 .env 값이 인증 판정에 끼어들지 못하게 한다.
// 빈 문자열은 ApiAuthGuard에서 "매핑 없음"과 동일하게 처리된다.
process.env.KNITGETHER_API_TOKENS ??= '';
