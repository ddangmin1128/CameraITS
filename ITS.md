
# CTS

- https://source.android.com/docs/compatibility/cts  

## History

- [Github CTS Issues](https://github.samsungds.net/RTASYS/BRCK_CoWork/issues?q=label%3A%22CTS+Issue%22+is%3Aclosed+)



## Work Summary

- 카메라와 관련된 CTS 항목들에 대한 이슈 발생 시 원인 분석을 진행하는 업무   

- ex) 기존에 Pass 되던 항목이 Fail 되는 경우 : 원인 커밋 분석 및 해결



## Setup

<details>

<summary>(📁 접기/펼치기)</summary>



  

**1.** [**Download**](https://source.android.com/docs/compatibility/cts/downloads)  

- Test 진행 OS의 Android 버전에 맞게 다운로드, 구글에 아직 업로드 되지 않은 경우,  

고객사에서 테스트 환경 셋업 파일을 제공합니다.  

칩셋에 맞는 아키텍쳐로 다운 받아주세요. (Exynos 의 경우 ARM 베이스로 고르시면 됩니다.)  

CTS의 경우 [Android 14 R5 Compatibility Test Suite (CTS) - ARM](https://dl.google.com/dl/android/cts/android-cts-14_r5-linux_x86-arm.zip) 와 같은 파일을 다운받아, 

자신이 쓰는 WSL 환경에 압축 해제 해주세요.



```

hjlim@KORCO131182:~/android-cts-14_r5-linux_x86-arm/android-cts$ ls -al

total 6016

drwxr-xr-x 1 hjlim hjlim    4096 Aug 21 16:19 .

drwxr-xr-x 1 hjlim hjlim    4096 Aug 21 15:00 ..

-rwxr--r-- 1 hjlim hjlim 5336356 Jan  1  2008 NOTICE.txt

drwxr-xr-x 1 hjlim hjlim    4096 Aug 21 15:02 jdk

drwxr-xr-x 1 hjlim hjlim    4096 Aug 21 16:24 logs

drwxr-xr-x 1 hjlim hjlim    4096 Aug 21 16:24 results

drwxr-xr-x 1 hjlim hjlim    4096 Aug 21 16:19 subplans

drwxr-xr-x 1 hjlim hjlim    4096 Jan  1  2008 testcases

drwxr-xr-x 1 hjlim hjlim    4096 Jan  1  2008 tools

```



**2. Proxy Setting**  



- net.properties 파일에 자신이 사용중인 프록시 정보를 입력 

```

vi ~/android-cts-14_r5-linux_x86-arm/android-cts/jdk/conf/net.properties



#...

java.net.useSystemProxies=true

#...

http.proxyHost=12.127.100.100

http.proxyPort=8080

#...

https.proxyHost=12.127.100.100

https.proxyPort=8080

jdk.http.auth.proxying.disabledSchemes=

jdk.http.auth.tunneling.disabledSchemes=

```



**3.Certficate Setting**  

- FTP : **/Brycen_Shared/Tools/CTS/certficate_related** 에서 **McAfee_Certificate.cer** 파일을 아래 경로로 복사  

아래 예시는 D드라이브에 미리 McAfee_Certificate.cer 파일을 받아두었습니다.

```

hjlim@KORCO131182:~$ cp /mnt/d/McAfee_Certificate.cer ~/android-cts-14_r5-linux_x86-arm/android-cts/jdk/lib/security/

```

- 이후 아래 경로로 이동 후, keytool 명령어 입력하여  

**Certificate was added to keystore** 출력 확인

```

cd ~/android-cts-14_r5-linux_x86-arm/android-cts/jdk/lib/security

keytool -import -trustcacerts -keystore cacerts -storepass changeit -noprompt -alias semi -file McAfee_Certificate.cer

```



**4. aapt2 버전 변경**



- 아래와 같이 aapt 관련 에러 메시지가 발생할 경우, aapt2 버전을 변경해주면 해결됩니다.

```

* Sample error message

05-20 10:10:26 E/AaptParser: aapt2 dump badging stderr: W/ziparchive( 1481): Unable to open 'badging': No such file or directory

badging: error: No such file or directory.

05-20 10:10:26 E/AaptParser: Failed to run aapt2 on /home/dongww/cts/sqe/android-cts/tools/../../android-cts/testcases/CtsCameraTestCases/arm64/CtsCameraTestCases.apk. stdout:

05-20 10:10:26 E/ModuleDefinition: Unexpected Exception from preparer: com.android.tradefed.targetprep.suite.SuiteApkInstaller

05-20 10:10:26 E/ModuleDefinition: AaptParser failed for file CtsCameraTestCases.apk. The APK won't be installed

```



- FTP : **/Brycen_Shared/Tools/CTS/Android** 폴더를 받아, 원하는 디렉토리로 이동시켜 주세요.  

저는 ~/tools/에 복사하였습니다.

```

hjlim@KORCO131182:~/tools$ ll

total 0

drwxr-xr-x 1 hjlim hjlim 4096 Nov  2  2023 ./

drwxr-xr-x 1 hjlim hjlim 4096 Aug 21 15:56 ../

drwxr-xr-x 1 hjlim hjlim 4096 Jul  3  2023 Android/

```

- ~/.bashrc 파일에 아래 환경변수 추가

```

vim ~/.bashrc



# CTS settings 

export PATH=/home/hjlim/tools/Android/Sdk/build-tools/34.0.0:$PATH



source ~/.bashrc

```



- 이후 아래 명령어로 aapt 와 aapt2 심볼릭 링크 변경

```

cd /usr/bin

sudo rm aapt

sudo ln -s ~/tools/Android/Sdk/build-tools/34.0.0/aapt aapt

sudo rm aapt2

sudo ln -s ~/tools/Android/Sdk/build-tools/34.0.0/aapt2 aapt2

```



- 결과적으로 아래처럼 버전 확인

```

hjlim@KORCO131182:~$ aapt version

Android Asset Packaging Tool, v0.2-10229193

hjlim@KORCO131182:~$ aapt2 version

Android Asset Packaging Tool (aapt) 2.19-10229193

```



</details>



## CTS 관련 Cheat Sheet

### 테스트 실행 - ./cts-tradefed

```

<프로젝트 경로>/tools$ ./cts-tradefed

..

Android Compatibility Test Suite 14_r5 (12186525)

Use "help" or "help all" to get more information on running commands.

08-21 16:10:48 I/DeviceManager: Detected new device <>

cts-tf >

```

### Sample Commands

```

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.cts.CameraTest#testImmediateZoom

run cts --plan CTS -m CtsCameraTestCases -t android.hardware.cts.LegacyCameraPerformanceTest --logcat-on-failure --skip-preconditions --disable-reboot 

run cts --plan CTS -m CtsCameraTestCases -t android.hardware.camera2.cts.BurstCaptureRawTest --skip-preconditions --disable-reboot --skip-device-info -l VERBOSE

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.camera2.cts.MultiViewTest#testDualCameraPreview[1]

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.camera2.cts.CameraTest --subplan testImmediateZoom

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.cts.CameraTest#testImmediateZoom

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.camera2.cts.ConcurrentCameraTest#testMandatoryConcurrentStreamCombination[1]

run cts -m CtsCameraTestCases --abi arm64-v8a --test android.hardware.camera2.cts.ConcurrentCameraTest

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.camera2.cts.DngCreatorTest#testDngRenderingByBitmapFactor[1]



# 아래 명령어는 전체 CtsCameraTestCases 실행 약 14시간 소요

run cts --plan CTS -m CtsCameraTestCases -t android.hardware.cts.CameraTest --skip-preconditions --disable-reboot --skip-device-info -l VERBOSE --logcat-on-failure

run cts --plan CTS -m CtsCameraTestCases -t android.hardware.camera2.cts



# Class 단위의 테스트 명령어

adb shell am instrument -e class android.hardware.camera2.cts.CaptureRequestTest#testFlashControl --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.CaptureRequestTest#testFlashControl --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.RobustnessTest#testAfThenAeTrigger --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.RobustnessTest#testAeThenAfTrigger --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.RobustnessTest#testAeAndAfCausality --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.RobustnessTest#testBasicTriggerSequence --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.RobustnessTest#testSimultaneousTriggers --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner

adb shell am instrument -e class android.hardware.camera2.cts.StillCaptureTest#testAePrecaptureTriggerCancelJpegCapture --abi arm64-v8a -w android.camera.cts/androidx.test.runner.AndroidJUnitRunner 



# 기타 다른 모듈 및 옵션 소개

run cts --plan CTS -m CtsCameraTestCases --skip-preconditions --disable-reboot --logcat-on-failure --skip-system-status-check com.android.compatibility.common.tradefed.targetprep.NetworkConnectivityChecker --skip-system-status-check com.android.tradefed.suite.checker.KeyguardStatusChecker --dynamic-config-url=""

run cts --module CtsAccountManagerTestCases --test android.accounts.cts.AbstractAuthenticatorTests#testIsCredentialsUpdateSuggestedDefaultImpl

run cts --module CtsAccountManagerTestCases --test android.accounts.cts.AbstractAuthenticatorTests#testIsCredentialsUpdateSuggestedDefaultImpl --skip-preconditions --disable-reboot --skip-system-status-check com.android.compatibility.common.tradefed.targetprep.NetworkConnectivityChecker --skip-system-status -check com.android.tradefed.suite.checker.KeyguardStatusChecker --dynamic-config-url=""



# Camera Sensor 전체 Open test

run cts -m CtsCameraTestCases --abi arm64-v8a --skip-preconditions --test android.hardware.camera2.cts.MultiViewTest#testDualCameraPreview[1]

```



### Sample Results

최종 log 는 /tmp/ 경로에 저장됩니다.

```

================= Results ==================

=============== Consumed Time ==============

    arm64-v8a CtsCameraTestCases: 1m 14s

    arm64-v8a CtsCameraTestCases[instant]: 1m 11s

Total aggregated tests run time: 2m 26s

============== TOP 2 Slow Modules ==============

    arm64-v8a CtsCameraTestCases: 0.01 tests/sec [1 tests / 74412 msec]

    arm64-v8a CtsCameraTestCases[instant]: 0.01 tests/sec [1 tests / 71952 msec]

============== Modules Preparation Times ==============

    arm64-v8a CtsCameraTestCases => prep = 6742 ms || clean = 809 ms

    arm64-v8a CtsCameraTestCases[instant] => prep = 5460 ms || clean = 846 ms

Total preparation time: 12s  ||  Total tear down time: 1s

=======================================================

=============== Summary ===============

Total Run time: 4m 40s

2/2 modules completed

Total Tests       : 2

PASSED            : 2

FAILED            : 0

============== End of Results ==============

============================================

08-21 16:24:37 D/ProtoResultReporter: process final logs: /tmp/12186525/cts/inv_8882512014154601932/inv_10891010768449972538/end_host_log_16801195045398482992.txt

08-21 16:24:37 I/CommandScheduler: Updating command 3 with elapsed time 281340 ms

08-21 16:24:37 I/CommandScheduler: Finalizing the logger and invocation.

08-21 16:24:37 D/ActiveTrace: Finalizing trace: /tmp/invocation-trace13021426778236329523.perfetto-trace

08-21 16:24:37 D/ProtoResultReporter: process final logs: /tmp/12186525/cts/inv_8882512014154601932/inv_10891010768449972538/invocation-trace_7383746635582040063.perfetto-trace.gz

08-21 16:24:37 D/ProtoResultReporter: process final logs: /tmp/12186525/cts/inv_8882512014154601932/inv_10891010768449972538/invoc_complete_host_log_2926028368922621546.txt

```



## CTS 진행중인지 확인하고 싶을때 

```

1. cts 테스트 중인 cmd 창은 계속 놔둬야 함.

2. wsl 창을 새로 open

3. adb -s R3CW70NCK5A logcat | grep -iE "camera|camx|hal" 

4. log 가 빠르게 올라가는게 보이면 진행중임. (아무런 로그가 올라오지 않거나, 특정에러를 뱉고 멈춰있다면

기기의 카메라 모듈이 뻗은 상태.(feat.gemini)



```

---

### WSL 설정 



https://github.samsungds.net/SLSISE/PANDO/wiki/WSL#adb-forwarding

```

export WSL_HOST_ADB='/mnt/e/zz_App/platform-tools/adb.exe' 

export HOST_IP='10.229.xx.yyy'







start_adb_fwd() {

  if ! [ -x "$(command -v socat)" ]; then

    echo 'Please install socat first:' >&2

    echo 'sudo apt update && sudo apt install -y socat'

    return 1

  fi



  # stop service

  stop_adb_fwd



#  echo "Get adb devices on host..."

#  $WSL_HOST_ADB devices

#  sleep 3

  $WSL_HOST_ADB kill-server

  sleep 2



  echo "Start services..."

  nohup $WSL_HOST_ADB -a nodaemon server start > /dev/null 2>&1 &

  nohup socat TCP-LISTEN:5037,reuseaddr,fork TCP:${HOST_IP}:5037 > /dev/null 2>&1 &

  sleep 1

  echo "Forward adb to ${HOST_IP}:5037."

  echo



  echo "Get adb devices..."

  adb devices

}



stop_adb_fwd() {

  echo "Kill running processes..."

  pkill -9 socat



  # $WSL_HOST_ADB kill-server > /dev/null 2>&1

  # adb kill-server > /dev/null 2>&1



  pkill -9 adb.exe

  pkill -9 adb

  sleep 1

  echo "Complete"

}

```

  

.bashrc 파일에 위의 코드를 복사/붙여넣기 하고, WSL_HOST_ADB 및 HOST_IP 부분 수정  

WSL_HOST_ADB는 cmd 창에서 adb 명령어 실행시 위에 나오는 경로를 사용 ( Windows 경로 사용 )  

HOST_IP는 cmd 창에서 ipconfig 실행시 나오는 IPv4 IP값을 사용 ( Windows IP 사용 )  

  

ex)  

 

```

export WSL_HOST_ADB='/mnt/e/zz_App/platform-tools/adb.exe' 

export HOST_IP='10.229.xx.yyy' 

```







---



# ITS

Android 공식 ITS 문서

- https://source.android.com/docs/compatibility/cts/camera-its



## History

- [Github ITS Issues](https://github.samsungds.net/RTASYS/BRCK_CoWork/issues?q=label%3A%22ITS+issue%22+is%3Aclosed+)



## Work Summary

카메라 ITS와 관련된 이슈 발생 시 원인 분석을 진행하는 업무  

ex) 기존에 Pass 되던 항목이 Fail 되는 경우 : 원인 커밋 분석 및 해결



## Setup

<details>

<summary>(📁 접기/펼치기)</summary>



**1.** [**Download**](https://source.android.com/docs/compatibility/cts/downloads)  

Test 진행 OS의 Android 버전에 맞게 다운로드, 구글에 아직 업로드 되지 않은 경우, 고객사에서 테스트 환경 셋업 파일을 제공합니다.  

칩셋에 맞는 아키텍쳐로 다운 받아주세요. (Exynos 의 경우 ARM 베이스로 고르시면 됩니다.)  

ITS 의 경우 [Android 14 R5 CTS Verifier - ARM](https://dl.google.com/dl/android/cts/android-cts-verifier-14_r5-linux_x86-arm.zip) 와 같은 파일을 받아주세요.

```

hjlim@KORCO131182:~/android-cts-verifier$ ll

total 34348

drwxr-xr-x 1 hjlim hjlim     4096 Aug 21 14:50 ./

drwxr-xr-x 1 hjlim hjlim     4096 Aug 22 10:01 ../

drwxr-xr-x 1 hjlim hjlim     4096 Aug 22 09:23 CameraITS/

drwxr-xr-x 1 hjlim hjlim     4096 Aug 21 14:50 CameraWebcamTest/

-rwxr--r-- 1 hjlim hjlim    16925 Jan  1  2008 CrossProfileTestApp.apk*

-rwxr--r-- 1 hjlim hjlim    12787 Jan  1  2008 CtsCarWatchdogCompanionApp.apk*

-rwxr--r-- 1 hjlim hjlim  1287711 Jan  1  2008 CtsDefaultNotesApp.apk*

-rwxr--r-- 1 hjlim hjlim   685554 Jan  1  2008 CtsDeviceControlsApp.apk*

-rwxr--r-- 1 hjlim hjlim    12765 Jan  1  2008 CtsEmptyDeviceAdmin.apk*

-rwxr--r-- 1 hjlim hjlim  2883202 Jan  1  2008 CtsEmptyDeviceOwner.apk*

-rwxr--r-- 1 hjlim hjlim    21042 Jan  1  2008 CtsForceStopHelper.apk*

-rwxr--r-- 1 hjlim hjlim    50037 Jan  1  2008 CtsPermissionApp.apk*

-rwxr--r-- 1 hjlim hjlim    12695 Jan  1  2008 CtsTileServiceApp.apk*

-rwxr--r-- 1 hjlim hjlim    12695 Jan  1  2008 CtsTtsEngineSelectorTestHelper.apk*

-rwxr--r-- 1 hjlim hjlim    12695 Jan  1  2008 CtsTtsEngineSelectorTestHelper2.apk*

-rwxr--r-- 1 hjlim hjlim 28191843 Jan  1  2008 CtsVerifier.apk*

-rwxr--r-- 1 hjlim hjlim    12770 Jan  1  2008 CtsVerifierInstantApp.apk*

-rwxr--r-- 1 hjlim hjlim   841425 Jan  1  2008 CtsVerifierUSBCompanion.apk*

-rwxr--r-- 1 hjlim hjlim    20958 Jan  1  2008 CtsVpnFirewallAppApi23.apk*

-rwxr--r-- 1 hjlim hjlim    20958 Jan  1  2008 CtsVpnFirewallAppApi24.apk*

-rwxr--r-- 1 hjlim hjlim    20958 Jan  1  2008 CtsVpnFirewallAppNotAlwaysOn.apk*

-rwxr--r-- 1 hjlim hjlim   961803 Jan  1  2008 NOTICE.txt*

-rwxr--r-- 1 hjlim hjlim    37750 Jan  1  2008 NotificationBot.apk*

```



**2. CtsVerifier.apk 설치**

```

# apk 설치

adb root

adb install -g -d -r CtsVerifier.apk



# 설치 완료

Performing Streamed Install

Success



# (필수) Android 13 이상 : CTS 인증 도구의 테스트 API 액세스 허용 

adb shell am compat enable ALLOW_TEST_API_ACCESS com.android.cts.verifier

- Enabled change 166236554 for com.android.cts.verifier.



# Android 10 이상 : 앱에 보고서를 생성할 권한 허용

adb shell appops set com.android.cts.verifier android:read_device_identifiers allow



# Android 11 이상 : 보고서 저장용 외부 최상위 디렉터리 액세스 허용

adb shell appops set com.android.cts.verifier MANAGE_EXTERNAL_STORAGE 0



# Android 14 이상 : 앱에 화면 켜는 권한을허용

adb shell appops set com.android.cts.verifier TURN_SCREEN_ON 0

```

- 앱이 안켜지거나, ITS 실행이 안될경우 아래 링크를 참고해주세요  

[Using CTS Verifier](https://source.android.com/docs/compatibility/cts/verifier)



**3. ITS envsetup**

- 환경 설정 가이드 : [Camera ITS - Setup](https://source.android.com/docs/compatibility/cts/camera-its)  

필요한 라이브러리들을 설치한 후 아래처럼 출력 되면 환경 설정 완료.

```

hjlim@KORCO131182:~/android-cts-verifier/CameraITS$ source build/envsetup.sh

CAMERA_ITS_TOP=/home/hjlim/android-cts-verifier/CameraITS



*****Please execute below adb command on your dut before running the tests*****



adb -s <device_id> shell am compat enable ALLOW_TEST_API_ACCESS com.android.cts.verifier

```

- 추가 설치가 필요한 라이브러리가 있다고 안내하는 경우,  

라이브러리 설치 후 다시 한번 source build/envsetup.sh 명령어를 실행해 주세요.  

대표적으로 필요한 라이브러리는 아래와 같지만, envsetup.sh 의 안내에 따라주세요

- ITS 16의 경우 필요 라이브러리 명이 다를수 있습니다. 프로그램 실행시 나오는 에러명을 보고 설치 하면 됩니다.

```

sudo apt install aapt

sudo apt install openjdk-11-jdk

sudo apt install python3

sudo apt install python3-pip

sudo apt install python-is-python3

sudo apt install ffmpeg

pip install opencv-python

pip install matplotlib

pip install scipy

pip install pyserial

pip install mobly



- python module 중 PIL 은 pip install pillow 로 변경 됨.

```

- (Tip) 시료 재부팅 이나 재연결 시 source build/envsetup.sh 명령어를 다시 실행해야 앱과 통신할 수 있습니다. 



</details>



# ITS 관련 Cheat Sheet (ITS BOX 없이 dut 단일 테스트)

### **config.yml** - 테스트 환경 설정  

최초 다운로드시 기본 샘플이 입력되어 있으며, 테스트 환경과 Scene, Camera 에 따라 내용을 수정한다.  

고객사는 [Camera ITS-in-a-Box](https://source.android.com/docs/compatibility/cts/camera-its-box) 기준으로 DUT와 Tablet 환경 설정이 되어있기 때문에,  

config가 상이할 수 있다.  

아래 예제는 Rear Camera 0 으로 scene #1 을 테스트한다.

```

TestBeds:

  - Name: TEST_BED_MANUAL

    Controllers:

        AndroidDevice:

          - serial: TEST_SERL_BKR # adb devices 명령어로 실제 시료의 시리얼을 확인해주세요.

            label: dut

    TestParams:

      brightness: 192

      chart_distance: 31.0

      debug_mode: "False"

      lighting_cntl: None

      camera: 0

      foldable_device: "False"

      scene: 1

```   



### **테스트 실행**  

다른 파라미터 없이 아래 명령어로 실행 시, config.yml 이 적용된다.

```

hjlim@KORCO131182:~/android-cts-verifier/CameraITS$ python tools/run_all_tests.py

```



아래 예시 처럼 파라미터 설정도 가능하다.

```

python tools/run_all_tests.py camera=1

python tools/run_all_tests.py scenes=2,1,0

python tools/run_all_tests.py camera=1 scenes=2,1,0

```



### **Sample Results**  

아래 예제의 경우 /tmp/CameraITS_z14ulc5r 경로에 테스트 리포트가 생성된다.  

Scene 별로 환경 셋업이 다르기 때문에  

INFO의 안내에 따라서 chart를 배치한 후 촬영하고 테스트를 실행하자.

```

hjlim@KORCO131182:~/android-cts-verifier/CameraITS$ python tools/run_all_tests.py

INFO:root:Saving test_bed_manual output files to: /tmp/CameraITS_z14ulc5r

INFO:root:Running ITS on device: R3CX503EGND, camera(s): ['0'], scene(s): ['scene1_1', 'scene1_2']

INFO:root:No tablet: manual, sensor_fusion, or scene5 testing.

INFO:root:camera: 0, scene(s): ['scene1_1', 'scene1_2']



 Press <ENTER> after positioning camera 0 with scene1_1.

 The scene setup should be:

  A grey card covering at least the middle 30% of the scene



INFO:root:Capturing an image to check the test scene

INFO:root:Please check scene setup in /tmp/CameraITS_z14ulc5r/cam_id_0/test_scene1_1.jpg

Is the image okay for ITS scene1_1? (Y/N)y

INFO:root:Using config_87szq199.yml as temporary config yml file

INFO:root:Running tests for scene1_1 with camera 0



INFO:root:FAIL  scene1_1/test_3a.py

INFO:root:FAIL  scene1_1/test_ae_af.py

INFO:root:FAIL  scene1_1/test_ae_precapture_trigger.py

INFO:root:FAIL  scene1_1/test_auto_vs_manual.py

```

### **Android16 ITS Test(Thetis 기준)**  

WSL2 / Ubuntu2

ADB 연결 시, Window Local 로 연결 필요



```

self.sock.connect((self.IPADDR, port))

ConnectionRefusedError: [Errno 111] Connection refused



ITS adb 연결 Log

[TEST_BED_TABLET_SCENES] 11-24 13:38:59.889 INFO self.IPADDR: 127.0.0.1

[TEST_BED_TABLET_SCENES] 11-24 13:38:59.889 INFO port: 6000



진행 중인 wsl2 에서 아래 내용 확인



1. port

adb forward --list

6000 확인



2. IP addr

window local PC 연결로 진행하기 때문에

127.0.0.1 local ip 는 맞지 않는 것으로 보임

its_session_utils.py 내,

WSL2 adb HOST_IP 값을 self.IPADDR 로 변경



상기 내용 변경 시, 개별 Test Pass 확인

Test results: Error 0, Executed 1, Failed 0, Passed 1, Requested 1, Skipped 0



추가적으로 전체 Test 의 경우,

python tools/run_all_tests.py camera=1 scenes=2,1,0

```



# ITS 관련 Cheat Sheet (ITS BOX 사용 시)



### Test 진행 환경 : WSL2, ITS 16, python 3.10 이상필요, ITS Box, Tablet 1대, dut 1대(M2 PV2 N)

 



### 1. ITS BOX Test시 사용가능한 Tablet 기기 확인 

- ( allowList 에 있는 기기로만 테스트 진행 가능 )



```

 - 해당 기기 확인 :  adb -s [device_id] shell getprop | grep 'ro.product.device'    

 - 공식 사이트에서 대조 확인 : https://source.android.com/docs/compatibility/cts/camera-its-box?hl=ko#run-tests

 - ITS code 에서 확인 : utils/its_session_utils.py , TABLET_ALLOWLIST 에서 확인 가능



만약, 허용 태블릿 없이 Test 진행하려면 강제로 우회

 - utils/its_session_utils.py , tablet_name 에 강제로 allow list 에 있는 값으로 하드코딩.

 - 이부분 말고, tablet_id 확인 하는곳 모두 찾아서 우회하는 코드 기입해야 함

```



### 2. 이미지 push 필요시 code 확인

- Test시, 태블릿에서 각 시나리오에 맞는 이미지/영상 을 띄어줌

- CamderaITS 폴더에서 태블릿으로 이미지/영상 파일을 push 하게 되어있으나 주석처리 되어있음

(이미 이미지가 저장되어 있다면 push 필요 없을수 있음)

```

/utils/its_session_utils.py

def copy_scenes_to_tablet(scene, tablet_id):  >> 함수안에

subprocess.Popen(cmd.split()) #MoonITS  >> 주석 처리 되어있으면 push cmd 실행 안함.

time.sleep(_COPY_SCENE_DELAY_SEC)  >> for 문 안으로 위치 수정

```



### 3. Test 진행

#### 재시작 할때마다 설정 해줘야 함.

1. USB 연결 후, 시료/태블릿 모두

```

 - Use USB for : Transferring files / Android Auto  선택 체크

 - developer options : Stay awake On 체크

```



2. Test 전 환경 설정

 - start_adb_fwd  ( 재부팅, usb 재결합 할때마다 )

 - adb forward --list 로 6000 이 나오는지 확인

 - 6000 안나오면 : adb -s [device_id] forward tcp:6000 tcp:6000

 -  hjlim@KORCO131182:~/android-cts-verifier/CameraITS$ source build/envsetup.sh

CAMERA_ITS_TOP=/home/hjlim/android-cts-verifier/CameraITS

 - 엑세스 허용 

```

# (필수) Android 13 이상 : CTS 인증 도구의 테스트 API 액세스 허용 

adb -s [device_id] shell am compat enable ALLOW_TEST_API_ACCESS com.android.cts.verifier

- Enabled  change 166236554 for com.android.cts.verifier.



# Android 10 이상 : 앱에 보고서를 생성할 권한 허용

adb -s [device_id] shell appops set com.android.cts.verifier android:read_device_identifiers allow



# Android 11 이상 : 보고서 저장용 외부 최상위 디렉터리 액세스 허용

adb -s [device_id] shell appops set com.android.cts.verifier MANAGE_EXTERNAL_STORAGE 0



# Android 14 이상 : 앱에 화면 켜는 권한을허용

adb -s [device_id] shell appops set com.android.cts.verifier TURN_SCREEN_ON 0

```

 - config 수정 ( tools/unit_test_configs 안에 예제 config 확인 가능 )

```

TestBeds:

  - Name: TEST_BED_TABLET_SCENES  # Need 'tablet' in name for tablet scenes

    # Use TEST_BED_MANUAL for manual testing and remove below lines:

    #     - serial <tablet_id>

    #       label: tablet

    # Test configuration for scenes[0:4, 6]

    Controllers:

        AndroidDevice:

          - serial: R3CYA0F4B5T  # quotes needed if serial id entirely numeric

            label: dut

          - serial: 78d130215c357ece  # quotes needed if serial id entirely numeric

            label: tablet

    TestParams:

      brightness: 192

      chart_distance: 22.0

      debug_mode: "True"  # quotes needed

      lighting_cntl: 'relay'  # can be arduino or "None"

      lighting_ch: 1

      camera: 0

      # scene: <scene-name> # if <scene-name> runs all scenes

      scene: scene6

      foldable_device: "False"  # "True" if testing foldable device

```

3. Test 실행 

 run_all_tests.py 실행시, 꼭 tools 폴더 외부에서 실행해야 함.

 - config 대로 실행 : python tools/run_all_tests.py

 - 선택 인자로 실행 : python tools/run_all_tests.py camera=0 scenes=1_1



## WSL Error

<details>

<summary>(📁 접기/펼치기)</summary>



**wsl 에서 ping 12.127.100.100 을 날려도 응답이 없을경우**

```

잘 되되가 갑자기 네트워크 문제로 Timeout 문제가 나거나, socket 에러가 난다면

wsl 네트워크가 꼬였을 가능성이 있음.



cmd(윈도우) 에서

netsh winsock reset

netsh int ip reset

wsl --shutdown

실행후 재부팅 하면 풀릴수 있다.

```



</details>



## ITS Box 설정 Error

<details>

<summary>(📁 접기/펼치기)</summary>





**port 6000 Error**

```

jh8051choi@KORCO203328:/mnt/c/Users/jh8051.choi$ adb -s R3CYA0F4B5T forward tcp:6000 tcp:6000

adb.exe: error: cannot bind listener: cannot bind to 127.0.0.1:6000: 액세스 권한에 의해 숨겨진 소켓에 액세스를 시도했습니다. (10013)



- 윈도우 cmd 에서 진행



PS C:\Users\jh8051.choi> net stop winnat

Windows NAT Driver 서비스를 잘 멈추었습니다.



PS C:\Users\jh8051.choi> net start winnat

Windows NAT Driver 서비스가 잘 시작되었습니다.

```



</details>



## ITS Box Test Skip Check

<details>

<summary>(📁 접기/펼치기)</summary>



```

각 scene 별로 dut 사양 체크후, Test 와 맞지 않으면 skip

대부분 각각의 scene 별로 

props = cam.get_camera_properties()

확인 후, 결정. ( 각각 확인 필요 )

skip 조건에 맞으면, 최종적으로

camera_properties_utils.skip_unless 

호출하여 skip



ex) Miracle M2, scene6, test_in_sensor_zoomm 의 경우 Skip됨

prop 데이터중, android.scaler.availableStreamUseCases 값에 '6' 이 없어서 False 로 skip 결정됨.

>> '6'이 없는 이유 검색 결과

StreamUseCase 의 값 6 은 ANDROID_SCALER_AVAILABLE_STREAM_USE_CASES_CROPPED_RAW 를 의미.

    하드웨어 레벨에서 고화질 인센서 줌 지원을 안하면 '6' 이 없다고 함. 아래와 같은 경우가 있음

 - 센서 자체가 지원하지 않음 : Cropped RAW 지원 하지 않을수 있음.

 - HAL 선언 누락 

 - hardware Level : Full 인지 3 인지 확인이 필요할 수 있음.( 3여야 UseCase 지원할 확률이 높다고 함 )

   level 확인해 보니 Full로 확인됨

  PS C:\Users\jh8051.choi> adb shell "dumpsys media.camera |grep Level"   

  PS C:\Users\jh8051.choi> adb shell "dumpsys media.camera | grep -A 1 android.info.supportedHardwareLevel"

```



</details>





# VTS

## History

- [Github VTS Issues](https://github.samsungds.net/RTASYS/BRCK_CoWork/issues/44)



## Work Summary

- 카메라와 관련된 VTS 항목들에 대한 이슈 발생 시 원인 분석을 진행하는 업무   

- ex) 기존에 Pass 되던 항목이 Fail 되는 경우 : 원인 커밋 분석 및 해결



## Setup

<details>

<summary>(📁 접기/펼치기)</summary>



**1. Download**  

- FTP: /Brycen_Shared/Tools/VTS

- (android-vts.zip // Proxy설정파일.zip ) 2가지 파일 다운로드

- 위 파일은 Sample file로 Android 새로운 버전 및 이슈에 맞는 VTS file이 필요할 수도 있음.



**2. 압축 해제**  

```

WSL 환경에 android-vts.zip 파일 카피 후, 압축 해제.

ex) cp ~/../../mnt/d/VTS/android-vts.zip .

    unzip android-vts.zip

```



**3. proxy 설정**

```

Proxy설정파일.zip 파일의

net.properties는 jdk/conf/ 아래

cacerts는 jdk/lib/security/ 아래 원래 있던 파일을 덮어 쓰면 됨.

```



**4. vts-tradefed 실행**

```

android-vts/tools 폴더로 이동.

./vts-tradefed

```



**5. CMD 입력**

```

run vts -m VtsAidlHalCameraProvider_TargetTest --test PerInstance/CameraAidlTest#processCaptureRequestBurstISO/0_android_hardware_camera_provider_ICameraProvider_internal_0 --skip-preconditions

입력 후 인내의 기다림.

```



**6. 결과 확인**

```

============================================

================= Results ==================

=============== Consumed Time ==============

    arm64-v8a VtsAidlHalCameraProvider_TargetTest: 2s

Total aggregated tests run time: 2s

=============== Summary ===============

Total Run time: 1m 24s

1/1 modules completed

Total Tests       : 1

PASSED            : 1

FAILED            : 0

============== End of Results ==============

============================================

```

</details>





# 참고사항

## WSL2 사용 필요

- ITS 진행시, WSL1에서는 longdouble 데이터 타입 지원 불가

```

/home/dskang/.local/lib/python3.10/site-packages/numpy/_core/getlimits.py:551: UserWarning: Signature b'\x00\xd0\xcc\xcc\xcc\xcc\xcc\xcc\xfb\xbf\x00\x00\x00\x00\x00\x00' for <class 'numpy.longdouble'> does not match any known type: falling back to type probe function.

This warnings indicates broken support for the dtype!

machar = _get_machar(dtype)



wsl1 numpy.longdouble 데이터 타입 지원 불가 문제

```



## Ubuntu 22.04 버전 이상 사용

- perfetto 및 ITS 등 진행시

- https://confluence.samsungds.net/spaces/RTASystem/pages/1087504889/Ubuntu+upgrade