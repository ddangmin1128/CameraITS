# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export WSL_HOST_ADB='/mnt/c/platform-tools/adb.exe'
export HOST_IP='172.27.16.1'

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

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

check_result() {
    if [ $? -eq 0 ]; then
        echo "PASS: $1"
    else
        echo -e "${RED}FAIL: $1${NC}"
    fi
}

DEVICE_ID="R3CT80ECKZY"

FORWARD_EXISTS=$(adb forward --list | grep "tcp:6000")

if [ -z "$FORWARD_EXISTS" ]; then
    echo "forward list is empty. Start ADB Forward.."
  
    start_adb_fwd
    adb -s $DEVICE_ID forward tcp:6000 tcp:6000
    adb forward --list
else
    adb forward --list
    echo "Already forwarding tcp:6000"
fi

# (필수) Android 13 이상 : CTS 인증 도구의 테스트 API 액세스 허용 ([device_id] : dut 시료 기준)
adb -s $DEVICE_ID shell am compat enable ALLOW_TEST_API_ACCESS com.android.cts.verifier
check_result "ALLOW_TEST_API_ACCESS"

# Android 10 이상 : 앱에 보고서를 생성할 권한 허용
adb -s $DEVICE_ID shell appops set com.android.cts.verifier android:read_device_identifiers allow
check_result "read_device_identifiers allow"

# Android 11 이상 : 보고서 저장용 외부 최상위 디렉터리 액세스 허용
adb -s $DEVICE_ID shell appops set com.android.cts.verifier MANAGE_EXTERNAL_STORAGE 0
check_result "MANAGE_EXTERNAL_STORAGE 0"

# Android 14 이상 : 앱에 화면 켜는 권한을허용
adb -s $DEVICE_ID shell appops set com.android.cts.verifier TURN_SCREEN_ON 0
check_result "TURN_SCREEN_ON 0"

#source build/envsetup.sh
#bash -c "source build/envsetup.sh; bash"

echo "------------------------------"
echo "Done"
echo "------------------------------"
echo -e "use ${GREEN}source build/envsetup.sh${NC} and,"
echo -e "Run config : ${GREEN}python tools/run_all_tests.py${NC}"
echo -e "Run param e.g. : ${GREEN}python tools/run_all_tests.py${NC} ${YELLOW}camera=0 scenes=1_1${NC}"
echo "------------------------------"