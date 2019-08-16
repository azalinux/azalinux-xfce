#!/bin/sh
#
# install-vivaldi.sh Version 1.8.666.4
#
## Basic Usage ##
#
# Issue the following in a terminal to install/update the latest snapshot:
#
#    chmod +x install-vivaldi.sh    # Only needed the first time
#    ./install-vivaldi.sh
#
## Auto-update ##
#
# If you would like to ensure that Vivaldi is automatically kept up to date,
# add the following crontab entry:
#
#     00 20 * * mon $PATH_TO_SCRIPT/install-vivaldi.sh >/dev/null 2>&1
#
# This would execute the script at 20:00 (8pm) every Monday, ensuring you are
# always running the latest Vivaldi snapshot.
#
# For more options, read one of the many crontab guides found on the internet.

# Stop people from running this on macOS or another non-linux system
if [ "$(uname -s )" != "Linux" ]; then
  cat << END >&2

This script is for Linux only. If you want the latest snapshot for another OS,
go the the Vivaldi Team Snapshot blog.

    https://vivaldi.com/blog/snapshots/

END
  exit 1
fi

# Correct the name of the script when piped to a shell
SCRIPT_NAME="$0"
if [ "$0" = "sh" -o "$0" = "ash" -o "$0" = "bash" -o "$0" = "dash" -o "$0" = "ksh" -o "$0" = "zsh" ]; then
  SCRIPT_NAME="./install-vivaldi.sh"
fi

# Provide some help on the available options
VIVALDI_ARCH="$(uname -m)"
helptext() {
  cat << HELP

Usage:

    $SCRIPT_NAME [OPTIONS(S)]

If no options are provided, then the script will install the most recent
Vivaldi snapshot for the detected system architecture ($VIVALDI_ARCH). It will
install, system-wide into "/usr/local/share" if possible, otherwise it will
default to "${XDG_DATA_HOME:-$HOME/.local/share}".

This script handles the fetching of a Vivaldi install file for repackaging but
will use a local copy, if it is already present in the working directory.


Options:

  -h, --help                          (Show this help text and exit)

  -t, --test                          (Test run Vivaldi with a clean profile
                                      before install. You will be asked if you
                                      want to proceed with the install
                                      NOTE: Does not work when run as root)

  -u, --uninstall                     (Uninstall the previous version)


Advanced Options:

  -a, --architecture [ARCHITECTURE]   (Use the supplied architecture instead
                                      of the one detected)

  -d, --directory [DIRECTORY]         (Install to the supplied directory. An
                                      "absolute" path must be given)

  -f, --final                         (Install the latest final instead)

  --insecure                          (Do not check package signature)

  -nl, --no-launch                    (Do not attempt to automatically Launch
                                      Vivaldi after first install)

  -r, --retrieve                      (Fetch package but do not install it)

  -v, --version [VERSION]             (Install the user supplied version
                                      number, rather than the latest detected
                                      in the APT repository)

HELP
}

# An easy way to check if an executable is present
available () {
  command -v "$1" >/dev/null 2>&1
}

# Don't leave stuff lying around
cleanup_before_exit () {
  cd /tmp
  if [ -d "$VIVALDI_FILES" ]; then
    rm -r "$VIVALDI_FILES"
  fi
  if [ -e "$VIVALDI_PKG" -a "$REMOVE_VIVALDI_PKG" = "Y" ]; then
    rm "$VIVALDI_PKG"
  fi
}

# Decide install directory based on write permissions to /usr/local
if [ -w "/usr/local/share" ]; then
  VIVALDI_INSTALL_DIR="/usr/local/share"
else
  VIVALDI_INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
fi

# Handle user options
REGISTER_DESKTOP_AND_ICONS=Y
VIVALDI_LAUNCH=Y
VIVALDI_RETRIEVE_ONLY=N
VIVALDI_STREAM=vivaldi-snapshot
VIVALDI_STREAM_SHORT=vivaldi-snapshot
VIVALDI_STREAM_SHORT_ALT=snapshot
VIVALDI_SIG_CHECK=Y
VIVALDI_TEST=N
VIVALDI_UNINSTALL=N
while [ 0 ]; do
  if [ "$1" = "-h" -o "$1" = "--help" -o "$1" = "help" ]; then
    helptext
    exit 0
  elif [ "$1" = "-f" -o "$1" = "--final" -o "$1" = "final" ]; then
    VIVALDI_STREAM=vivaldi-stable
    VIVALDI_STREAM_SHORT=vivaldi
    VIVALDI_STREAM_SHORT_ALT=stable
    shift 1
  elif [ "$1" = "--insecure" -o "$1" = "insecure" ]; then
    VIVALDI_SIG_CHECK=N
    shift 1
  elif [ "$1" = "-nl" -o "$1" = "--no-launch" -o "$1" = "no-launch" ]; then
    VIVALDI_LAUNCH=N
    shift 1
  elif [ "$1" = "-r" -o "$1" = "--retrieve" -o "$1" = "retrieve" ]; then
    VIVALDI_RETRIEVE_ONLY=Y
    shift 1
  elif [ "$1" = "-t" -o "$1" = "--test" -o "$1" = "test" ]; then
    if [ "$USER" = "root" ]; then
      echo 'The option "--test" cannot be used when running this script is run as the root user' >&2
      exit 1
    fi
    VIVALDI_TEST=Y
    shift 1
  elif [ "$1" = "-u" -o "$1" = "--uninstall" -o "$1" = "uninstall" -o "$1" = "exorcise" ]; then
    VIVALDI_UNINSTALL=Y
    shift 1
  elif [ "$1" = "-v" -o "$1" = "--version" -o "$1" = "version" -o "$1" = "ver" ]; then
    if echo "$2" | grep -xq '\([0-9]\+\.\)\{3\}[0-9]\+-[0-9]\+'; then
      VIVALDI_VERSION="$2"
    # 9 times of of 10 the packaging number is -1
    elif echo "$2" | grep -xq '\([0-9]\+\.\)\{3\}[0-9]\+'; then
      VIVALDI_VERSION="${2}-1"
    else
      echo 'You must specify a valid version number if you use the "-v" switch' >&2
      exit 1
    fi
    shift 2
  elif [ "$1" = "-a" -o "$1" = "--architecture" -o "$1" = "architecture" -o "$1" = "arch"  ]; then
    if [ -z "$2" ]; then
      echo 'You must specify the architecture if you use the "-a" switch' >&2
      exit 1
    fi
    VIVALDI_ARCH="$2"
    shift 2
  elif [ "$1" = "-d" -o "$1" = "--directory" -o "$1" = "directory" -o "$1" = "dir" ]; then
    if [ -z "$2" ] || ! echo "$2" | grep -q '^/'; then
      echo 'You must specify an absolute path if you use the "-d" switch' >&2
      exit 1
    fi
    VIVALDI_INSTALL_DIR="$(echo $2 | sed 's,/$,,')"
    if ! [ "$VIVALDI_INSTALL_DIR" = "${XDG_DATA_HOME:-$HOME/.local/share}" -o "$VIVALDI_INSTALL_DIR" = "/usr/local/share" -o "$VIVALDI_INSTALL_DIR" = "/usr/share" ]; then
      REGISTER_DESKTOP_AND_ICONS=N
    fi
    shift 2
  else
    break
  fi
done

# Just uninstall and then exit, if the user requested this (-u, --uninstall)
UNINSTALL_VIVALDI_SCRIPT="$VIVALDI_INSTALL_DIR/remove-$VIVALDI_STREAM_SHORT.sh"
UNINSTALL_VIVALDI_SCRIPT_OLD="$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/remove-vivaldi.sh"
UNINSTALL_VIVALDI_SCRIPT_ANCIENT="/usr/local/bin/remove-$VIVALDI_STREAM.sh"
remove_previous () {
  echo "Removing previously installed $VIVALDI_STREAM"
  "$1"
  exit "$?"
}
if [ "$VIVALDI_UNINSTALL" = "Y" ]; then
  if [ -x "$UNINSTALL_VIVALDI_SCRIPT" ]; then
    remove_previous "$UNINSTALL_VIVALDI_SCRIPT"
  # Handle the old uninstall locations, used by previous versions of this script
  elif [ -x "$UNINSTALL_VIVALDI_SCRIPT_OLD" ]; then
    remove_previous "$UNINSTALL_VIVALDI_SCRIPT_OLD"
  elif [ "$USER" = "root" -a -x "$UNINSTALL_VIVALDI_SCRIPT_ANCIENT" ]; then
    remove_previous "$UNINSTALL_VIVALDI_SCRIPT_ANCIENT"
  else
    echo "$UNINSTALL_VIVALDI_SCRIPT is not present" >&2
    exit 1
  fi
fi

# Set architecture information
case "$VIVALDI_ARCH" in
   x86_64) DEBARCH=amd64 ;;
     i?86) DEBARCH=i386 ;;
     arm*) DEBARCH=armhf ;;
  aarch64) DEBARCH=arm64 ;;
        *) echo "The architecture $VIVALDI_ARCH is not supported." >&2 ; exit 1 ;;
esac

# Make sure we have Wget or cURL
if available wget; then
  SILENT_DL="wget -qO-"
  LOUD_DL="wget"
  DL_OUTPUT="-O"
elif available curl; then
  SILENT_DL="curl -fs"
  LOUD_DL="curl -f"
  DL_OUTPUT="-o"
else
  if [ -z "$VIVALDI_VERSION" ]; then
    # If there is a suitable vivaldi package in the working directory, we could use this instead of fetching
    VIVALDI_VERSION=$(ls | sed -n "s/^${VIVALDI_STREAM}_\(\([0-9]\+\.\)\{3\}[0-9]\+-[0-9]\+\)_$DEBARCH.deb$/\1/p" | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n 1)
    if [ -z "$VIVALDI_VERSION" ]; then
      echo "You need to install Wget or cURL to retrieve the latest version of $VIVALDI_STREAM for $VIVALDI_ARCH; exiting" >&2
      exit 1
    fi
    printf 'Since neither Wget nor cURL is available, only locally saved packages can be installed\n\n' >&2
    printf '                                    * * *\n\n'
  fi
fi

# Check if the local script is different from server version (if Wget or cURL is present)
if [ -n "$SILENT_DL" ]; then
  script_update_msg () {
    # Throw away a redundant copy
    if [ -n "$FIRST_LATEST_SCRIPT" ]; then
      if [ "$(md5sum "$LATEST_SCRIPT" | cut -d' ' -f1)" = "$(md5sum "$FIRST_LATEST_SCRIPT" | cut -d' ' -f1)" ]; then
        rm "$LATEST_SCRIPT" >/dev/null 2>&1
        LATEST_SCRIPT="$FIRST_LATEST_SCRIPT"
      fi
    fi
    cat << END >&2

An updated/different version of this script was found on vivaldi.com. It has
been downloaded and saved for your current user ($USER) here:

    $LATEST_SCRIPT

                                    * * *

END
  }
  # We can not diff the current version to the server version if we have no copy
  if ! [ "$0" = "sh" -o "$0" = "ash" -o "$0" = "bash" -o "$0" = "dash" -o "$0" = "ksh" -o "$0" = "zsh" ]; then
    if [ -d "${XDG_DOWNLOAD_DIR:-$HOME/Downloads}" -a -w "${XDG_DOWNLOAD_DIR:-$HOME/Downloads}" ]; then
      LATEST_SCRIPT="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}/install-vivaldi-snapshot_new.sh"
    else
      # I am less keen on this destination as it is a shared directory and
      # predictable name. A nefarious second user could exploit that fact
      LATEST_SCRIPT="${TMP:-/tmp}/install-vivaldi-snapshot_$USER.sh"
    fi
    # Avoid updating a script the user might be using
    if [ -e "$LATEST_SCRIPT" ];then
      FIRST_LATEST_SCRIPT="$LATEST_SCRIPT"
      LATEST_SCRIPT="${LATEST_SCRIPT%???}-$(date '+%Y%V%u%H').sh"
    fi
    $SILENT_DL https://downloads.vivaldi.com/snapshot/install-vivaldi.sh > "$LATEST_SCRIPT"
    # Kill the downloaded copy if it is the same as the one they are using
    if [ "$(md5sum "$0" | cut -d' ' -f1)" = "$(md5sum "$LATEST_SCRIPT" | cut -d' ' -f1)" ]; then
      rm "$LATEST_SCRIPT" >/dev/null 2>&1
    else
      # Check the script's signature when possible
      if available gpg; then
        if gpg --list-keys 2>/dev/null | grep -Fq 'packager@vivaldi.com'; then
          LATEST_SCRIPT_SIG="$LATEST_SCRIPT.asc"
          $SILENT_DL https://downloads.vivaldi.com/snapshot/install-vivaldi.sh.asc > "$LATEST_SCRIPT_SIG"
          if gpg -q --verify "$LATEST_SCRIPT_SIG" >/dev/null 2>&1; then
            script_update_msg
          fi
          rm "$LATEST_SCRIPT_SIG" >/dev/null 2>&1
        else
          script_update_msg
        fi
      else
        script_update_msg
      fi
    fi
  fi
fi

# Find the latest Vivaldi version from the APT repository if --version is not used
if [ -z "$VIVALDI_VERSION" ]; then
  VIVALDI_VERSION=$($SILENT_DL "https://repo.vivaldi.com/archive/deb/dists/stable/main/binary-$DEBARCH/Packages.gz" | gzip -d | grep -A6 -x "Package: $VIVALDI_STREAM" | sed -n 's/^Version: \(\([0-9]\+\.\)\{3\}[0-9]\+-[0-9]\+\)/\1/p' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n 1)
fi

# Error out if $VIVALDI_VERISON is not set because the previous command failed
if [ -z "$VIVALDI_VERSION" ]; then
  echo "Could not work out the latest version of $VIVALDI_STREAM for $VIVALDI_ARCH; exiting" >&2
  exit 1
fi

# Just fetch and then exit, if the user requested this, via "-r" or "--retrieve"
if [ -n "$SILENT_DL" ] && [ "$VIVALDI_RETRIEVE_ONLY" = "Y" ]; then
  printf "Fetching ${VIVALDI_STREAM} (${VIVALDI_VERSION}) for ${VIVALDI_ARCH} ...\n\n"
  $LOUD_DL "https://downloads.vivaldi.com/$VIVALDI_STREAM_SHORT_ALT/${VIVALDI_STREAM}_${VIVALDI_VERSION}_${DEBARCH}.deb" "$DL_OUTPUT" "${VIVALDI_STREAM}_${VIVALDI_VERSION}_${DEBARCH}.deb"
  exit "$?"
elif [ -z "$SILENT_DL" ] && [ "$VIVALDI_RETRIEVE_ONLY" = "Y" ]; then
  echo "You need to install Wget or cURL to retrieve $VIVALDI_STREAM ($VIVALDI_VERSION) for $VIVALDI_ARCH; exiting" >&2
  exit
fi

# Checks if the same Vivaldi version is already installed
if [ -e "$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/VERSION_$VIVALDI_VERSION" ]; then
  echo "$VIVALDI_STREAM ($VIVALDI_VERSION) is already installed; exiting"
  exit 0
fi

# Get the appropriate package or use a local copy if it is already present
if [ -e "${VIVALDI_STREAM}_${VIVALDI_VERSION}_${DEBARCH}.deb" ]; then
  printf "Using files from local package \"./${VIVALDI_STREAM}_${VIVALDI_VERSION}_${DEBARCH}.deb\"\n\n" >&2
  VIVALDI_PKG="$PWD/${VIVALDI_STREAM}_${VIVALDI_VERSION}_${DEBARCH}.deb"
  REMOVE_VIVALDI_PKG=N
else
  VIVALDI_PKG="$(mktemp -t vivaldi-pkg.XXXXXX)"
  REMOVE_VIVALDI_PKG=Y
  printf "Fetching ${VIVALDI_STREAM} (${VIVALDI_VERSION}) for ${VIVALDI_ARCH} ...\n\n"
  $LOUD_DL "https://downloads.vivaldi.com/$VIVALDI_STREAM_SHORT_ALT/${VIVALDI_STREAM}_${VIVALDI_VERSION}_${DEBARCH}.deb" "$DL_OUTPUT" "$VIVALDI_PKG"
  if ! [ "$?" = 0 ]; then
    echo "Download failed!" >&2
    cleanup_before_exit
    exit 1
  fi
fi

# Extract data.tar.xz one way or another!
data_extract () {
  if available ar; then
    ar p "$VIVALDI_PKG" data.tar.xz > "$VIVALDI_FILES/data.tar.xz"
  else
    DATA_ARCHIVE_LENGTH="$(grep -aom1 'data\.tar.*[0-9]\+' "$VIVALDI_PKG" | sed 's/.* //')"
    # Use part of the XZ magic bytes to locate the start of data.tar.xz
    if available strings; then
      # The problem with strings -o is that sometimes you get a result in
      # octal and other times decimal and -t is not always present
      DATA_ARCHIVE_POSITION="$(strings -o "$VIVALDI_PKG" | grep -m1 '7zXZ$' | sed 's/ *0*\([0-9]\+\) .*/\1/')"
      # See if offset above is in Octal because we'll need to convert if so
      if [ "$(expr "$DATA_ARCHIVE_LENGTH" + "$DATA_ARCHIVE_POSITION")" -gt "$(stat -c '%s' "$VIVALDI_PKG")" ]; then
        DATA_ARCHIVE_POSITION="$(printf '%d' "0$DATA_ARCHIVE_POSITION")"
      fi
    else
      # This is cleaner but you cannot use -b this way on non GNU grep
      DATA_ARCHIVE_POSITION="$(grep -Fabom1 7zXZ "$VIVALDI_PKG" | cut -d: -f1)"
    fi
    tail -c+"$DATA_ARCHIVE_POSITION" "$VIVALDI_PKG" | head -c"$DATA_ARCHIVE_LENGTH" > "$VIVALDI_FILES/data.tar.xz"
  fi
}

# Check the package signatures (if possible) and extract contents
VIVALDI_FILES="$(mktemp -d -t vivaldi-files.XXXXXX)"
if [ "$VIVALDI_SIG_CHECK" = "Y" ];then
  if available gpg; then
    if gpg --list-keys 2>/dev/null | grep -Fq 'packager@vivaldi.com'; then
      if ! grep -q '^-----BEGIN PGP SIGNED MESSAGE-----' "$VIVALDI_PKG"; then
        echo "$VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH} is unsigned; exiting!" >&2
        cleanup_before_exit
        exit 1
      fi
      sed -n '/^-----BEGIN/,/^-----END/p' "$VIVALDI_PKG" > "$VIVALDI_FILES/_gpgbuilder"
      data_extract
      cd "$VIVALDI_FILES"
      if sed -n '/data\.tar\.xz$/s/.* \([a-z0-9]\{40\}\) .*/\1  data.tar.xz/p' _gpgbuilder | sha1sum -c >/dev/null 2>&1; then
        if ! gpg -q --verify _gpgbuilder >/dev/null 2>&1; then
          echo "Failed verifying signature for $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH}; exiting!" >&2
          cleanup_before_exit
          exit 1
        fi
      else
        echo "Failed verifying checksum for $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH}; exiting!" >&2
        cleanup_before_exit
        exit 1
      fi
      rm _gpgbuilder
      cd - >/dev/null
    fi
  else
    printf '                                    * * *\n\n'
    printf "gpg is not installed, so signature checking cannot be performed for upgrades\n\n" >&2
    printf '                                    * * *\n\n'
  fi
fi
if ! [ -e "$VIVALDI_FILES/data.tar.xz" ]; then
  data_extract
fi

# Now things are getting serious, so stop the script for errors or undefined variables
set -eu

# Make sure non-root installs will be able to proceed
if [ "$USER" != "root" ]; then
  if mkdir -p "$VIVALDI_INSTALL_DIR" 2>/dev/null && [ -w "$VIVALDI_INSTALL_DIR" ]; then
    # Without user namespace support a single user install will not work
    if available unshare; then
      if ! unshare -U true >/dev/null 2>&1; then
        echo "User namespace support not enabled." >&2
        echo "Re-run this script as root (or prefaced with sudo)" >&2
        cleanup_before_exit
        exit 1
      fi
    fi
  else
    echo "You do not have write permission to \"$VIVALDI_INSTALL_DIR\"" >&2
    echo "Try re-running this script as root (or prefaced with sudo)" >&2
    cleanup_before_exit
    exit 1
  fi
fi

# Extract files from the /usr/share and /opt directories and rearrange
cd "$VIVALDI_FILES"
printf "Uncompressing $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH} ...\n\n"
export EXTRACT_UNSAFE_SYMLINKS=1 # This keeps busybox happy ;)
tar xJf data.tar.xz "./opt/$VIVALDI_STREAM_SHORT" ./usr/share
mv usr temp
mkdir -p ".$VIVALDI_INSTALL_DIR"
mv temp/share/* ".$VIVALDI_INSTALL_DIR"
rmdir temp/share temp
mv "opt/$VIVALDI_STREAM_SHORT" ".$VIVALDI_INSTALL_DIR"
rmdir opt
rm data.tar.xz

# Test run the package if the user selected this with -t or --test
if [ "$VIVALDI_TEST" = "Y" ]; then
  printf "Test launching $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH} ...\n\n"
  ".$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/$VIVALDI_STREAM_SHORT" --user-data-dir=tmp-user-data >/dev/null 2>&1 ||:
  if [ -d "tmp-user-data" ]; then
    rm -r "tmp-user-data"
  fi
  while [ 0 ]; do
    read -p "Do you want to install $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH}? [y/N]: " VIVALDI_PROCEED_AFTER_TEST </dev/tty
    case "${VIVALDI_PROCEED_AFTER_TEST:-N}" in
      [Yy]*) break ;;
      [Nn]*) cleanup_before_exit; exit ;;
          *) echo 'Please answer yes or no.' >&2 ;;
    esac
  done
  printf '\n'
fi

# Create the first part of the uninstall script
cat << END > ".$UNINSTALL_VIVALDI_SCRIPT"
#!/bin/sh

# Check if an executable is present
available () {
  command -v "\$1" >/dev/null 2>&1
}

# Update the icon and desktop databases
updatedbs () {
  # These commands are non-essential but helpful. The '||:' causes them to
  # return true in cases where the command fails, so that the script does not
  # stop early.
  touch -c "$VIVALDI_INSTALL_DIR/icons/hicolor" 2>/dev/null ||:
  if available gtk-update-icon-cache; then
    gtk-update-icon-cache -tq "$VIVALDI_INSTALL_DIR/icons/hicolor" 2>/dev/null ||:
  fi
  if available update-desktop-database; then
    update-desktop-database -q "$VIVALDI_INSTALL_DIR/applications" 2>/dev/null ||:
  fi
}

# Stop if any error is encountered
set -e

# Remove installed files and directories (if empty)
while read f; do
  # '-e' alone would not find broken symlinks
  if [ -e "\$f" -o -h "\$f" ]; then
    if [ -d "\$f" ]; then
      if ! ls -A "\$f" | grep -q ^; then
        # Don't remove a symlink pointing to a directory, as it could have
        # been created by the user or the distribution
        if [ ! -h "\$f" ]; then
          rmdir "\$f"
        fi
      fi
    else
      rm "\$f"
      printf '.'
    fi
  fi
done << FILE_LIST
END

# Record the version number in the package
touch ".$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/VERSION_$VIVALDI_VERSION"

# Symlink desktop environment icons to icons within the package
for png in ".$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/"product_logo_*.png; do
  pngsize="${png##*/product_logo_}"
  mkdir -p ".$VIVALDI_INSTALL_DIR/icons/hicolor/${pngsize%.png}x${pngsize%.png}/apps"
  ln -fs "$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/product_logo_${pngsize}" ".$VIVALDI_INSTALL_DIR/icons/hicolor/${pngsize%.png}x${pngsize%.png}/apps/$VIVALDI_STREAM_SHORT.png"
done

# Update the executable path in the desktop launcher
sed -i "/^Exec=/s,=.*$VIVALDI_STREAM ,=\"$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/$VIVALDI_STREAM_SHORT\" ," ".$VIVALDI_INSTALL_DIR/applications/$VIVALDI_STREAM.desktop"

# Create a symlink between the old and new uninstall locations. This helps
# people to locate the uninstall script, alongside the other files
ln -fs "$UNINSTALL_VIVALDI_SCRIPT" ".$UNINSTALL_VIVALDI_SCRIPT_OLD"

# Create symlinks in /usr/local/bin or $HOME/bin when possible, since
# these directories are likely to be in the user's path.
CREATE_PATH_SYMLINKS=N
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
  CREATE_PATH_SYMLINKS=Y
  SYMLINK_PATH="/usr/local/bin"
elif [ -d "$HOME/bin" ] && [ -w "$HOME/bin" ]; then
  CREATE_PATH_SYMLINKS=Y
  SYMLINK_PATH="$HOME/bin"
fi
if [ "$CREATE_PATH_SYMLINKS" = "Y" ]; then
  mkdir -p ".$SYMLINK_PATH"
  ln -fs "$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/$VIVALDI_STREAM_SHORT" ".$SYMLINK_PATH/."
  ln -fs "$UNINSTALL_VIVALDI_SCRIPT" ".$SYMLINK_PATH/remove-${VIVALDI_STREAM_SHORT}.sh"
fi

# Find all files and add them to the uninstall script with their absolute paths
find . ! -type d | sed 's,^\.,,' | grep -Fxv "$UNINSTALL_VIVALDI_SCRIPT" >> ".$UNINSTALL_VIVALDI_SCRIPT"

# Find all directories and add them to the uninstall script with their absolute
# paths. Standard system directories are filtered out
find . -depth -type d | sed 's,^\.,,;/^\.\?$/d' | \
  grep -Fxv \
    -e '/home' \
    -e "$HOME" \
    -e "$HOME/bin" \
    -e "$HOME/.local" \
    -e "$VIVALDI_INSTALL_DIR" \
    -e '/usr' \
    -e '/usr/local' \
    -e '/usr/local/bin' \
    -e '/usr/local/share/doc' \
    -e '/usr/local/share/man' \
    -e '/usr/local/share/man/man1' >> ".$UNINSTALL_VIVALDI_SCRIPT"
cat << END >> ".$UNINSTALL_VIVALDI_SCRIPT"
FILE_LIST
updatedbs
rm "$UNINSTALL_VIVALDI_SCRIPT"
printf '. done\n\n'
END

# Don't register desktop files and icons, in non-standard locations
if [ "$REGISTER_DESKTOP_AND_ICONS" = "N" ]; then
  sed -i '/^updatedbs$/s/^/#/' ".$UNINSTALL_VIVALDI_SCRIPT"
fi

# Make the uninstall script executable
chmod 755 ".$UNINSTALL_VIVALDI_SCRIPT"

# If an old Vivaldi is already installed, remove it first
VIVALDI_UPGRADE=N
remove_previous_upgrade () {
  VIVALDI_UPGRADE=Y
  printf '                                    * * *\n\n'
  echo "Removing previously installed $VIVALDI_STREAM first"
  "$1"
}
if [ -x "$UNINSTALL_VIVALDI_SCRIPT" ]; then
  remove_previous_upgrade "$UNINSTALL_VIVALDI_SCRIPT"
elif [ -x "$UNINSTALL_VIVALDI_SCRIPT_OLD" ]; then
  remove_previous_upgrade "$UNINSTALL_VIVALDI_SCRIPT_OLD"
elif [ "$USER" = "root" -a -x "$UNINSTALL_VIVALDI_SCRIPT_ANCIENT" ]; then
  remove_previous_upgrade "$UNINSTALL_VIVALDI_SCRIPT_ANCIENT"
fi

# Install the files only, *not* directories by use of a tar pipe
# This avoids changing system directory permissions and ownership
printf "Installing $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH} ...\n\n"
find . ! -type d | tar -cf- -T- | tar -xf- -C /

# Remove temporary files
cleanup_before_exit

# Correct the Vivaldi sandbox permissions, when installed by root
# Needed on Arch based distros due to a kernel without user namespace support
if [ "$USER" = "root" ]; then
  chmod 4755 "$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/vivaldi-sandbox"
fi

# Update the icon and desktop databases
if [ "$REGISTER_DESKTOP_AND_ICONS" = "Y" ]; then
  touch -c "$VIVALDI_INSTALL_DIR/icons/hicolor" 2>/dev/null ||:
  if available gtk-update-icon-cache; then
    gtk-update-icon-cache -tq "$VIVALDI_INSTALL_DIR/icons/hicolor" 2>/dev/null ||:
  fi
  if available update-desktop-database; then
    update-desktop-database -q "$VIVALDI_INSTALL_DIR/applications" 2>/dev/null ||:
  fi
fi

# Extract the cron job key handling functions and adapt them for use with gpg
# instead of apt-key. This allows updates to have their signatures checked
if [ -r "$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/cron/$VIVALDI_STREAM_SHORT" ]; then
  VIVALDI_CRON="$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/cron/$VIVALDI_STREAM_SHORT"
  VIVALDI_KEY_FUNCTIONS="$(mktemp -t vivaldi-key-functions.XXXXXX)"
  sed -n '/^\(remove_old\|install\(_future\)\?\)_key() {/,/^}$/p' "$VIVALDI_CRON" | sed \
    -e 's/ apt-key / gpg /' \
    -e 's/\("$APT_KEY"\) del /\1 --no-tty --quiet --batch --yes --delete-key /' \
    -e 's/\("$APT_KEY"\) list /\1 --list-keys /;s/\("$APT_KEY"\) add - /\1 --import /' \
    > "$VIVALDI_KEY_FUNCTIONS"
  . "$VIVALDI_KEY_FUNCTIONS"
  rm "$VIVALDI_KEY_FUNCTIONS"
  # Run each of the Vivaldi cron job key handling functions
  for KEY_CMD in remove_old_key install_key install_future_key; do
    if available "$KEY_CMD"; then
      "$KEY_CMD" ||:
    fi
  done
fi

# And ... we're done! ;) Let the user know what is next
printf '                                    * * *\n\n'
echo "Vivaldi was successfully installed into \"$VIVALDI_INSTALL_DIR\""
if [ "$REGISTER_DESKTOP_AND_ICONS" = "Y" ]; then
  printf "\nRe-login to your desktop environment if $VIVALDI_STREAM does not immediately show up.\n"
fi
printf '\n                                    * * *\n\n'
printf "You can start $VIVALDI_STREAM manually via the following command:\n\n"
if [ "$CREATE_PATH_SYMLINKS" = "Y" ]; then
  echo "    $SYMLINK_PATH/$VIVALDI_STREAM_SHORT&"
else
  echo "    $VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/$VIVALDI_STREAM_SHORT&"
fi
if [ "$USER" = "root" ]; then
  printf "\nTo uninstall, issue the following as root (or prefaced with sudo):\n\n"
else
  printf "\nTo uninstall, issue the following:\n\n"
fi
if [ "$CREATE_PATH_SYMLINKS" = "Y" ]; then
  printf "    $SYMLINK_PATH/remove-${VIVALDI_STREAM_SHORT}.sh\n\n"
else
  printf "    $UNINSTALL_VIVALDI_SCRIPT\n\n"
fi

# Try and launch Vivaldi for new users, who are not running as root when
# possible, and assuming they haven't disabled it ;)
if available nohup && [ "$VIVALDI_UPGRADE" = "N" -a "$VIVALDI_LAUNCH" = "Y" -a "$USER" != "root" ]; then
  printf '                                    * * *\n\n'
  printf "Attempting to launch $VIVALDI_STREAM ($VIVALDI_VERSION) for ${VIVALDI_ARCH} ...\n\n"
  nohup "$VIVALDI_INSTALL_DIR/$VIVALDI_STREAM_SHORT/$VIVALDI_STREAM_SHORT" >/dev/null 2>&1 &
fi
exit
