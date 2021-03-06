#!/bin/bash

# Main function
main()
{
  readopts $@

  # check wether script is a symlink and get path
  [ -h $0 ] && eprintf "This script MUST NOT be a symlink\n" && exit 1
  path=$( cd $(dirname $0) && pwd)

  # Update dotfiles in home
  vprintf ${GREEN} "\ndotfiles in ${path}"
  for file in `ls ${path} | grep -vE "PACKAGES\.lst|README\.md|deploy\.sh|config"`; do
    link ${path}/${file} ${HOME}/.${file} ${VERBOSE}
  done

  vprintf ${GREEN} "\ndotfiles ${path}/config"
  dryrun "mkdir -p ${HOME}/.config"
  for file in `ls ${path}/config`; do
    link ${path}/config/${file} ${HOME}/.config/${file} ${VERBOSE}
  done

  vprintf ${GREEN} "\n== Files deployed =="
}

# Usage: link target name
# creates Symlink 'name -> target' or copies file if COPY is not empty
link()
{
  target=$1
  name=$2

  vprintf ${GREEN} "> ${name}"

  # SYMLINK mode
  if [ "x${COPY}" == 'x' ]; then
    # remove symlink if exists
    if [ "x${FORCE}" != 'x' ] || [ -h ${name} ]; then 
      vprintf ${NC} "  removing ${name}"
      dryrun "rm ${name}"
    else
      if [ -e ${name} ]; then
        eprintf "  ${name} exists and is not an symlink!"
        return
      fi
    fi

    vprintf ${NC} "  creating new symlink: ${name} -> ${target}"
    dryrun "ln -s ${target} ${name}"
  else

    if [ -e ${name} ]; then
      vprintf ${NC} "  removing ${name}"
      if [ -d ${name} ]; then
        dryrun "rm -r ${name}"
      else
        dryrun "rm ${name}"
      fi
    fi

    vprintf ${NC} "  copying ${name} recursive to ${target}"
    if [ -d ${target} ]; then
      dryrun "cp -r ${target} ${name}"
    else
      dryrun "cp ${target} ${name}"
    fi
  fi
}

readopts()
{
  # initialize variables (again)
  COLOR='true'
  COPY=''
  FORCE=''
  PRETEND=''
  VERBOSE=''

  while [ $# -gt 0 ]; do
    case $1 in
      -c|--copy)
        COPY='true'
        ;;
      -f|--force)
        FORCE='true'
        ;;
      -h|--help)
        printf "${HELP}\n"
        exit 0
        ;;
      -p|--pretend)
        PRETEND='true'
        VERBOSE='true'
        ;;
      -v|--verbose)
        VERBOSE='true'
        ;;
      -x|--no-color)
        COLOR=''
        ;;
      *)
        eprintf "Unknown option: \'$1\'!"
        printf "${HELP}\n"
        exit 1
        ;;
    esac
    shift
  done
}

# prints $2 and newline in color $1 if VERBOSE is other than empty
vprintf()
{
  if [ "x${VERBOSE}" != 'x' ]; then
    if [ "x${COLOR}" == 'x' ]; then
      printf "$2\n"
    else
      printf "${1}$2${NC}\n"
    fi
  fi
}

# prints $1 as error message
eprintf()
{
 if [ "x${COLOR}" == 'x' ]; then
   printf "EE: $1\n"
 else
   printf "${RED}$1${NC}\n"
 fi
}

# run $1 if PRETEND is empty
dryrun()
{
  if [ "x${PRETEND}" == 'x' ]; then
    $1
  else
    vprintf ${YELLOW} "  would run \'$1\'"
  fi
}

# global vars
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# may be redefined by readopts
COLOR=''
COPY=''
FORCE=''
PRETEND=''
VERBOSE=''

HELP=$( cat <<EOF
Usage: $0 [OPTIONS]

OPTIONS
  -h | --help
    prints this helptext.

  -c | --copy
    instead of symlinking, copy files.

  -f | --force
    In symlink mode: remove existing files.

  -p | --pretend
    do not actually do something, just print actions (enables verbose mode).

  -v | --verbose
    give more output.

  -x | --no-color
    disable colorazation of the text.
EOF
)

# run the programm
main $@

# vim:set et ts=2 sw=2 sts=2:
