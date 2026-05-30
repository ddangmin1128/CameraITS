#!/usr/bin/env bash
# =============================================================================
#  Camera ITS 자동 셋업 + 실행 스크립트 (반복 실행 기능 포함)
#
#  - DUT(폰) 권한 설정은 세션이 끊기면 사라지므로, 매번 이 스크립트를 다시
#    실행해도 안전하도록 멱등성(idempotent) 있게 작성함.
#  - 노트북 재부팅 / USB 재연결 / DUT 재부팅 후에 그대로 다시 돌리면 됨.
#
#  사용법:
#      cd ~/ai_analyze_ITS16/Android16.1-cts/CameraITS
#      bash setup_and_run_repeat.sh
#
#  디바이스가 바뀌면 환경변수로 덮어쓰기 가능:
#      DEVICE_ID=다른시리얼 bash setup_and_run_repeat.sh
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

# WSL 환경에서 adb 데몬이 꺼져 있으면 첫 호출 때 기동 메시지가 결과에 섞임.
# 'adb start-server' 로 데몬을 먼저 올리고 장치 목록이 안정될 때까지 재시도.
adb start-server > /dev/null 2>&1
for _retry in 1 2 3 4 5; do
    STATE=$(adb -s "${DEVICE_ID}" get-state 2>&1 | tr -d '\r\n[:space:]')
    [[ "$STATE" == "device" ]] && break
    info "데몬 기동 대기 중… (${_retry}/5)"
    sleep 2
done
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

# bashrc 에 정의된 start_adb_fwd 함수 확인 (non-interactive 스크립트에서는
# bash -i -c 로 호출해야 bashrc 함수가 로드됨)
if bash -i -c "declare -f start_adb_fwd" >/dev/null 2>&1; then
    info "start_adb_fwd 함수 발견 — 실행 시작"
    echo -e "${BOLD}━━━ start_adb_fwd 출력 시작 ━━━${RST}"
    bash -i -c "start_adb_fwd" 2>&1
    FWD_EXIT=$?
    echo -e "${BOLD}━━━ start_adb_fwd 출력 끝 (종료 코드: ${FWD_EXIT}) ━━━${RST}"
    echo
    if [[ $FWD_EXIT -ne 0 ]]; then
        warn "start_adb_fwd 실패 (exit=${FWD_EXIT}) — 계속 진행"
    else
        ok "start_adb_fwd 정상 완료"
    fi

    # start_adb_fwd 실행 후 adb forward --list 즉시 확인
    info "▶ start_adb_fwd 실행 후 adb forward --list 결과:"
    echo -e "${BOLD}────────────────────────────────${RST}"
    adb forward --list 2>&1
    echo -e "${BOLD}────────────────────────────────${RST}"
    echo

    # devices 목록 안정화 대기
    info "devices 목록 안정화 대기 중..."
    sleep 3
    for _wait in $(seq 1 20); do
        DEVLIST=$(adb devices 2>&1)
        if echo "$DEVLIST" | grep -q "${DEVICE_ID}"; then
            ok "devices 목록에서 ${DEVICE_ID} 확인됨 (${_wait}번째 시도)"
            break
        fi
        info "  아직 미인식 (${_wait}/20) — 2초 후 재확인..."
        sleep 2
        if [[ "$_wait" -eq 20 ]]; then
            warn "20회 시도 후에도 ${DEVICE_ID} 미인식 — 계속 진행 (수동 확인 필요)"
        fi
    done
    echo
    info "현재 adb devices:"
    adb devices
    echo
    sleep 1
else
    warn "start_adb_fwd 함수를 찾지 못했습니다 (bashrc 미정의 또는 미로드)"
fi

if adb forward --list | grep -q "tcp:6000.*tcp:6000"; then
    ok "6000 포트 이미 forward 됨"
else
    warn "6000 포트 forward 없음 — 직접 적용"
    sleep 1
    adb -s "${DEVICE_ID}" forward tcp:6000 tcp:6000
    sleep 1
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
sleep 1

info "(Android 10+) read_device_identifiers allow"
adb -s "${DEVICE_ID}" shell appops set com.android.cts.verifier \
    android:read_device_identifiers allow
sleep 1

info "(Android 11+) MANAGE_EXTERNAL_STORAGE"
adb -s "${DEVICE_ID}" shell appops set com.android.cts.verifier \
    MANAGE_EXTERNAL_STORAGE 0
sleep 1

info "(Android 14+) TURN_SCREEN_ON"
adb -s "${DEVICE_ID}" shell appops set com.android.cts.verifier \
    TURN_SCREEN_ON 0
sleep 1

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
    sleep 1
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
    # shellcheck disable=SC1091
    source build/envsetup.sh
    ok "envsetup.sh 적용 완료"
else
    err "build/envsetup.sh 가 없습니다. 현재 폴더: $(pwd)"
    exit 1
fi

# =============================================================================
# 7. 실행 모드 선택
# =============================================================================
hdr "7. 실행 모드 선택"
cat <<'EOM'

  어떻게 진행할까요?

    [1]  전체 풀테스트
           → python3 tools/run_all_tests.py  (config.yml 대로, ~3시간)

    [2]  수동 입력 모드
           → 실행할 명령어를 직접 입력. 해당 명령어를 반복 실행함.
             예) python3 tools/run_all_tests.py camera=0 scenes=1_1

EOM
read -r -p "  선택 [1/2] : " CHOICE
echo

if [[ "$CHOICE" != "1" && "$CHOICE" != "2" ]]; then
    warn "올바르지 않은 선택입니다. 종료합니다."
    info "다음에 다시 실행하려면: bash setup_and_run_repeat.sh"
    exit 0
fi

# 수동 모드일 때 명령어를 미리 한 번만 입력받음
if [[ "$CHOICE" == "2" ]]; then
    read -r -p "  실행할 명령어 : " USER_CMD
    echo
    if [[ -z "$USER_CMD" ]]; then
        err "명령어를 입력하지 않았습니다. 종료합니다."
        exit 1
    fi
fi

# =============================================================================
# 8. 반복 횟수 선택
# =============================================================================
hdr "8. 반복 횟수 선택"
cat <<'EOM'

  몇 번 반복할까요?

    숫자 입력  → 해당 횟수만큼 반복 후 종료
    0 또는 Enter → Ctrl+C 를 누를 때까지 무한 반복

EOM
read -r -p "  반복 횟수 [숫자 / 0 / Enter] : " MAX_RUNS
echo

if [[ -z "$MAX_RUNS" || "$MAX_RUNS" -eq 0 ]] 2>/dev/null; then
    MAX_RUNS=0
    info "무한 반복 모드 — Ctrl+C 를 누르면 종료됩니다."
else
    if ! [[ "$MAX_RUNS" =~ ^[0-9]+$ ]]; then
        err "숫자만 입력 가능합니다. 종료합니다."
        exit 1
    fi
    info "${MAX_RUNS}회 반복합니다."
fi
echo

# Ctrl+C 시 루프만 중단
INTERRUPTED=false
trap 'echo; warn "Ctrl+C 감지 — 현재 회차 완료 후 중단합니다."; INTERRUPTED=true' INT

# =============================================================================
# 실행 루프
# =============================================================================
RUN_COUNT=0
while true; do
    if $INTERRUPTED; then
        break
    fi
    if [[ "$MAX_RUNS" -gt 0 && "$RUN_COUNT" -ge "$MAX_RUNS" ]]; then
        break
    fi

    RUN_COUNT=$((RUN_COUNT + 1))

    if [[ "$MAX_RUNS" -gt 0 ]]; then
        hdr "실행 ${RUN_COUNT} / ${MAX_RUNS} 회차"
    else
        hdr "실행 ${RUN_COUNT}회차 (무한 — Ctrl+C 로 중단)"
    fi

    case "$CHOICE" in
        1)
            python3 tools/run_all_tests.py
            EXIT_CODE=$?
            if [[ $EXIT_CODE -ne 0 ]]; then
                warn "테스트 종료 코드: ${EXIT_CODE}"
            fi
            ;;
        2)
            info "실행: ${USER_CMD}"
            eval "$USER_CMD"
            EXIT_CODE=$?
            if [[ $EXIT_CODE -ne 0 ]]; then
                warn "종료 코드: ${EXIT_CODE}"
            fi
            ;;
    esac

    sleep 3
done

trap - INT

echo
if $INTERRUPTED; then
    warn "반복 실행 중단됨 (완료 횟수: ${RUN_COUNT}회)"
else
    ok "반복 실행 완료 (총 ${RUN_COUNT}회)"
fi

hdr "스크립트 종료"
info "세션이 끊긴 후 다시 실행하려면: bash setup_and_run_repeat.sh"
