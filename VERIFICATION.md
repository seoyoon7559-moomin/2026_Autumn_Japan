# 실행 결과 및 보안 점검

## 완료

- 원본 GitHub 저장소와 배포 페이지를 읽고 기존 모바일 카드·탭 디자인을 재사용.
- 원본 `index.html` SHA-256 복사본 일치 확인. 원본 저장소에 원격 쓰기 없음.
- 별도 저장소 `seoyoon7559-moomin/2026_Autumn_Japan`에 소스 업로드.
- 25개 일정 / 15개 장소 / 항공 2편 / 신칸센 3편 / 숙소 3박 / 예산 반영.
- 자동 테스트 6개 로컬·GitHub Actions 모두 통과.
- 브라우저에서 일정 추가 → 새로고침 유지 → 삭제 확인.
- 좋아요와 메모 저장 → 새로고침 유지 확인; 검사용 데이터 정리.
- 반다이바시 Google Maps 지도 임베드가 실제 지도와 위치를 표시함을 확인.
- 로컬 HTTP 응답 200 확인.

## Supabase 보안 검토

- 공개 클라이언트에는 `sb_publishable_...` 키만 포함. 관리자 키/DB 비밀번호 없음.
- 새 앱의 REST 경로는 `autumn_trip_items`, `autumn_trip_members`만 사용.
- `trip_id=2026AutumnJapan`; 여름 앱의 `trip_shared_state` 및 trip_id에 쓰지 않음.
- 설계된 정책: 로그인 + 명시적 멤버십, 비회원 접근 차단, 자기 좋아요만 수정, membership 변경은 관리자만 가능.
- UPDATE 정책에 USING과 WITH CHECK 포함. 버전 트리거는 SECURITY INVOKER, search_path 고정.
- 입력 데이터는 HTML 출력 시 이스케이프, 지도 검색어는 URL 인코딩.
- 브라우저의 로그인 세션은 sessionStorage에 보관; 비밀 키를 전달하지 않음.

## 아직 완료하지 못한 부분

- Supabase 프로젝트 INACTIVE 상태. 재활성화 승인 대기.
- DB 정책의 실제 조회·적용·역할별 테스트 및 두 계정 실시간 협업은 미검증.
- `supabase/setup.sql`, `seed.sql`, `security-check.sql`은 준비된 파일이며 실제 DB에 적용하지 않음.
- GitHub Pages 최초 실행은 configure-pages 단계에서 Pages 미활성화로 실패. 앱 테스트와 정적 파일 준비는 성공. 사용자의 Pages Source 설정 후 재실행 필요.
- 모든 브라우저/기기 조합의 반응형 동작을 검증한 것은 아님.

협업이 준비되지 않은 상태에서 공유 저장이 된 것으로 표시하지 않도록 `collaborationEnabled: false`로 제공.
