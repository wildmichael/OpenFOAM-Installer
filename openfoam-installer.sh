#!/bin/sh
#------------------------------------------------------------------------------
# =========                 |
# \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
#  \\    /   O peration     |
#   \\  /    A nd           | Copyright (C) 2012 OpenFOAM Foundation
#    \\/     M anipulation  |
#------------------------------------------------------------------------------
# License
#     This file is part of OpenFOAM.
#
#     OpenFOAM is free software: you can redistribute it and/or modify it
#     under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
#     ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#     FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#     for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with OpenFOAM.  If not, see <http://www.gnu.org/licenses/>.
#
# Script
#     openfoam-installer.sh
#
# Description
#     Install OpenFOAM on Ubuntu, Fedora and OpenSUSE.
#------------------------------------------------------------------------------

# Bail out on error
set -e

# Function to report failure and terminate
die ()
{
  echo "*** Error: $@" >&2
  exit 1
}

# Function to report progress
log ()
{
  echo "$@"
}

# Function to ask a yes/no question from the user. -n make "no" the default, -y
# "yes". If not specified, -n is assumed. Exits with 0 if "y" was answered,
# with 1 if "n" was the input.
askyesno ()
{
  DEFAULT=n
  while [ $# -gt 1 ]; do
    case $1 in
      -n)
        shift
        break
        ;;
      -y)
        DEFAULT=y
        shift
        ;;
      *)
        break
        ;;
    esac
  done
  if [ $# -lt 1 ]; then
    die "INTERNAL ERROR: askyesno requires a prompt message."
  fi
  while true; do
    read -p "$@" ans
    case "${ans:-$DEFAULT}" in
      y)
        return 0
        ;;
      n)
        return 1
        ;;
    esac
  done
}

# Function to backup a file. The -s switch uses sudo to create the copy.
backup ()
{
  ROOT_CMD=
  while [ $# -gt 1 ]; do
    case $1 in
      -s)
        ROOT_CMD=sudo
        shift
        ;;
      *)
        die "INTERNAL ERROR: unknown option found."
        ;;
    esac
  done
  if [ $# -ne 1 ]; then
    die "INTERNAL ERROR: backup requires exactly one file to back up."
  fi
  ORIG_FILE=$1
  BACKUP_FILE=$ORIG_FILE.openfoam.$(date +%F).save
  log "Backing up $ORIG_FILE to $BACKUP_FILE"
  $ROOT_CMD cp -a --backup=t $ORIG_FILE $BACKUP_FILE
}

# Installation procedure for Ubuntu
install_ubuntu ()
{
  if [ $# -ne 1 ]; then
    die "INTERNAL ERROR: install_ubuntu requires the code-name as argument."
  fi
  VERS=$1

  case "$VERS" in
    lucid|natty|oneiric|precise)
      ;;
    12.10)
      VERS=precise
      ;;
    *)
      die "Ubuntu '$VERS' is not supported by this installer."
      ;;
  esac

  # See whether we can find an already existing sources.list file
  # Ask user whether he wants to overwrite it or abort.
  SRCS_LIST=/etc/apt/sources.list.d/openfoam.list
  log "Checking for existing $SRCS_LIST."
  if [ -f $SRCS_LIST ]; then
    echo "The file $SRCS_LIST already exists."
    if askyesno -y "Continue and overwrite it [Y/n]?"
    then
      backup -s $SRCS_LIST
    else
      log "Aborted."
      exit 0
    fi
  fi

  # Write the new sources.list file, update the cache and install OpenFOAM.
  # Would like to use add-apt-repository, but that just writes it to
  # /etc/apt/sources.list instead of a /etc/apt/sources.list.d/*.list file
  # as of now.
  log "Writing $SRCS_LIST."
  REPO=http://www.openfoam.org/download/ubuntu
  sudo sh -c "echo deb $REPO $VERS main > $SRCS_LIST"

  log "Updating APT cache."
  sudo apt-get update

  log "Installing OpenFOAM."
  sudo apt-get install openfoam211 paraviewopenfoam3120
}

# Installation procedure for Fedora
install_fedora ()
{
  if [ $# -ne 1 ]; then
    die "INTERNAL ERROR: install_fedora requires the version as argument."
  fi
  VERS=$1

  case "$VERS" in
    1[67])
      ;;
    *)
      die "Fedora release $VERS is not supported by this installer."
      ;;
  esac

  case $(getconf LONG_BIT) in
    32)
      URL=http://www.openfoam.org/download/fedora/$VERS/i386
      ARCH=i686
      ;;
    64)
      URL=http://www.openfoam.org/download/fedora/$VERS/x86_64
      ARCH=x86_64
      ;;
    *)
      die "Failed to determine whether operating system is 32 or 64 bit."
      ;;
  esac

  log "Installing prerequisites."
  sudo yum groupinstall 'Development Tools'
  sudo yum install openmpi openmpi-devel qt-devel qt-webkit-devel tcsh
  log "Installing OpenFOAM."
  sudo rpm -i --replacepkgs -v \
    $URL/OpenFOAM-scotch-5.1.12-1.$ARCH.rpm \
    $URL/OpenFOAM-ParaView-3.12.0-1.$ARCH.rpm \
    $URL/OpenFOAM-2.1.1-1.$ARCH.rpm
}

# Installation procedure for OpenSUSE
install_suse ()
{
  if [ $# -ne 1 ]; then
    die "INTERNAL ERROR: install_suse requires the version as argument."
  fi
  VERS=$1

  case "$VERS" in
    12.1)
      ;;
    *)
      die "OpenSUSE $VERS is not supported by this installer."
      ;;
  esac

  URL=http://www.openfoam.org/download/suse
  case $(getconf LONG_BIT) in
    32)
      ARCH=i586
      ;;
    64)
      ARCH=x86_64
      ;;
    *)
      die "Failed to determine whether operating system is 32 or 64 bit."
      ;;
  esac

  log "Installing prerequisites."
  sudo zypper install pattern:devel_basis libqt4 libQtWebKit4 openmpi
  log "Installing OpenFOAM."
  sudo rpm -i --replacepkgs -v \
    $URL/11.4/$ARCH/OpenFOAM-scotch-5.1.12-1.$ARCH.rpm \
    $URL/12.1/$ARCH/OpenFOAM-ParaView-3.12.0-1.$ARCH.rpm \
    $URL/12.1/$ARCH/OpenFOAM-2.1.1-1.$ARCH.rpm
}

###############################################################################
# Here goes the actual main script
###############################################################################

# Make sure we read from the tty
exec 0</dev/tty

# Detect operating system name and version
log "Checking operating system requirements."
DIST=
VERS=
if [ -r /etc/os-release ]; then
  DIST=$(awk -F= '/^NAME/{print gensub(/[^a-zA-Z0-9._-]/, "", "g", $2)}' \
    /etc/os-release)
  VERS=$(awk -F= '/^VERSION_ID/{print gensub(/[^a-zA-Z0-9._-]/, "", "g", $2)}' \
    /etc/os-release)
elif which lsb_release >/dev/null 2>&1; then
  DIST=$(lsb_release -is)
  VERS=$(lsb_release -cs)
fi

if [ -z "$DIST" -o -z "$VERS" ]; then
  die "Failed to determine operating system information."
fi

SPECIALS=
case "$DIST" in
  Ubuntu)
    install_ubuntu $VERS
    INSTALL_DIR=/opt/openfoam211
    SPACE="     "
    ;;
  Fedora)
    install_fedora $VERS
    INSTALL_DIR=/opt/OpenFOAM-2.1.1
    SPACE="  "
    SPECIALS="$(printf '\n  module add mpi\n')"
    ;;
  openSUSE)
    install_suse $VERS
    INSTALL_DIR=/opt/OpenFOAM-2.1.1
    SPACE="  "
    ;;
  *)
    die "The '$DIST' operating system is not supported by this installer."
    ;;
esac

log "Installation of OpenFOAM is finished."
if askyesno -y "Create /etc/profile.d/openfoam.sh [Y/n]?"; then
  log "Installing /etc/profile.d/openfoam.sh."
  TMPFILE=$(mktemp)
  cat > $TMPFILE << EOF
# OpenFOAM shell initialization file
# Automatically generated on $(date -R)
if [ \$(id -u) -ne 0 ]; then$SPECIALS
  source $INSTALL_DIR/etc/bashrc
fi
EOF
  sudo cp --backup=t $TMPFILE /etc/profile.d/openfoam.sh
  sudo chmod 0644 /etc/profile.d/openfoam.sh
  rm -f $TMPFILE
  log "************************************************"
  log "*** Log out and back in for the changes to   ***"
  log "*** take effect.                             ***"
  log "************************************************"
else
  log "************************************************"
  log "*** To use OpenFOAM please add               ***"
  log "***                                          ***"
  log "***   source $INSTALL_DIR/etc/bashrc${SPACE}***"
  log "***                                          ***"
  log "*** to your ~/.bashrc file. Log out and back ***"
  log "*** in for the changes to take effect.       ***"
  log "************************************************"
fi

# Et voila, c'est tous
log "Done."
exit 0
