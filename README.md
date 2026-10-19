<div align="center">

# 🧸 ReMory Frontend

**치매 어르신과 가족을 잇는 돌봄 인형 서비스, 리모리(ReMory)의 보호자 앱**

가족은 앱으로 어르신의 하루를 살피고,<br/>
메시지 · 사진 · 추억 · 익숙한 목소리를 인형 **모리**에게 전합니다.

<br/>

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart&logoColor=white)
![Mobile](https://img.shields.io/badge/Platform-Android%20%C2%B7%20iOS-555555)
![Passkey](https://img.shields.io/badge/Auth-Passkey-936249)
![Firebase](https://img.shields.io/badge/Firebase-Auth%20%C2%B7%20FCM-FFCA28?logo=firebase&logoColor=black)

</div>

---

## 📖 이런 서비스입니다

치매를 앓는 어르신은 하루 대부분을 혼자 보냅니다. 가족은 멀리 있고,
"오늘 어떠셨어요?"를 물어볼 방법이 전화밖에 없습니다.

**리모리는 어르신 곁에 인형을 둡니다.** 인형 *모리*는 어르신과 대화를 나누고,
가족이 남긴 메시지를 **가족의 목소리로** 읽어주고, 약 드실 시간을 알려줍니다.
그 사이에 쌓인 대화·감정·활동은 보호자 앱의 홈 화면과 리포트로 정리되어 전달됩니다.

<table>
<tr>
<td width="33%" valign="top">

### 👵 어르신
말벗이 되어주는 인형 **모리**.
"모리야" 하고 부르면 대답하고,
사진 속 추억을 함께 이야기하고,
약 시간을 챙겨줍니다.

</td>
<td width="33%" valign="top">

### 🧸 인형 (Device)
Raspberry Pi 5 + 카메라·마이크·스피커.
대화·감정·활동을 서버에 올리고,
가족 메시지와 어르신 정보(RAG)를
서버에서 받아 갑니다.

</td>
<td width="33%" valign="top">

### 👨‍👩‍👧 가족 (보호자)
Flutter 앱으로 어르신 상태를 보고,
메시지·사진·추억을 남기고,
자기 목소리를 등록하고,
오늘과 한 주의 리포트를 받습니다.

</td>
</tr>
</table>

---

## 📱 앱 화면 미리보기

<table>
<tr>
<th align="center" width="33%">온보딩 화면</th>
<th align="center" width="33%">홈 화면</th>
<th align="center" width="33%">오늘의 리포트</th>
</tr>
<tr>
<td align="center" valign="top"><img src="remory-readme-assets/screen-onboarding.jpg" alt="ReMory 온보딩 화면" width="260" /></td>
<td align="center" valign="top"><img src="remory-readme-assets/screen-home.jpg" alt="ReMory 홈 화면" width="260" /></td>
<td align="center" valign="top"><img src="remory-readme-assets/screen-report.jpg" alt="ReMory 오늘의 리포트" width="260" /></td>
</tr>
<tr>
<th align="center" width="33%">추억 추가</th>
<th align="center" width="33%">목소리 등록</th>
<th align="center" width="33%">설정</th>
</tr>
<tr>
<td align="center" valign="top"><img src="remory-readme-assets/screen-memory.jpg" alt="ReMory 추억 추가" width="260" /></td>
<td align="center" valign="top"><img src="remory-readme-assets/screen-voice.jpg" alt="ReMory 목소리 등록" width="260" /></td>
<td align="center" valign="top"><img src="remory-readme-assets/screen-settings.jpg" alt="ReMory 설정" width="260" /></td>
</tr>
</table>

---

## 🗺 시스템 구성

<div align="center">
  <img src="remory-readme-assets/system-architecture.png" alt="ReMory 시스템 구성도" width="100%" />
</div>

<br/>

**전체 서비스에서 이 저장소의 자리**

| | 무엇을 하나 | 핵심 |
|---|---|---|
| **보호자 앱** | 📍 **이 저장소** | Flutter(Android·iOS) · 보호자 입력과 화면 표시 · 사진 선택 · 음성 녹음 · 푸시 수신 |
| **① 엣지 · 인형 모리** | 어르신 곁에서 듣고 말한다 | Raspberry Pi 5 + AI HAT+ · 카메라/마이크/스피커/LCD · 웨이크워드·STT·감정 인식 |
| **② AI 처리** | 대화를 이해하고 가족 목소리를 만든다 | Groq(대화 생성) · Fish Audio(TTS·가족 음성 모델) · RAG |
| **③ AWS 클라우드** | 앱과 인형을 잇는다 | FastAPI · 패스키 인증 · PostgreSQL · S3 · FCM · HTTPS REST API |

앱은 어르신의 얼굴 원본을 받지 않습니다. 인형이 얼굴을 기기 안에서 분석하고,
서버와 앱에는 대화에 필요한 **감정 라벨과 활동 기록만** 전달합니다.

> 🔗 인형의 온디바이스 코드는 [Hanium-Remory/Hanium-Remory-HW](https://github.com/Hanium-Remory/Hanium-Remory-HW), 백엔드는 [Hanium-Remory/Hanium-Remory-BE](https://github.com/Hanium-Remory/Hanium-Remory-BE)에 있습니다.

---

## 🔁 앱 사용 흐름

### 01 보호자 앱 화면 구성

<div align="center">
  <img src="remory-readme-assets/app-flow.png" alt="ReMory 앱 화면 구성도" width="100%" />
</div>

### 02 사용자별 주요 기능

<div align="center">
  <img src="remory-readme-assets/use-case.png" alt="ReMory 유즈케이스 다이어그램" width="100%" />
</div>

```text
스플래시 → 온보딩 → 전화번호 인증 · 패스키 가입/로그인
                                  ↓
                         최초 정보 등록 / 가족 연결
                                  ↓
                             홈 대시보드
               ┌──────────┬───────┼────────┬──────────┐
             대화방      추억    리포트   알림 센터    설정
               │          │       │                     │
        글·사진 전달   기억 저장  일간·주간       가족·인형·복약·목소리
```

---

## ✨ 주요 화면과 기능

| 화면 | 보호자가 할 수 있는 일 |
|---|---|
| 👋 **온보딩** | 서비스 소개를 보고 가입·로그인을 시작합니다 |
| 🔐 **가입·로그인** | Firebase 전화번호 인증 뒤 패스키를 등록하고, 이후 비밀번호 없이 로그인합니다 |
| 👨‍👩‍👧 **최초 등록·가족 연결** | 보호자·어르신 정보를 입력하거나 초대 코드로 기존 가족에 참여합니다 |
| 🏠 **홈 대시보드** | 인형의 연결·대화 상태, 오늘의 감정과 활동을 5초 간격으로 갱신합니다 |
| 🔔 **알림 센터** | 감정 변화·기기 연결·가족 메시지·리포트 알림을 확인하고 읽음 처리합니다 |
| 💬 **가족 대화방** | 글과 사진을 보내고 미확인 가족 수와 인형 전달 여부를 확인하며, 어르신의 음성 답장을 재생합니다 |
| 📷 **추억 등록** | 사진과 시기, 이야기를 입력해 모리가 대화 중 꺼내 볼 추억을 저장합니다 |
| 🎙 **가족 목소리 등록** | 안내 문구를 녹음·재생·업로드하고 학습 상태를 확인합니다 |
| 📊 **오늘의 리포트** | 날짜별 요약·감정·실제 활동·대화 발췌를 확인하고 달력에서 기록을 찾습니다 |
| 📈 **주간 리포트** | 주별 이야기, 주요 키워드와 요일별 감정 흐름을 확인합니다 |
| ⚙️ **설정** | 프로필, 가족, 어르신 정보, 인형 볼륨·목소리·방해 금지 시간과 복약 일정을 관리합니다 |

---

## 🛠 설계에서 신경 쓴 것

- 🔐 **비밀번호를 기억할 필요가 없습니다.** 최초 전화번호 확인 뒤 기기에 패스키를 등록하고, Android에서는 지문 등 기기 인증으로, iOS에서는 Face ID 등으로 다시 로그인합니다.
- ♻️ **세션이 끊겨도 요청을 바로 버리지 않습니다.** 인증 요청이 401을 받으면 refresh token으로 access token을 갱신하고 요청을 한 번 재시도합니다. 복구할 수 없을 때만 세션을 지우고 로그인 화면으로 돌아갑니다.
- 🔔 **앱을 보고 있을 때도 알림을 놓치지 않습니다.** 백그라운드에서는 FCM이, 포그라운드에서는 중요도 높은 로컬 알림 채널이 휴대전화 상단에 알림을 띄웁니다. 상태바에는 단색 모리 얼굴 아이콘을 사용합니다.
- 💬 **전송 뒤의 상태까지 보여줍니다.** 글에는 읽지 않은 가족 수를, 사진에는 `인형에 보내는 중`과 `인형 화면에 표시 완료`를 표시합니다.
- 🎧 **어르신 답장을 기다리지 않고 듣습니다.** 음성 주소를 말풍선이 나타날 때 미리 준비하고, 재생·일시정지·이어 듣기를 지원합니다. 10초 주기 갱신 중에도 같은 메시지 키를 유지해 재생이 끊기지 않습니다.
- 🎙 **목소리는 가족이 함께 쓰되 소유권은 지킵니다.** 등록된 목소리는 가족이 인형의 기본 목소리로 고를 수 있지만, 삭제 버튼은 등록한 보호자에게만 보이고 서버도 같은 기준으로 검사합니다.
- 🐟 **새로 녹음하지 않아도 됩니다.** Fish Audio에 이미 만든 목소리는 모델 ID나 모델 주소로 가져와 바로 인형 목소리로 선택할 수 있습니다.
- 👵 **화면의 말투도 익숙하게 맞춥니다.** 저장된 성별에 따라 `어머님` 또는 `아버님` 호칭을 사용하고, 크림색·브라운 계열과 큰 카드 중심의 모바일 화면으로 통일했습니다.

---

## 🔐 인증 · 세션 · 알림

### 가입과 로그인

```text
전화번호 입력 → Firebase SMS 인증 → 백엔드 토큰 검증
                                      ↓
                              패스키 등록(WebAuthn)
                                      ↓
                           access/refresh token 저장
```

패스키 인증은 서버의 RP ID와 Android App Links 또는 iOS Associated Domains 설정이 일치해야 합니다.
세션은 `shared_preferences`에 저장하며, 앱 시작 시 refresh token의 JWT 만료 시각을 먼저 확인합니다.
만료 경계 30초 전부터 만료로 처리해 홈 화면에 들어간 직후 연속으로 401을 받는 상황을 피합니다.

### 푸시 알림

앱은 알림 권한을 요청하고 FCM 토큰을 백엔드에 등록합니다. 토큰이 갱신되면 새 값을 다시 등록하고,
로그아웃할 때는 서버에서 토큰을 해제합니다. 푸시 도착 시 알림 센터가 데이터를 다시 불러옵니다.

현재 보호자가 직접 켜고 끌 수 있는 항목은 다음과 같습니다.

| 알림 | 의미 |
|---|---|
| **감정 변화** | 어르신의 감정 변화가 감지됐을 때 |
| **기기 연결 해제** | 인형의 연결이 끊겼을 때 |

가족 메시지, 어르신 음성 답장, 목소리 학습 완료, 리포트 생성 등 서버가 보내는 서비스 알림도 FCM으로 수신합니다.

---

## 🧰 기술 스택

| 영역 | 사용 기술 | 용도 |
|---|---|---|
| **앱 프레임워크** | Flutter · Dart 3.12+ | Android·iOS 보호자 앱 UI와 화면 흐름 |
| **UI 구성** | Material · flutter_screenutil | Pretendard 글꼴, 공통 테마, 화면 크기 대응 |
| **상태·화면 전환** | StatefulWidget · IndexedStack · Navigator | 화면별 상태와 하단 탭·단계 이동 관리 |
| **서버 통신** | http | HTTPS REST API와 multipart 파일 업로드 |
| **인증** | passkeys · Firebase Auth | WebAuthn 패스키와 SMS 전화번호 인증 |
| **로컬 저장** | shared_preferences | access/refresh token, 보호자 ID, 온보딩 여부, 어르신 호칭 |
| **사진 선택** | image_picker | 추억·프로필·대화방 사진 선택 |
| **음성** | record · audioplayers | 가족 목소리 녹음·미리 듣기, 어르신 답장 재생 |
| **푸시 알림** | firebase_messaging · flutter_local_notifications | FCM 수신과 포그라운드 상단 알림 |
| **공유** | share_plus | 초대 코드 등의 시스템 공유 |
| **앱 정보** | package_info_plus | 앱 버전 조회 |
| **개발 도구** | flutter_lints · flutter_test | 정적 분석과 단위·위젯 테스트 |

패키지와 앱 버전은 [`pubspec.yaml`](pubspec.yaml)에서 확인할 수 있습니다.

---

## 📁 프로젝트 구조

```text
lib/
├── main.dart                       Firebase·세션 초기화와 공통 테마
├── main_shell.dart                 홈·대화·추억·설정 공통 하단 탭
├── firebase_options.dart           Android·iOS Firebase 플랫폼 설정
├── preview_launcher.dart           주요 화면 미리보기 런처
├── backend_test.dart               백엔드 연동 확인용 진입점
├── reg_test.dart                   등록 확인용 진입점
├── 1. splash_onboarding/           스플래시 · 온보딩
├── 2. pastkey/                     가입 · 전화번호 확인 · 패스키 인증
├── 3. code/                        최초 정보 등록 · 초대 코드
├── 4. home/                        홈 대시보드 · 알림 센터
├── 5. memory/                      사진 추억 등록
├── 6. chat/                        가족 대화방 · 어르신 음성 답장
├── 7. report/                      오늘 · 주간 리포트 · 달력
├── 8. vocie/                       가족 목소리 녹음·등록
├── 9. set/                         프로필 · 가족 · 인형 · 복약 설정
└── services/
    ├── auth_api.dart               전화번호 확인 · 패스키 등록·로그인
    ├── settings_api.dart           서비스 API · 응답 모델 · 401 재시도
    ├── session_store.dart          로컬 세션과 온보딩 상태
    ├── firebase_phone_auth.dart    Firebase SMS 인증과 ID token 발급
    ├── push_service.dart           FCM 토큰·수신·상단 알림
    └── device_token_store.dart     인형 기기 토큰의 로컬 보관

android/ · ios/                     모바일 플랫폼·Firebase·알림 설정
web/ · windows/ · macos/ · linux/   Flutter 플랫폼 실행 프로젝트
test/                               기능별 단위·위젯 테스트
remory-readme-assets/               README 화면·흐름·구성 이미지
```

> 폴더명 `8. vocie/`는 현재 저장소의 표기를 그대로 적었습니다. 기본 실행 환경은 Android·iOS이며, 다른 플랫폼은 Firebase 등 별도 설정이 필요합니다.

---

## 🚀 실행하기

### 1. 프로젝트 준비

Dart SDK `^3.12.0` 조건을 충족하는 Flutter SDK와 Android 또는 iOS 기기·에뮬레이터를 준비합니다.

```bash
git clone https://github.com/26-HS092/Hanium-Remory-FE.git
cd Hanium-Remory-FE
flutter pub get
```

### 2. 실행 환경 설정

백엔드 주소와 Firebase 토큰 검증 경로는 소스 수정 없이 `--dart-define`으로 지정할 수 있습니다.

| 설정 | 코드의 기본값 | 용도 |
|---|---|---|
| `BACKEND_BASE_URL` | `https://32-184-124-116.sslip.io` | 백엔드 API 주소 |
| `FIREBASE_VERIFY_PATH` | `/auth/phone/verify-firebase` | Firebase ID token 검증 경로 |

설정 정의는 [`auth_api.dart`](lib/services/auth_api.dart)에 있습니다.
자체 Firebase 프로젝트를 사용할 경우 [`firebase_options.dart`](lib/firebase_options.dart),
Android `google-services.json`, iOS `GoogleService-Info.plist`와 앱 식별자를 함께 맞춰야 합니다.

사진·마이크·알림 기능은 실행 기기의 권한 허용이 필요합니다.

### 3. 앱 실행

```bash
flutter devices
flutter run -d <기기_ID>

# 다른 백엔드에 연결할 때
flutter run -d <기기_ID> \
  --dart-define=BACKEND_BASE_URL=https://your-backend.example.com
```

`<기기_ID>`는 `flutter devices`에 표시된 값으로 바꿉니다.

### 4. 화면 미리보기

```bash
flutter run -t lib/preview_launcher.dart
```

미리보기 런처에서는 온보딩·홈·리포트·추억·목소리·설정 등 주요 화면으로 바로 이동할 수 있습니다.
API를 호출하는 화면에는 유효한 로그인 세션이 필요할 수 있습니다.

---

## 🔌 백엔드와 주고받는 것

인증이 필요한 요청에는 `Authorization: Bearer <accessToken>`을 붙입니다.

| 기능 | 대표 엔드포인트 | 앱에서 하는 일 |
|---|---|---|
| **전화번호·패스키** | `POST /auth/phone/*` · `POST /auth/passkey/*` | SMS 확인, 패스키 등록·로그인 |
| **보호자·가족** | `GET/PUT /protectors/me` · `GET /users/{id}/family-members` | 프로필과 연결 가족 관리 |
| **가족 초대** | `POST /users/{id}/invite-codes` · `POST /invite-codes/{code}/accept` | 초대 코드 생성·확인·참여 |
| **홈** | `GET /users/{id}/home` · `GET /users/{id}/emotions` · `GET /users/{id}/activities` | 인형 상태, 감정과 활동 조회 |
| **가족 대화방** | `GET/POST /users/{id}/chat/messages` | 글·사진 전달, 읽음·인형 전달·음성 답장 조회 |
| **추억** | `POST /files/images` · `POST /users/{id}/memories` | 사진 업로드와 추억 저장 |
| **리포트** | `GET /users/{id}/reports/daily` · `GET /users/{id}/reports/weekly` | 일간·주간 리포트와 기록 날짜 조회 |
| **알림** | `GET /notifications` · `PATCH /notifications/{id}/read` | 앱 알림 조회·읽음 처리 |
| **인형 설정** | `GET/PUT /devices/{id}/settings` · `GET/PUT /devices/{id}/dnd` | 볼륨, 기본 목소리, 방해 금지 시간 관리 |
| **복약** | `GET/POST /devices/{id}/medications` · `PUT/DELETE /medications/{id}` | 복약 일정 조회·추가·수정·삭제 |
| **목소리** | `POST /devices/{id}/voices` · `POST /devices/{id}/voices/fish` | 녹음 업로드 또는 Fish 모델 가져오기 |
| **푸시** | `POST/DELETE /protectors/me/push-tokens` | 기기의 FCM token 등록·해제 |

### 주기적으로 갱신하는 화면

| 화면·기능 | 주기 | 동작 |
|---|---|---|
| **홈 대시보드** | 5초 | 인형 연결·대화 상태, 감정과 활동 갱신 |
| **가족 대화방** | 10초 | 새 메시지, 읽음 수, 인형 전달 상태, 음성 답장 갱신 |
| **목소리 학습 상태** | 5초 | 학습 진행률을 확인하며 최대 10분 동안 대기 |
| **알림 센터** | 이벤트 | FCM 수신 시 새 알림 목록 다시 불러오기 |

`settings_api.dart`의 `kUseMockSettingsForDevelopment` 기본값은 `false`입니다.
개발용 mock 응답 분기가 있지만 앱 전체를 오프라인으로 실행하는 옵션은 아닙니다.

---

## 🧪 테스트와 빌드

### 정적 분석과 테스트

```bash
flutter analyze
flutter test
```

| 테스트 | 확인 내용 |
|---|---|
| `chat_room_test.dart` | 전달 상태·미확인 인원·날짜 구분선·음성 답장 이름 |
| `memory_layout_test.dart` | 기억 등록 제목·칩·입력 안내 배치 |
| `mood_caption_test.dart` | 감정 설명 문구 |
| `report_arrows_test.dart` | 오늘 리포트 날짜 이동 |
| `report_calendar_test.dart` | 날짜 선택·기록 없는 날·월 이동 |
| `report_excerpt_test.dart` | 실제 대화 발췌 표시 |
| `weekly_report_test.dart` | 키워드·요일별 감정·빈 기록 |
| `voice_sharing_test.dart` | 목소리 등록자 표시·삭제 권한 |

패스키·SMS·푸시·녹음·업로드는 백엔드와 플랫폼 설정을 갖춘 실제 기기 환경에서 별도로 확인합니다.

### 릴리스 빌드

```bash
# Android
flutter build apk --release

# iOS — macOS와 Xcode 필요
flutter build ios --release
```

---

## 🔗 관련 저장소

- [ReMory Hardware](https://github.com/Hanium-Remory/Hanium-Remory-HW)
- [ReMory Backend](https://github.com/Hanium-Remory/Hanium-Remory-BE)
