#!/usr/bin/env bash
# =============================================================================
#  Camera ITS 자동 셋업 + 실행 스크립트
#
#  - DUT(폰) 권한 설정은 세션이 끊기면 사라지므로, 매번 이 스크립트를 다시
#    실행해도 안전하도록 멱등성(idempotent) 있게 작성함.
#  - 노트북 재부팅 / USB 재연결 / DUT 재부팅 후에 그대로 다시 돌리면 됨.
#
#  사용법:
#      cd ~/ai_analyze_ITS16/Android16.1-cts/CameraITS
#      bash setup_and_run.sh
#
#  디바이스가 바뀌면 환경변수로 덮어쓰기 가능:
#      DEVICE_ID=다른시리얼 bash setup_and_run.sh
# =============================================================================

DEVICE_ID="${DEVICE_ID:-R5KL309P2KR}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- 출력 색상 / 헬퍼 ----------
RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'
BLUE='\033[34m'; BOLD='\033[1m'; RST='\033[0m'

hdr()  { echo; echo -e "${BOLD}${BLUE}━━━ $1 ━━━${RST}"; }
info() { echo -e "${BLUE}[INFO]${RST} $1"; }
ok()   { echo -e "${GREEN}[OK]${RST}   $1"; }
warn() { echo -e "${YELLOW}[WARN]${RST} $1"; }
err()  { echo -e "${RED}[ERR]${RST}  $1"; }

cd "$SCRIPT_DIR" || { err "작업 디렉터리 이동 실패: $SCRIPT_DIR"; exit 1; }

# =============================================================================
# 1. 디바이스 연결 확인
#    WSL 환경에서는 adb 출력에 CR(\r) 이 따라오는 경우가 있어, awk 로 컬럼
#    파싱하면 비교가 어긋날 수 있다. 가장 안정적인 'adb get-state' 사용.
# =============================================================================
hdr "1. 디바이스 연결 확인 (adb get-state)"

STATE=$(adb -s "${DEVICE_ID}" get-state 2>&1 | tr -d '\r\n[:space:]')
if [[ "$STATE" != "device" ]]; then
    err "DUT(${DEVICE_ID}) 가 'device' 상태가 아닙니다. 현재 상태: '${STATE:-(없음)}'"
    echo
    info "현재 adb devices 출력:"
    adb devices
    echo
    info "USB 케이블·디버깅 허용·잠금 해제를 확인하고 다시 실행하세요."
    exit 1
fi
ok "DUT 인식: ${DEVICE_ID} (state=device)"

# Tablet 도 같이 확인 (있으면 안내, 없으면 경고만)
TABLET_ID="${TABLET_ID:-R32XB004ZLM}"
TSTATE=$(adb -s "${TABLET_ID}" get-state 2>&1 | tr -d '\r\n[:space:]')
if [[ "$TSTATE" == "device" ]]; then
    ok "Tablet 인식: ${TABLET_ID} (state=device)"
else
    warn "Tablet(${TABLET_ID}) 미연결 — Tablet 씬은 실행 불가. (state='${TSTATE:-(없음)}')"
fi

# =============================================================================
# 2. adb forward tcp:6000 확인 / 설정
# =============================================================================
hdr "2. adb forward tcp:6000 확인"

# 사용자가 bashrc 에 정의해둔 start_adb_fwd 함수가 있다면 실행
if command -v start_adb_fwd >/dev/null 2>&1; then
    info "start_adb_fwd 실행"
    start_adb_fwd || warn "start_adb_fwd 실행 실패 (계속 진행)"
fi

if adb forward --list | grep -q "tcp:6000.*tcp:6000"; then
    ok "6000 포트 이미 forward 됨"
else
    warn "6000 포트 forward 없음 — 직접 적용"
    adb -s "${DEVICE_ID}" forward tcp:6000 tcp:6000
    if adb forward --list | grep -q "tcp:6000.*tcp:6000"; then
        ok "6000 포트 forward 완료"
    else
        err "6000 포트 forward 실패 — 수동 확인 필요"
    fi
fi

# =============================================================================
# 3. CtsVerifier 권한 (세션 단위 — 매번 적용 필요)
# =============================================================================
hdr "3. CtsVerifier 권한 설정 (세션마다 재적용)"

info "(Android 13+) ALLOW_TEST_API_ACCESS"
adb -s "${DEVICE_ID}" shell am compat enable ALLOW_TEST_API_ACCESS \
    com.android.cts.verifier 2>&1 | sed 's/^/        /'

info "(Android 10+) read_device_identifiers allow"
adb -s "${DEVICE_ID}" shell appops set com.android.cts.verifier \
    android:read_device_identifiers allow

info "(Android 11+) MANAGE_EXTERNAL_STORAGE"
adb -s "${DEVICE_ID}" shell appops set com.android.cts.verifier \
    MANAGE_EXTERNAL_STORAGE 0

info "(Android 14+) TURN_SCREEN_ON"
adb -s "${DEVICE_ID}" shell appops set com.android.cts.verifier \
    TURN_SCREEN_ON 0

ok "CtsVerifier 권한 4종 적용 완료"

# =============================================================================
# 4. 삼성 기본 카메라 앱(com.sec.android.app.camera) 권한
# =============================================================================
hdr "4. 삼성 기본 카메라 앱 권한 부여"

SAMSUNG_CAM="com.sec.android.app.camera"
PERMS=(
    "android.permission.CAMERA"
    "android.permission.RECORD_AUDIO"
    "android.permission.ACCESS_FINE_LOCATION"
    "android.permission.READ_MEDIA_IMAGES"
    "android.permission.READ_MEDIA_VIDEO"
)

for PERM in "${PERMS[@]}"; do
    info "pm grant ${PERM##*.}"
    OUT=$(adb -s "${DEVICE_ID}" shell pm grant "${SAMSUNG_CAM}" "$PERM" 2>&1)
    if [[ -n "$OUT" ]]; then
        echo "        ${OUT}"
    fi
done
ok "삼성 카메라 권한 5종 적용 완료"

# =============================================================================
# 5. 사용자 수동 확인 (DUT 화면에서 직접 작업)
# =============================================================================
hdr "5. (수동 확인) DUT 에서 기본 카메라 앱 정상 동작 점검"
cat <<'EOM'

  다음 작업을 DUT(폰) 화면에서 직접 해주세요.
  ※ 이미 한 번 해봤다면 그냥 [Enter] 로 지나가도 됩니다.

    1) 기본 카메라 앱을 한 번 켠다
    2) 첫 실행 시 나오는 모든 약관 / 팝업에 동의
    3) 사진 한 장 찍어 정상 동작 확인
    4) 카메라 앱 종료

EOM
read -r -p "  준비되면 [Enter] 를 눌러 진행 : " _

# =============================================================================
# 6. build/envsetup.sh 적용 (PYTHONPATH 등)
# =============================================================================
hdr "6. build/envsetup.sh 적용"
if [[ -f "build/envsetup.sh" ]]; then
    # 같은 셸 안에서 source — 이후 단계의 python 호출에 PYTHONPATH 등이 반영됨
    # shellcheck disable=SC1091
    source build/envsetup.sh
    ok "envsetup.sh 적용 완료"
else
    err "build/envsetup.sh 가 없습니다. 현재 폴더: $(pwd)"
    exit 1
fi

# =============================================================================
# 7. 실행 모드 선택 (1=전체 자동 / 2=수동 타이핑)
# =============================================================================
hdr "7. 실행 모드 선택"
cat <<'EOM'

  어떻게 진행할까요?

    [1]  전체 풀테스트 자동 실행
           → python3 tools/run_all_tests.py  (config.yml 대로, ~3시간)

    [2]  수동 입력 모드
           → envsetup 이 적용된 새 셸로 진입.
             직접 명령을 타이핑하여 단일 씬/카메라만 돌릴 수 있음.
             예) python3 tools/run_all_tests.py camera=0 scenes=1_1
             예) python3 tests/scene6/test_zoom.py -c test_config.yml
             종료하려면 'exit' 입력.

EOM
read -r -p "  선택 [1/2] : " CHOICE
echo

case "$CHOICE" in
    1)
        hdr "풀테스트 시작 — python3 tools/run_all_tests.py"
        info "Ctrl+C 로 언제든 중단 가능. 로그는 /tmp/CameraITS_*/ 에 저장."
        echo
        python3 tools/run_all_tests.py
        ;;
    2)
        hdr "수동 모드 — envsetup 적용된 새 셸로 진입"
        info "프롬프트 앞에 [ITS] 가 표시됩니다. 종료: exit"
        echo

        # 새 인터랙티브 bash 셸을 띄우되, envsetup 을 자동 재적용하도록
        # 임시 rc 파일을 만들어 --rcfile 로 전달한다.
        TMP_RC=$(mktemp /tmp/its_rc.XXXXXX)
        cat > "$TMP_RC" <<RCFILE
# 사용자 기본 환경 로드
[ -f "\$HOME/.bashrc" ] && source "\$HOME/.bashrc"
# CameraITS envsetup 재적용
cd "${SCRIPT_DIR}"
source build/envsetup.sh 2>/dev/null
# 시각적 구분용 프롬프트
PS1='\[\033[1;34m\][ITS]\[\033[0m\] \w\$ '
echo
echo "  ★ ITS 수동 모드. envsetup 이 적용된 상태입니다."
echo "    예시:  python3 tools/run_all_tests.py camera=0 scenes=1_1"
echo "    종료:  exit"
echo
# 셸 종료 시 임시 rc 파일 정리
trap "rm -f '$TMP_RC'" EXIT
RCFILE
        bash --rcfile "$TMP_RC" -i
        rm -f "$TMP_RC"
        ;;
    *)
        warn "올바르지 않은 선택입니다. 종료합니다."
        info "다음에 다시 실행하려면: bash setup_and_run.sh"
        exit 0
        ;;
esac

hdr "스크립트 종료"
info "세션이 끊긴 후 다시 실행하려면: bash setup_and_run.sh"
