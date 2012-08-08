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
#     ubuntu-openfoam-installer.sh
#
# Description
#     Install OpenFOAM on Ubuntu.
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
    die "INTERNAL ERROR: askyesno requires a prompt message"
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
        die "INTERNAL ERROR: unknown option found"
        ;;
    esac
  done
  if [ $# -ne 1 ]; then
    die "INTERNAL ERROR: backup requires exactly one file to back up"
  fi
  ORIG_FILE=$1
  BACKUP_FILE=$ORIG_FILE.openfoam.$(date +%F).save
  log "Backing up $ORIG_FILE to $BACKUP_FILE"
  $ROOT_CMD cp -a --backup=t $ORIG_FILE $BACKUP_FILE
}

###############################################################################
# Here goes the actual main script
###############################################################################

# Make sure we read from the tty
exec 0</dev/tty

# Check whether lsb_release is available (not all distros have it)
log "Checking for lsb_release."
which lsb_release >/dev/null 2>&1 || \
  die "Required program lsb_release not found."

# Check that the user is running a supported version of Ubuntu
log "Checking operating system requirements."
DIST=$(lsb_release -is)
VERS=$(lsb_release -cs)
case "$DIST" in
  Ubuntu)
    ;;
  *)
    die "The '$DIST' operating system is not supported by this installer."
    ;;
esac
case "$VERS" in
  lucid|natty|oneiric|precise)
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

log "Installation of OpenFOAM is finished."
if askyesno -y "Create /etc/profile.d/openfoam.sh [Y/n]?"; then
  log "Installing /etc/profile.d/openfoam.sh"
  TMPFILE=$(mktemp)
  cat > $TMPFILE << EOF
# OpenFOAM shell initialization file
# Automatically generated on $(date -R)
if [ \$(id -u) -ne 0 ]; then
  source /opt/openfoam211/etc/bashrc
fi
EOF
  sudo cp --backup=t $TMPFILE /etc/profile.d/openfoam.sh
  sudo chmod 0644 /etc/profile.d/openfoam.sh
  rm -f $TMPFILE
  log "************************************************"
  log "*** Close this terminal and open a new one   ***"
  log "*** for the changes to take effect           ***"
  log "************************************************"
else
  log "************************************************"
  log "*** To use OpenFOAM please add               ***"
  log "***                                          ***"
  log "***   source /opt/openfoam211/etc/bashrc     ***"
  log "***                                          ***"
  log "*** to your ~/.bashrc file.                  ***"
  log "************************************************"
fi

# Et voila, c'est tous
log "Done."
exit 0
