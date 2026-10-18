# 2026AutumnJapan 🍁

[여행 앱](https://seoyoon7559-moomin.github.io/2026_Autumn_Japan/)

2026-10-22~25 니가타 → 에치고유자와 → 도쿄 → 니가타 2인 여행.
기존 2026summer의 모바일 UI를 재사용하며 원본 코드·데이터는 변경하지 않았습니다.

## 현재 사용 방식

사용자가 요청한 **이메일·로그인 없는 공동 편집**입니다. 앱을 열면 Supabase 자료를 읽고 변경을 자동 저장합니다. 다른 기기에는 약 10초 간격으로 반영됩니다. 주소를 아는 누구나 읽고 수정할 수 있는 공개 협업이며 비공개 자료용으로 설계되지 않았습니다.

- 일정·장소 추가/수정/삭제, 브라우저별 좋아요, 메모, Google Maps 지도·길찾기
- 오프라인 기기 저장, 연결 복구 시 업로드, 항목별 버전 충돌 표시
- JSON 백업 다운로드·복원
- 항공·숙소·열차, 확정 비용 ₩1,764,570, 현지 예상 ₩460,000, 총 예상 ₩2,224,570
- 환전 계획 ₩250,000은 비용에 중복 합산하지 않음

## 데이터와 권한

`trip_id=2026AutumnJapan`, `autumn_trip_items`만 사용합니다. RLS는 계속 활성화되어 있으며 anon 역할의 SELECT/INSERT/UPDATE는 이 trip_id로 제한합니다. 삭제는 버전이 있는 tombstone입니다. 회원 테이블은 익명 접근을 허용하지 않습니다. 여름 앱의 `trip_shared_state`는 변경하지 않았습니다.

공개 publishable 키만 사용하며 관리자 키는 포함하지 않습니다. 브라우저 ID는 좋아요 구분용이고 사용자 인증이나 보안 수단이 아닙니다. 누구나 수정 가능한 협업 방식이므로 좋아요 소유권도 보안적으로 보호되지 않습니다.

적용 순서: `create_isolated_autumn_trip` → `enable_autumn_anonymous_collaboration`. 초기 로그인용 정책은 남아 있지만 현재 앱은 인증 토큰 없이 anon으로 요청합니다. 이메일 로그인, 멤버 등록, Redirect URL 설정은 필요 없습니다.

## 실행과 검증

Node.js 22 이상: `node server.mjs` (http://127.0.0.1:4173), `node --test tests/*.test.mjs`.
별도 패키지 설치 없이 실행합니다. GitHub Actions가 테스트 후 Pages에 배포합니다.

자동 테스트 12개 통과. 익명 DB 읽기/추가/수정, 버전 충돌, 다른 trip_id 삽입 차단 및 회원 목록 접근 차단 검사 완료. `supabase/anonymous-tests.sql`은 현재 모드 검사이며, `supabase/rls-tests.sql`은 이전 로그인 전용 모드의 검사 기록이므로 현재 모드에서 기대 결과가 다릅니다.
