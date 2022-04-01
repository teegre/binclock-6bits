#! /usr/bin/env bash

#  ____  _        _____ _            _      __
# |  _ \(_)      / ____| |          | |    / /
# | |_) |_ _ __ | |    | | ___   ___| | __/ /_
# |  _ <| | '_ \| |    | |/ _ \ / __| |/ / '_ \
# | |_) | | | | | |____| | (_) | (__|   <| (_) |
# |____/|_|_| |_|\_____|_|\___/ \___|_|\_\\___/
# 6 Bits Edition
#
# Copyright (C) 2022, Stéphane MEYER.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>
#
# BinClock
# C : 2022/04/01
# M : 2022/04/01
# D : A binary clock.

bold="\e[1m"
dim="\e[2m"
color1="\e[38;5;9m"
color2="\e[38;5;1m"
rst="\e[m"

hidecursor()    { echo -ne "\e[?25l"; }
showcursor()    { echo -ne "\e[?25h"; }
locate()        { local y x; y=$1; x=$2; printf '\e[%d;%dH' $((y)) $((x)); }
get_scr_size()  { shopt -s checkwinsize; (:;:); }
random_colors() { local C; ((C=(RANDOM%254)+1)); color1="\e[38;5;${C}m"; color2="\e[38;5;$((C+1))m" ;}

exec {pause_fd}<> <(:)
pause() ( read -rt "$1" -u $pause_fd )

_sync() {
  local n=1
  local N
  while (( n !=0 )); do
    N="${EPOCHREALTIME#*,}"
    n=${N:0:1}
    pause 0.0625
  done
}

init_screen() {
  clear;
  get_scr_size
  ((OY=(LINES/2)-2))
  ((OX=(COLUMNS/2)-8))
  frame
}

reset_var() { unset hy mm sd; }

tobin() {
  # convert an integer from decimal to binary.
  # usage: tobin <number> [bits]
  
  local n b d
  n=$1
  b=$2

  while ((n > 0)); do
    d="$((n%2))$d"
    ((n/=2))
    ((b--))
  done
  
  while ((b > 0)); do
    d="0${d}"
    ((b--))
  done
  
  echo "$d"
}

digit() {
  # print a 6 bits binary number and display
  # a guide that helps to read its value.

  # i.e.: 59
  # 32 16  8  .  2  1
  #  1  1  1  0  1  1


  local y x n i g
  y=$1
  x=$2
  n=$3
  ((g=32))

  for ((i=0;i<${#n};i++)); do
    locate $((y)) $((x))
    (( ${n:i:1} == 1 )) && {
      printf "%b%3s%b" "${color1}${bold}" "$g" "${rst}"
      locate $((y+1)) $((x))
      printf "%b%3s%b" "${color2}${bold}" "1" "${rst}"
    }
    (( ${n:i:1} == 0 )) && {
      printf "%b%3s%b" "${color1}${dim}"  "." "${rst}"
      locate $((y+1)) $((x))
      printf "%b%3s%b" "${color2}${dim}"  "0" "${rst}"
    }
    ((x+=3))
    ((g=g == 1 ? 32 : g/2))
  done
}

frame() {
  local y x color
  color=$color1

  for ((y=OY-1;y<=OY-1+7;y++)); do
    printf "%b" "$color"
    for ((x=OX-3; x<=OX-3+21; x+=3)); do
      ((y>OY-1 && y<OY-1+7 && x>OX-3 && x<OX-3+21)) && continue
      locate $((y)) $((x))
      printf "%3s" "."
    done
    [[ $color == "$color1" ]] && color=$color2 || color=$color1
  done
}

clock() {
  local TD HY MM SD
  [[ $SHOWDATE ]] || TD="$(date "+%_H %_M %_S")"
  [[ $SHOWDATE ]] && TD="$(date "+%_y %_m %_d")"
  # shellcheck disable=SC2162
  IFS=' ' read HY MM SD <<< "$TD"
  ((y=OY))
  ((x=OX))
  [[ $hy != "$HY" ]] && { hy=$HY; digit $((y)) $((x)) "$(tobin "$HY" 6)"; }
  ((y+=2))
  [[ $mm != "$MM" ]] && { mm=$MM; digit $((y)) $((x)) "$(tobin "$MM" 6)"; }
  ((y+=2))
  [[ $sd != "$SD" ]] && { sd=$SD; digit $((y)) $((x)) "$(tobin "$SD" 6)"; }
}

declare hy mm sd

trap 'echo -en "\e[m"; showcursor; stty sane; echo; exit' INT QUIT
trap 'init_screen; reset_var' WINCH

hidecursor; stty -echo -icanon time 0 min 0

init_screen

while :; do
  
  # shellcheck disable=SC2162
  IFS= read key
  case $key in
    c | C) random_colors; frame; reset_var ;;
    d | D) [[ $SHOWDATE ]] || { SHOWDATE=1; ((TIMER=EPOCHSECONDS)); reset_var; } ;;
    q | Q) break ;;
    r | R) clear; frame; reset_var ;;
  esac

  _sync
  clock
  
  pause 0.5

  [[ $TIMER ]] && ((EPOCHSECONDS-TIMER == 5 )) && {
    unset TIMER SHOWDATE
    reset_var
  }

done

echo
stty sane; showcursor
