# 2026AutumnJapan 🍁

2026-10-22–25, 니가타 → 에치고유자와 → 도쿄 → 니가타 2인 여행 수첩.

기존 [2026summer](https://github.com/seoyoon7559-moomin/2026summer)의 모바일 카드·탭 UI와 편집 흐름을 재사용했습니다. 원본 저장소와 여름 여행 데이터에는 쓰지 않습니다.

## 현재 상태

- 4일 일정, 15개 장소, 항공·열차·숙소, 2인 예산 입력 완료.
- 일정·장소 추가/수정/삭제, 좋아요, 메모, 검색, 지역 필터, Google Maps 지도·길찾기.
- 브라우저 저장, JSON 백업/복원. 로그인하지 않아도 사용 가능.
- Supabase 프로젝트 복원 및 가을 전용 테이블·초기 데이터·RLS 적용 완료. 역할별 DB 검사 15개 통과. 로그인 UI 활성화. 실제 이용 전 이메일 로그인 및 여행 멤버 등록이 필요합니다.
- 로그인 없는 열람에서 보이는 기본 여행 일정·예산은 공개 저장소/Pages의 공개 정보입니다. 멤버의 편집 내용은 RLS를 통해 보호하도록 설계했습니다.

## 실행

Node.js 22 이상에서 추가 설치 없이:

```sh
node server.mjs
node --test tests/*.test.mjs
```

브라우저에서 `http://127.0.0.1:4173`을 엽니다. ES 모듈을 쓰므로 `index.html`을 파일로 직접 열지 말고 HTTP 서버나 Pages를 사용합니다.

## GitHub Pages

저장소: `seoyoon7559-moomin/2026_Autumn_Japan`

Settings → Pages → Build and deployment → Source를 **GitHub Actions**로 선택합니다. `.github/workflows/pages.yml`이 테스트 후 정적 파일만 업로드합니다. Actions에서 `Deploy travel app to GitHub Pages`를 실행할 수 있습니다.

배포 주소: `https://seoyoon7559-moomin.github.io/2026_Autumn_Japan/`

## Supabase 연결을 마무리하는 순서

1. 완료: 기존 `ynzhiioicftbswyozfvt` 프로젝트를 재활성화했습니다. 여름 앱의 테이블·정책은 변경하지 않았습니다.
2. 완료: `supabase/setup.sql`, `supabase/seed.sql` 적용. setup을 다시 실행하지 마세요. 실제 적용된 마이그레이션 이름은 `create_isolated_autumn_trip`입니다.
3. Auth → URL Configuration에 실제 Pages 주소를 허용 리디렉션 URL로 추가합니다. 기존 여름 앱 URL을 덮어쓰지 않습니다.
4. 두 사람이 이메일로 가입/로그인한 후 관리자가 `auth.users`의 실제 사용자 UUID 두 개만 `autumn_trip_members`에 등록합니다. 익명 사용자나 모든 로그인 사용자에게 멤버 권한을 주지 않습니다.
5. `supabase/security-check.sql`과 Supabase Security Advisor로 접근 권한을 확인하고, 멤버/비멤버/로그아웃 상태의 읽기·쓰기 테스트를 합니다.
6. `collaborationEnabled: true`로 활성화했습니다. 로그인/두 기기 동기화/동시 수정 충돌/로그아웃의 실제 사용자 검증이 남아 있습니다.

`trip_id`는 **2026AutumnJapan**이며 새 테이블은 `autumn_trip_members`, `autumn_trip_items`입니다. 원본 `trip_shared_state`에는 접근하지 않습니다. 항목별 낙관적 버전 확인으로 동시 편집 충돌을 표시하고, 삭제는 tombstone으로 동기화합니다. 온라인에서는 10초 간격으로 갱신합니다.

브라우저에는 공개용 `sb_publishable_...` 키만 포함합니다. `service_role`, `sb_secret_...`, DB 비밀번호는 절대 넣지 않습니다. 멤버 목록은 관리자만 변경하며 클라이언트는 자기 멤버십만 읽습니다. 좋아요는 로그인 사용자별로 저장합니다. 로그인 세션은 탭 세션 저장소에 보관합니다.

## 예산

| 항목 | 2인 금액 |
|---|---:|
| 항공 | ₩703,600 |
| 숙박 | ₩680,000 |
| 열차 | ₩380,970 |
| 확정 합계 | ₩1,764,570 |
| 현지 지출 예상 | ₩460,000 |
| 총 예상 | ₩2,224,570 |
| 환전 계획 (중복 합산 안 함) | ₩250,000 |

관광 시각은 제안이며 항공·열차 시각은 사용자 제공 확정 내역입니다. 영업시간·요금·예약 가능 여부는 검증한 정보로 표시하지 않았습니다. 지도는 검색어 기반으로, 목적지의 정확한 지점은 Google Maps에서 확인합니다.

## 검증 범위

- Node 자동 검사: 예산, 날짜, 영구 저장, 삭제 유지, 충돌 보존/해결, 지도 URL 인코딩, 저장 오류 표시.
- 브라우저: 초기 화면 렌더링, 일정 추가→새로고침 유지→삭제, 좋아요·메모 저장 유지, 반다이바시 Google Maps 지도 표시 확인.
- Supabase: 실제 DB에서 멤버/비멤버/익명/버전충돌/좋아요 소유권 등 15개 검사 통과. Security Advisor 지적 0건. 브라우저 저장·동기화 로직 자동 검사 11개 통과.
- 미검증: 실제 이메일 로그인 및 두 기기 공동 편집, 모든 모바일 브라우저의 동작.

보안 기준: [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).
