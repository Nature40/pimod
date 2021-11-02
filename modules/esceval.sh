# SPDX-License-Identifier: 0BSD
# Copyright 2014 Alexander Kozhevnikov <mentalisttraceur@gmail.com>

# On 2019-04-25, this script was compatible with Bourne and POSIX shells.
# EXCEPT for the following exceptions:
# Function declarations (First appeared in SVR2 Bourne shells in 1984).
# command built-in (not supported in really old Bourne shells)

if command -v esceval 1>/dev/null 2>&1
then
 :
else
 if (eval 'echo ${A%%a} ${A#a}' 1>/dev/null 2>&1)
 then
  eval 'esceval()
  {
   case $# in 0) return 0; esac
   (
    while :
    do
     escaped=\'\''
     unescaped=$1
     while :
     do
      case $unescaped in
      *\'\''*)
       escaped=$escaped${unescaped%%\'\''*}"'"'\''"'"
       unescaped=${unescaped#*\'\''}
       ;;
      *)
       break
      esac
     done
     escaped=$escaped$unescaped\'\''
     shift
     case $# in 0) break; esac
     printf "%s " "$escaped" || return $?
    done
    printf "%s\n" "$escaped"
   )
  }'
 else
  esceval()
  {
   case $# in 0) return 0; esac
   (
    b='\\'
    while :
    do
     escaped=`
      printf '%s\n' "$1" \
      | sed "
         s/'/'$b''/g
         1 s/^/'/
         $ s/$/'/
        "
     ` || return $?
     shift
     case $# in 0) break; esac
     printf '%s ' "$escaped" || return $?
    done
    printf '%s\n' "$escaped"
   )
  }
 fi
fi