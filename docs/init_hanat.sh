#!/bin/bash
#
# Startup script for hanat
#
# chkconfig: - 99 1
# description: hanat
#

# Source function library.
. /etc/rc.d/init.d/functions

prog=hanat
pidfile=/var/run/$prog.pid
lockfile=/var/lock/subsys/$prog

basedir=/opt/hanat
exec=$basedir/bin/hanat.sh
logfile=$basedir/logs/hanat.log

start() {
    echo -n $"Starting $prog: "
    nohup $exec < /dev/null >> $logfile 2>&1 &
    RETVAL=$?
    PID=$!
    [ $RETVAL = 0 ] && touch $lockfile && echo $PID > $pidfile && success || failure
    echo
    return $RETVAL
}

stop() {
    echo -n $"Stopping $prog: "
    killproc -p $pidfile $exec
    RETVAL=$?
    echo
    [ $RETVAL = 0 ] && rm -f $lockfile
    return $RETVAL
}

rh_status() {
    status -p $pidfile $exec
}

rh_status_q() {
    rh_status > /dev/null 2>&1
}

case "$1" in
    start)
	rh_status_q && exit 0
        start
	;;
    stop)
	rh_status_q || exit 0
	stop
	;;
    restart)
	stop
	start
	;;
    status)
	rh_status
        ;;
    *)
	echo $"Usage: $prog {start|stop|restart|status}"
	exit 1
esac

exit $RETVAL

