'''
self.IPADDR Auto Change
Get Ipconfig
'''

import subprocess
import re


def get_tailscale_ip():
    result = subprocess.run(
        ["cmd.exe", "/c", "ipconfig"],
        capture_output=True,
        text=True,
        encoding="cp949",
        errors="ignore"
    )

    text = result.stdout

    # Tailscale 어댑터 블록만 찾기
    match = re.search(
        r"어댑터 Tailscale:([\s\S]*?)(?:\n\S|\Z)",
        text
    )

    if match:
        block = match.group(1)
        ip_match = re.search(
            r"IPv4 주소[ .]*: ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)",
            block
        )
        # 169.254.x.x 는 APIPA(자동구성) 주소 - Tailscale 꺼진 상태에서 할당되므로 제외
        if ip_match and not ip_match.group(1).startswith('169.254.'):
            return ip_match.group(1)

    # Tailscale 없으면 WSL 기본 게이트웨이(= Windows vEthernet IP)로 fallback
    # ip route show default → "default via 172.27.16.1 dev eth0 ..."
    route = subprocess.run(
        ['ip', 'route', 'show', 'default'],
        capture_output=True, text=True
    )
    gw_match = re.search(r'default via ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)', route.stdout)
    if gw_match:
        return gw_match.group(1)

    raise RuntimeError("연결 가능한 Windows IP를 찾을 수 없습니다.")


if __name__ == "__main__":
    test_ip = get_tailscale_ip()
    print(f'Current Ip = {test_ip}')