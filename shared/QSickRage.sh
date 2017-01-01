#! /bin/sh

QPKG_NAME=QSickRage
QPKG_DIR=$(/sbin/getcfg $QPKG_NAME Install_Path -f /etc/config/qpkg.conf)
PID_FILE="$QPKG_DIR/config/sickrage.pid"

DAEMON_OPTS="SickBeard.py --datadir $QPKG_DIR/config --daemon --pidfile $PID_FILE --port 7073"

# Determine Arch
ver="none"
arch="$(/bin/uname -m)"
if [[ $arch == "*arm*" ]]; then
    ver="arm";
elif [[ $arch == "*i686*" ]]; then
    ver="x86";
elif [[ $arch == "*x86_64*" ]]; then
    ver="x86_64"
else
    err_log "Could not determine architecture from $arch";
fi

# Add all possible paths to python2.7
export PATH=${QPKG_DIR}/${ver}/bin-utils:/Apps/bin:/Apps/opt/bin:/opt/QPython2/bin:/opt/bin:/usr/local/bin:/usr/bin:/bin:$PATH

CheckQpkgEnabled() { # Is the QPKG enabled? if not exit the script
  if [ $($CMD_GETCFG ${QPKG_NAME} Enable -u -d FALSE -f /etc/config/qpkg.conf) = UNKNOWN ]; then
      $CMD_SETCFG ${QPKG_NAME} Enable TRUE -f /etc/config/qpkg.conf
  elif [ $($CMD_GETCFG ${QPKG_NAME} Enable -u -d FALSE -f /etc/config/qpkg.conf) != TRUE ]; then
      $CMD_ECHO "${QPKG_NAME} is disabled."
      exit 1
  fi
}

ConfigPython(){
  # python dependency checking
    DAEMON=$($CMD_GETCFG Python2 path -u -d None -f /etc/config/qpkg.conf)
    [ -x $DAEMON ] && return

    DAEMON=$(which python2.7)
    VER=0
    [ -x $DAEMON ] && VER=$(expr substr "$($DAEMON -V 2>&1)" 8 8)
    for path in $(echo $PATH | tr ':' "\n"); do
        echo "Looking for $path/python2.7"
        [ -x path/python2.7 ] || continue
        version=$(expr substr "$(${path}/python2.7 -V 2>&1)" 8 8)
        [ $version == 2.7* ] || continue
        if [ $version > $VER ]; then
            DAEMON=$path/python2.7
            VER=$version
        fi
    done
    if [ ! -x $DAEMON ]; then
        log_error "Failed to start $QPKG_NAME, Python was not found. Please re-install the Python qpkg." 1
        exit 1
    else
        log "Found Python Version ${VER} at ${DAEMON}"
        $CMD_SETCFG Python2 path $DAEMON -f /etc/config/qpkg.conf
    fi
}

CheckQpkgRunning() { # Is the QPKG already running? if so, exit the script
  if [ -f $PID_FILE ]; then
    # grab pid from pid file
    Pid=$($CMD_CAT $PID_FILE)
    if [ -d /proc/$Pid ]; then
      log "$QPKG_NAME is already running"
      exit 1
    fi
  fi
  # ok, we survived so the QPKG should not be running
}

StartQpkg(){
    log "Starting $QPKG_NAME"
    cd $QPKG_DIR/$QPKG_NAME
    PATH=${PATH} ${DAEMON} ${DAEMON_OPTS}
}

ShutdownQPKG() { # kills a proces based on a PID in a given PID file
    log "Shutting down ${QPKG_NAME}... "
    if [ -f $PID_FILE ]; then
        # grab pid from pid file
        Pid=$($CMD_CAT $PID_FILE)
        i=0
        /bin/kill $Pid
        log " Waiting for ${QPKG_NAME} to shut down: "
        while [ -d /proc/$Pid ]; do
            sleep 1
            let i+=1
            /bin/echo -n "$i, "
            if [ $i = 45 ]; then
                log_warn " Tired of waiting, killing ${QPKG_NAME} now"
                /bin/kill -9 $Pid
                /bin/rm -f $PID_FILE
                exit 1
            fi
        done
        $CMD_RM -f $PID_FILE
        log "Done"
    else
        log "${QPKG_NAME} is not running?"
    fi
}

case "$1" in
    start)
        CheckQpkgEnabled # Check if the QPKG is enabled, else exit
        CheckQpkgRunning # Check if the QPKG is not running, else exit
        ConfigPython   # Check for Python, exit if not found
        StartQpkg    # Finally Start the qpkg
        ;;
  stop)
        ShutdownQPKG
        ;;
  restart)
        echo "Restarting $QPKG_NAME"
        $0 stop
        $0 start
        ;;
  *)
        N=/etc/init.d/$QPKG_NAME.sh
        $CMD_ECHO "Usage: $N {start|stop|restart}" >&2
        exit 1
        ;;
esac
