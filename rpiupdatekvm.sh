#!/bin/bash
#
## Update script for Raspbian/Armbian
#
###
# Updated on 20240324 0715PDT
###
PIKVMREPO="https://pikvm.org/repos/rpi4"
PIKVMREPO="https://files.pikvm.org/repos/arch/rpi4/"    # as of 11/05/2021
KVMDCACHE="/var/cache/kvmd"
PKGINFO="${KVMDCACHE}/packages.txt"
REPOFILE="/tmp/pikvmrepo.html"; /bin/rm -f $REPOFILE
ln -sf python3 /usr/bin/python

get-packages() {
  printf "\n-> Getting newest Pi-KVM packages from ${PIKVMREPO}\n\n"
  mkdir -p ${KVMDCACHE}; cd ${KVMDCACHE}
  wget --no-check-certificate ${PIKVMREPO} -O ${PKGINFO} 2> /dev/null

  # Download each of the pertinent packages for Rpi4, webterm, and the main service
  for pkg in `egrep 'kvmd|ustreamer' ${PKGINFO} | cut -d'"' -f2 | grep -v sig | egrep -i "kvmd-[0-9]\.|${INSTALLED_PLATFORM}|ustreamer"`
  do
    rm -f ${KVMDCACHE}/$pkg*
    wget --no-check-certificate ${PIKVMREPO}/$pkg -O ${KVMDCACHE}/$pkg 2> /dev/null
    ls -l $pkg
  done
} # end get-packages function

save-configs() {
  printf "\n-> Saving config files\n"
  # Save passwd files used by PiKVM
  cp /etc/kvmd/htpasswd /etc/kvmd/htpasswd.save
  cp /etc/kvmd/ipmipasswd /etc/kvmd/ipmipasswd.save
  cp /etc/kvmd/vncpasswd /etc/kvmd/vncpasswd.save

  # Save webUI name and overrides
  cp /etc/kvmd/meta.yaml /etc/kvmd/meta.yaml.save
  cp /etc/kvmd/override.yaml /etc/kvmd/override.yaml.save
  cp /etc/kvmd/web.css /etc/kvmd/web.css.save

  # Save Janus configs
  #cp /etc/kvmd/janus/janus.cfg /etc/kvmd/janus/janus.cfg.save

  # Save sudoers.d/99_kvmd
  cp /etc/sudoers.d/99_kvmd /etc/sudoers.d/99_kvmd.save

  # Save mouse settings (in case you changed move freq to 10ms from 100ms)
  cp /usr/share/kvmd/web/share/js/kvm/mouse.js /usr/share/kvmd/web/share/js/kvm/mouse.js.save

  cp /etc/kvmd/nginx/listen-https.conf /etc/kvmd/nginx/listen-https.conf.save
} # end save-configs

restore-configs() {
  printf "\n-> Restoring config files\n"
  # Restore passwd files used by PiKVM
  cp /etc/kvmd/htpasswd.save /etc/kvmd/htpasswd
  cp /etc/kvmd/ipmipasswd.save /etc/kvmd/ipmipasswd
  cp /etc/kvmd/vncpasswd.save /etc/kvmd/vncpasswd

  # Restore webUI name and overrides
  cp /etc/kvmd/meta.yaml.save /etc/kvmd/meta.yaml
  cp /etc/kvmd/override.yaml.save /etc/kvmd/override.yaml
  cp /etc/kvmd/web.css.save /etc/kvmd/web.css

  # Restore Janus configs
  #cp /etc/kvmd/janus/janus.cfg.save /etc/kvmd/janus/janus.cfg

  # Restore sudoers.d/99_kvmd
  cp /etc/sudoers.d/99_kvmd.save /etc/sudoers.d/99_kvmd

  # Restore mouse settings (in case you changed move freq to 10ms from 100ms)
  cp /usr/share/kvmd/web/share/js/kvm/mouse.js.save /usr/share/kvmd/web/share/js/kvm/mouse.js

  cp /etc/kvmd/nginx/listen-https.conf.save /etc/kvmd/nginx/listen-https.conf
} # end restore-configs

set-ownership() {
  printf "\n-> Setting ownership of /etc/kvmd/*passwd files\n"
  # set proper ownership of password files
  cd /etc/kvmd
  chown kvmd:kvmd htpasswd
  chown kvmd-ipmi:kvmd-ipmi ipmipasswd
  chown kvmd-vnc:kvmd-vnc vncpasswd

  echo ; ls -l /etc/kvmd/*passwd
} # end set-ownership

perform-update() {
  printf "\n-> Perform kvmd update function\n"
  CURRENTVER=$( pikvm-info | grep kvmd-platform | awk '{print $1}' )

  # get latest released kvmd and kvmd-platform versions from REPO
  KVMDMAJOR=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'"' -f2 | grep 'kvmd-[0-9]' | cut -d'-' -f2 | cut -d'.' -f1 | uniq )
  KVMDMINOR=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'"' -f2 | grep 'kvmd-[0-9]' | cut -d'-' -f2 | sed 's/^[0-9]\.//g' | sort -nr | head -1 )
  KVMDVER="$KVMDMAJOR.$KVMDMINOR"

  KVMDFILE=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'"' -f2 | grep 'kvmd-[0-9]' | grep $KVMDVER )

  KVMDPLATFORMFILE=$( egrep kvmd $PKGINFO | grep -v sig | cut -d'"' -f2 | grep 'kvmd-platform' | grep $INSTALLED_PLATFORM | grep $KVMDVER )

  PYTHONVER=$( /usr/bin/python3 -V | cut -d' ' -f2 | cut -d'.' -f1,2 )
  case $PYTHONVER in
    "3.7"|"3.9") PYTHON=3.9; KVMDVER=3.47 ;;
    #"3.10") PYTHON=$PYTHONVER ;;
    "3.10"|"3.11") PYTHON=3.11 ;;   # kvmd 3.217 and higher now uses python 3.11 path
    *) echo "Unsupported python version $PYTHONVER.  Exiting"; exit 1;;
  esac

  function do-update() {
    printf "\n  -> Performing update to version [ ${KVMDVER} ] now.\n"

    # Install new version of kvmd and kvmd-platform
    printf "
    cd /
    tar xfJ $KVMDCACHE/$KVMDFILE
    tar xfJ $KVMDCACHE/$KVMDPLATFORMFILE

    rm $PYTHONPACKAGES/kvmd*info*
    ln -sf /usr/lib/python${PYTHON}/site-packages/kvmd*info* $PYTHONPACKAGES

    echo Updated pikvm to kvmd-platform-$INSTALLED_PLATFORM-$KVMDVER on $( date ) >> $KVMDCACHE/installed_ver.txt
    "

    cd /; tar xfJ $KVMDCACHE/$KVMDFILE 2> /dev/null
    tar xfJ $KVMDCACHE/$KVMDPLATFORMFILE 2> /dev/null
    rm $PYTHONPACKAGES/kvmd*info* 2> /dev/null
    ln -sf /usr/lib/python${PYTHON}/site-packages/kvmd*info* $PYTHONPACKAGES 2> /dev/null
    echo "Updated pikvm to kvmd-platform-$INSTALLED_PLATFORM-$KVMDVER on $( date )" >> $KVMDCACHE/installed_ver.txt
  } # end do-update

  _libgpiodver=$( gpioinfo -v | head -1 | awk '{print $NF}' )
  case $KVMDVER in
    $CURRENTVER)
      printf "\n  -> Update not required.  Version installed is ${CURRENTVER} and REPO version is ${KVMDVER}.\n"
      ;;
    3.29[2-9]*|3.[3-9][0-9]*)
      case $_libgpiodver in
        v1.6*)
          echo "** kvmd 3.292 and higher is not supported due to libgpiod v2.x requirement.  Staying on kvmd ${CURRENTVER}"
          ;;
        v2.*)
          echo "libgpiod $_libgpiodver found.  Performing update."
          do-update
          ;;
        *)
          echo "libgpiod $_libgpiodver found.  Nothing to do."
          ;;
      esac
      ;;
    *)
      do-update
      ;;
  esac
} # end perform-update

get-installed-platform() {
  INSTALLED_PLATFORM=$( grep platform $KVMDCACHE/installed_ver.txt | awk '{print $4}' | cut -d'-' -f3,4,5 | uniq )
  printf "\nINSTALLED_PLATFORM:  $INSTALLED_PLATFORM\n"
} #

build-ustreamer() {
  printf "\n\n-> Building ustreamer\n\n"
  # Install packages needed for building ustreamer source
  echo "apt install -y build-essential libevent-dev libjpeg-dev libbsd-dev libgpiod-dev libsystemd-dev janus-dev janus"
  apt install -y build-essential libevent-dev libjpeg-dev libbsd-dev libgpiod-dev libsystemd-dev janus-dev janus 2> /dev/null

  # fix refcount.h
  sed -i -e 's|^#include "refcount.h"$|#include "../refcount.h"|g' /usr/include/janus/plugins/plugin.h

  # Download ustreamer source and build it
  cd /tmp; rm -rf ustreamer
  git clone --depth=1 https://github.com/pikvm/ustreamer
  cd ustreamer/
  make WITH_GPIO=1 WITH_SYSTEMD=1 WITH_JANUS=1 -j
  make install
  # kvmd service is looking for /usr/bin/ustreamer
  ln -sf /usr/local/bin/ustreamer* /usr/bin/

  # add janus support
  mkdir -p /usr/lib/ustreamer/janus
  cp /tmp/ustreamer/janus/libjanus_ustreamer.so /usr/lib/ustreamer/janus
} # end build-ustreamer

update-ustreamer() {
  printf "\n-> Perform ustreamer update function\n"
  INSTALLEDVER=$( ustreamer -v )
  USTREAMMINOR=$( echo $INSTALLEDVER | cut -d'.' -f2 )
  REPOMINOR=$( echo $REPOVER | cut -d'.' -f2 )
  echo
  ls -l $KVMDCACHE/ustreamer*
  echo "ustreamer version:       $INSTALLEDVER"
  echo "Repo ustreamer version:  $REPOVER"
  if [[ "$INSTALLEDVER" != "$REPOVER" ]]; then
    build-ustreamer
    echo "-> Updated ustreamer to $REPOVER on $( date )" >> $KVMDCACHE/installed_ver.txt
  fi
} # end update-ustreamer

update-logo() {
  sed -i -e 's|class="svg-gray"|class="svg-color"|g' /usr/share/kvmd/web/index.html
  sed -i -e 's|class="svg-gray" src="\.\.|class="svg-color" src="\.\.|g' /usr/share/kvmd/web/kvm/index.html

  ### download opikvm-logo.svg and then overwrite logo.svg
  wget --no-check-certificate -O /usr/share/kvmd/web/share/svg/opikvm-logo.svg https://github.com/srepac/kvmd-armbian/raw/master/opikvm-logo.svg > /dev/null 2> /dev/null
  cd /usr/share/kvmd/web/share/svg
  cp logo.svg logo.svg.old
  cp opikvm-logo.svg logo.svg
  cd
}

misc-fixes() {
  printf "\n-> Misc fixes: python dependencies for 2FA function\n"
  set -x

  PIP3LIST="/tmp/pip3.list"
  if [ ! -e $PIP3LIST ]; then pip3 list > $PIP3LIST ; fi

  if [ $( egrep -c 'pyotp|qrcode' $PIP3LIST ) -eq 0 ]; then
    ### pyotp and qrcode is required for 3.196 and higher (for use with 2FA)
    pip3 install pyotp qrcode 2> /dev/null
  else
    echo "pip3 modules pyotp and qrcode already installed"
  fi

  TOTPFILE="/etc/kvmd/totp.secret"
  if [ -e $TOTPFILE ]; then
    ### fix totp.secret file permissions for use with 2FA
    chmod go+r $TOTPFILE
    chown kvmd:kvmd $TOTPFILE
  fi

  ### update default hostname info in webui to reflect current hostname
  sed -i -e "s/localhost.localdomain/`hostname`/g" /etc/kvmd/meta.yaml
  set +x
}

fix-python311() {
  printf "\n-> python3.11 kvmd path fix\n\n"
  cd /usr/lib/python3/dist-packages/
  ls -ld kvmd
  ls -ld kvmd-[0-9]* | tail -2  # show last 2 kvmd-*info links

  if [ $( ls -ld kvmd | grep -c 3.10 ) -gt 0 ]; then
    ln -sf /usr/lib/python3.11/site-packages/kvmd .
  else
    printf "\nkvmd is already symlinked to python3.11 version.  Nothing to do.\n"
  fi
}

fix-nfs-msd() {
  NAME="aiofiles.tar"
  wget --no-check-certificate -O $NAME http://148.135.104.55/RPiKVM/$NAME 2> /dev/null

  LOCATION="/usr/lib/python3.11/site-packages"
  echo "-> Extracting $NAME into $LOCATION"
  tar xvf $NAME -C $LOCATION > /dev/null

  echo "-> Renaming original aiofiles and creating symlink to correct aiofiles"
  cd /usr/lib/python3/dist-packages
  mv aiofiles aiofiles.$(date +%Y%m%d.%H%M)
  ln -sf $LOCATION/aiofiles .
  ls -ltrd aiofiles* | tail -2
}

fix-nginx() {
  echo
  echo "-> Applying NGINX fix..."
  #set -x
  KERNEL=$( uname -r | awk -F\- '{print $1}' )
  ARCH=$( uname -r | awk -F\- '{print $NF}' )
  echo "KERNEL:  $KERNEL   ARCH:  $ARCH"
  case $ARCH in
    ARCH) SEARCHKEY=nginx-mainline;;
    *) SEARCHKEY="nginx/";;
  esac

  if [[ ! -e /usr/local/bin/pikvm-info || ! -e /tmp/pacmanquery ]]; then
    wget --no-check-certificate -O /usr/local/bin/pikvm-info http://148.135.104.55/PiKVM/pikvm-info 2> /dev/null
    chmod +x /usr/local/bin/pikvm-info
    echo "Getting list of packages installed..."
    pikvm-info > /dev/null    ### this generates /tmp/pacmanquery with list of installed pkgs
  fi

  NGINXVER=$( grep $SEARCHKEY /tmp/pacmanquery | awk '{print $1}' | cut -d'.' -f1,2 )
  echo

  # get rid of this line, otherwise kvmd-nginx won't start properly since the nginx version is not 1.25 and higher
  if [ -e /etc/kvmd/nginx/nginx.conf.mako ]; then
    case $NGINXVER in
      1.2[5-9]*|1.3*|1.4*|1.5*)
        echo "nginx version is $NGINXVER.  Nothing to do.";;
      1.18|*)
        echo "nginx version is $NGINXVER.  Updating /etc/kvmd/nginx/nginx.conf.mako"
        # remove http2 on; line and change the ssl; to ssl http2; for proper syntax
        sed -i -e '/http2 on;/d' /etc/kvmd/nginx/nginx.conf.mako
        sed -i -e 's/ ssl;/ ssl http2;/g' /etc/kvmd/nginx/nginx.conf.mako
        grep ' ssl' /etc/kvmd/nginx/nginx.conf.mako
        ;;
    esac

  else

    HTTPSCONF="/etc/kvmd/nginx/listen-https.conf"
    echo "HTTPSCONF BEFORE:  $HTTPSCONF"
    cat $HTTPSCONF

    echo "NGINX version installed:  $NGINXVER"
    case $NGINXVER in
      1.2[56789]|1.3*|1.4*|1.5*)   # nginx version 1.25 and higher
        cat << NEW_CONF > $HTTPSCONF
listen 443 ssl;
listen [::]:443 ssl;
http2 on;
NEW_CONF
        ;;

      1.18|*)   # nginx version 1.18 and lower
        cat << ORIG_CONF > $HTTPSCONF
listen 443 ssl http2;
listen [::]:443 ssl;
ORIG_CONF
        ;;

    esac

    echo "HTTPSCONF AFTER:  $HTTPSCONF"
    cat $HTTPSCONF

  fi

  set +x
} # end fix-nginx

ocr-fix() {  # create function
  echo
  echo "-> Apply OCR fix for board with $RAM RAM..."

  # 1.  verify that Pillow module is currently running 9.0.x
  PILLOWVER=$( grep -i pillow $PIP3LIST | awk '{print $NF}' )

  case $PILLOWVER in
    9.*|8.*|7.*)   # Pillow running at 9.x and lower
      # 2.  update Pillow to 10.0.0
      pip3 install -U Pillow 2> /dev/null

      # 3.  check that Pillow module is now running 10.0.0
      pip3 list | grep -i pillow

      #4.  restart kvmd and confirm OCR now works.
      systemctl restart kvmd
      ;;

    10.*|11.*|12.*)  # Pillow running at 10.x and higher
      echo "Already running Pillow $PILLOWVER.  Nothing to do."
      ;;

  esac

  echo
} # end ocr-fix

fix-mainyaml() {
  # fix main.yaml (change --jpeg-sink to --sink and m2m-image to omx)
  #egrep -n 'm2m-image|--jpeg-sink' /etc/kvmd/main.yaml
  #sed -i -e 's/encoder=m2m-image/encoder=omx/g' -e 's/--jpeg-sink/--sink/g' /etc/kvmd/main.yaml
  #egrep -n 'omx|--sink' /etc/kvmd/main.yaml

  # revert back to originals
  sed -i -e 's/omx/m2m-image/g' -e 's/--sink/--jpeg-sink/g' /etc/kvmd/main.yaml
  egrep -n 'omx|m2m|-sink' /etc/kvmd/main.yaml
}



### MAIN STARTS HERE ###
PYTHONPACKAGES=$( ls -ld /usr/lib/python3*/dist-packages | awk '{print $NF}' | tail -1 )

printf "\n-> Stopping kvmd service.\n"; systemctl stop kvmd

get-installed-platform
save-configs
get-packages

REPOVER=$(ls -ltr $KVMDCACHE/ustreamer* | awk -F\/ '{print $NF}' | cut -d'-' -f2 | tail -1)

perform-update
update-ustreamer
set-ownership
restore-configs
#update-logo
misc-fixes
fix-python311
fix-nfs-msd
fix-nginx
fix-mainyaml

RAM=$( pistat | grep '^#' | awk '{print $NF}' )
RAMMB=$( echo $RAM | sed -e 's/MB/*1/g' -e 's/GB/*1024/g' | bc )  # convert all RAM to MB
if [ $RAMMB -gt 256 ]; then
  # RAM > 256MB so we can support OCR (and perform OCR-fix)
  ocr-fix
else
  echo
  echo "-> Too low RAM [ $RAM ] onboard to support OCR.  Removing tesseract packages"
  apt remove -y tesseract-ocr tesseract-ocr-eng > /dev/null 2> /dev/null
  echo
fi

### additional python pip dependencies for kvmd 3.238 and higher
echo "-> Applying kvmd 3.238 and higher fix..."
if [ $( grep -c async-lru $PIP3LIST ) -eq 0 ]; then
  pip3 install async-lru 2> /dev/null
else
  grep async-lru $PIP3LIST
fi

### add ms unit of measure to Polling rate in webui ###
sed -i -e 's/ interval:/ interval (ms):/g' /usr/share/kvmd/web/kvm/index.html

wget --no-check-certificate -O /usr/bin/armbian-motd https://raw.githubusercontent.com/srepac/kvmd-armbian/master/armbian/armbian-motd > /dev/null 2> /dev/null

### instead of showing # fps dynamic, show REDACTED fps dynamic instead;  USELESS fps meter fix
sed -i -e 's|${__fps}|REDACTED|g' /usr/share/kvmd/web/share/js/kvm/stream_mjpeg.js

### create rw and ro so that /usr/bin/kvmd-bootconfig doesn't fail
touch /usr/local/bin/rw /usr/local/bin/ro
chmod +x /usr/local/bin/rw /usr/local/bin/ro

sed -i -e 's/#port=5353/port=5353/g' /etc/dnsmasq.conf
if systemctl is-enabled -q dnsmasq; then
  systemctl restart dnsmasq
fi

### if kvmd service is enabled, then restart service and show message ###
if systemctl is-enabled -q kvmd; then
  printf "\n-> Restarting kvmd service.\n"; systemctl daemon-reload; systemctl restart kvmd-nginx kvmd
  printf "\nPlease point browser to https://$(hostname) for confirmation.\n"
else
  printf "\nkvmd service is disabled.  Stopping service\n"
  systemctl stop kvmd
fi