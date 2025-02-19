#!/bin/sh

# Copyrights     : CNRS
# Author         : Oleg Lodygensky
# Acknowledgment : XtremWeb-HEP is based on XtremWeb 1.8.0 by inria : http://www.xtremweb.net/
# Web            : http://www.xtremweb-hep.org
# 
#      This file is part of XtremWeb-HEP.
#
#    XtremWeb-HEP is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    XtremWeb-HEP is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with XtremWeb-HEP.  If not, see <http://www.gnu.org/licenses/>.
#
#



#
# xtremwebconf.sh      this file sets some parameters
#
# Requirements  : ROOTDIR variable must be set before calling this file
# Params : [--jvmopts]
#          --jvmopts tells to optimize java (this may be source to troubles :( )
#
# Author : Oleg Lodygensky (lodygens -a-t- lal.in2p3.fr)
#
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# **                DO NOT EDIT                     **
# **   This file is generated by install script     **
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#


#
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#  One can modify these variables
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#
# the nice priority
V_NICE=10


#
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#   Following should not be changed
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
#


#
# return codes
#   0 on success
#   1 on usage error
#   2 on file error (files not found)
#   3 if LAUNCHER URL does not contains server version, the server cowardly refuses to start 
#   4 if not in the expected state :
#      ** stop  asked but not running
#      ** start asked but already running
#   5 on user error (user not found)
#
#
ERROK=0
ERRUSAGE=1
ERRFILE=2
ERRCONNECTION=3
ERRSTATE=4
ERRUSER=5


LOGDIR=/var/log



#
# since 8.0.0 we use SmartSockets
#
IBISHUBCLASS="ibis.smartsockets.util.HubStarter"
IBISHUBPORTNAME="SMARTSOCKETSPORT"
IBISHUBPORTDEFAULT=4329
IBISHUBPORT=4329
IBISHUBADDRESSNAME="SMARTSOCKETSEXTERNALADDRESS"
IBISHUBADDRESS=""
IBISLOG=$LOGDIR/xwhep-ibishub.log
touch $IBISLOG

#
# The middleware must not run as root
# $XWUSER is a new user created by installers
# Note that uninstaller do not remove that user: it must be done manually
#
XWUSER=@XWUSER@

if [ "X$ROOTDIR" = "X" ]; then
    echo "`date` [`uname -n` $PROG] ERROR : ROOTDIR is not set"
    return $ERRUSAGE
fi

XWFORMAT=""
XWVERBOSE=""
XWDOWNLOAD=""

BINDIR=$ROOTDIR/bin
BINFILE=$BINDIR/xtremweb
LIBDIR=$ROOTDIR/lib
CFGDIR=$ROOTDIR/conf
CFGFILE=$CFGDIR/$PROG.conf
RESOURCESDIR=$ROOTDIR/resources
LOG4JCONFIGFILENAME=log4j.xml


[ "X$PROG" = "Xxtremweb.rpc"     ] && CFGFILE=$CFGDIR/xtremweb.client.conf
[ "X$PROG" = "Xxtremweb.tests"   ] && CFGFILE=$CFGDIR/xtremweb.client.conf
[ "X$PROG" = "Xxwhep.bridge"     ] && CFGFILE=$CFGDIR/xtremweb.client.conf
#[ "X$PROG" = "Xxtremweb.ganglia" ] && CFGFILE=$CFGDIR/xtremweb.client.conf
[ "X$PROG" = "Xxtremweb.monitor" ] && CFGFILE=$CFGDIR/xtremweb.worker.conf
[ "X$PROG" = "Xxwhep.probe"      ] && CFGFILE=$CFGDIR/xtremweb.worker.conf

if [ -f  "$HOME/.xtremweb/$PROG.conf" ] ; then
    CFGDIR="$HOME/.xtremweb/"
    CFGFILE="$CFGDIR/$PROG.conf"
fi

#
# Parse options
#
# --jvmopts command line argument to optimize java
JVMOPTS=0
while [ $# -gt 0 ]; do
    case $1 in
        "-h" | "--help" | "--xwhelp" )
            PARAMS="--xwhelp"
            $JAVA -cp $XW_CLASSES $MAINCLASS $PARAMS
            ;;
        "console" | "start" | "stop" | "restart" | "status" )
            ACTION=$1
            ;;
	"--xwdownload" )
	    XWDOWNLOAD="--xwdownload"
	    ;;
	"--xwverbose" )
	    XWVERBOSE="--xwverbose"
	    ;;
    "--xwformat" )
        shift
        TMPFMT=$1
        [ "X$TMPFMT" != "X" ] && XWFORMAT="--xwformat $TMPFMT"
        ;;
    "--xwstatus" )
        shift
        TMPSTATUS=$1
        [ "X$TMPSTATUS" != "X" ] && XWSTATUS="--xwstatus $TMPSTATUS"
        ;;
    "--jvmopts" )
        JVMOPTS=1
        ;;
    "--xwconfig" )
        shift
        TMPCFG=$1
        [ "X$TMPCFG" != "X" ] && CFGFILE=" $TMPCFG"            
        CFGDIR=`dirname $CFGFILE`
        ;;
    * )
		echo $1 | grep -E "^-D" > /dev/null 2>&1
		if [ $? -eq 0 ] ; then
			USERJAVAOPTS="$USERJAVAOPTS $1"
		else
           	PARAMS=$PARAMS" "$1
        fi
        ;;
    esac

    shift
    
done




# Feb 17 2009 : we dont use opts
JVMOPTS=0

LOGFILE=$HOME/$PROG-$USER.log
touch $LOGFILE

CFGERR=""

# Config file
if [ ! -f $CFGFILE -a "X$PROG" != "Xxtremweb.ganglia" ] ; then
	CFGERR="`date` [`uname -n` $PROG] ERROR : $CFGFILE not found; looking for a default one"
	echo $CFGERR >> $LOGFILE
    CFGDIR="$HOME/.xtremweb/"
    CFGFILE="$CFGDIR/$PROG.conf"

    if [ ! -w $CFGFILE ] ; then
	echo "`date` [`uname -n` $PROG] ERROR : config file is not writable ($CFGFILE)"  >> $LOGFILE
	return $ERRFILE
    fi
    if [ ! -s $CFGFILE ] ; then
	echo "`date` [`uname -n` $PROG] ERROR : config file is empty ($CFGFILE)" >> $LOGFILE
	return $ERRFILE
    fi
fi

if [ "X$CFGERR" != "X" ] ; then
	echo "$CFGERR (found $CFGFILE)" >> $LOGFILE
fi

HOST=`uname -n`
#
# default
#
SCRATCH=/tmp

#
# Retreive tmp directory from config file
#
grep -El "^tmpdir" $CFGFILE > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    SCRATCH=`grep -i -E "^[[:space:]]*tmpdir" $CFGFILE | head -1 | cut -d '=' -f 2`
fi

LOGFILE=$LOGDIR/$PROG-$HOST.log
[ "X$PROG" = "Xxtremweb.client" ] && LOGFILE=$SCRATCH/$PROG-$USER.log
LOGBAKFILE=$LOGFILE.bak

[ "X$ACTION" = "Xstart" ] && mv -f $LOGFILE $LOGBAKFILE  > /dev/null 2>&1
touch $LOGFILE > /dev/null 2>&1
if [ $? -ne 0 ]; then
    LOGFILE=$SCRATCH/$PROG-$HOST.log
    [ "X$PROG" = "Xxtremweb.client" ] && LOGFILE=$SCRATCH/$PROG-$USER.log
    LOGBAKFILE=$LOGFILE.bak
    touch $LOGFILE > /dev/null 2>&1
    if [ $? -ne 0 ]; then
		echo "`date` [`uname -n` $PROG] WARN : can't create $LOGFILE"
		echo $ERRFILE
    fi
fi

echo "`date` [`uname -n` $PROG] INFO : $ACTION" >> $LOGFILE

#
# test database access
#
if [ "$PROG" = "xtremweb.server" ] ; then

	DB_VENDOR=`grep -i -E "^[[:space:]]*DBVENDOR" $CFGFILE | head -1 | cut -d '=' -f 2`

	if [ "$DB_VENDOR" = "mysql" ] ; then

		DB_NAME=`grep -i -E "^[[:space:]]*DBNAME" $CFGFILE | head -1 | cut -d '=' -f 2`
		DB_USER=`grep -i -E "^[[:space:]]*DBUSER" $CFGFILE | head -1 | cut -d '=' -f 2`
		DB_PASSWD=`grep -i -E "^[[:space:]]*DBPASS" $CFGFILE | head -1 | cut -d '=' -f 2`
		DB_HOST=`grep -i -E "^[[:space:]]*DBHOST" $CFGFILE | head -1 | cut -d '=' -f 2`
	
		MYSQL_PASS=""
	    [ "$DB_PASSWD" = "" ] || MYSQL_PASS="--password=$DB_PASSWD"
		
		MYSQL_HOST=""
	    if [ "$DB_HOST" != "" ] ; then 
			which ping  >> $LOGFILE 2>&1
			if [ $? -eq 0 ] ; then 
				ping -c 1 -t 5 $DB_HOST >> $LOGFILE 2>&1
				if [ $? -ne 0 ] ; then
			    	echo "`date` [`uname -n` $PROG] FATAL: mysql host not reachable" >> $LOGFILE 2>&1
					return $ERRFILE
				fi
			fi 
	    	MYSQL_HOST="-h $DB_HOST"
		fi

		which mysql  >> $LOGFILE 2>&1
		if [ $? -eq 0 ] ; then 
			echo "mysql --connect_timeout=20 -u $DB_USER $MYSQL_PASS $MYSQL_HOST $DB_NAME -e ''" >> $LOGFILE 2>&1
			mysql --connect_timeout=20 -u $DB_USER $MYSQL_PASS $MYSQL_HOST $DB_NAME  -e '' >> $LOGFILE 2>&1
			if [ $? -ne 0 ] ; then
		    	echo "`date` [`uname -n` $PROG] FATAL: mysql config error " >> $LOGFILE 2>&1
				return $ERRFILE
			fi
		else
	    	echo "`date` [`uname -n` $PROG] WARN : mysql client not found" >> $LOGFILE 2>&1
		fi
	fi
fi


# this uniquely names things, if needed
TMPNAME=`date +%Y%m%d%H%M%S`

# next is the name of the created script to execute
SCRIPTTMPFILE="/tmp/$PROG.tmp.sh"



#
# main jar file
#
MAINJAR=""
[ "X$PROG" = "Xxwhep.probe" ] && MAINJAR="XtremWebStatsCollector.jar"


#
# Java available ?
#
#$JAVA -version > /dev/null 2>&1
#[ $? -ne 0 -a -f /etc/java.conf ] && . /etc/java.conf
#$JAVA -version > /dev/null 2>&1
#[ $? -ne 0 -a "$JAVA_HOME" != "" ] && export JAVA=$JAVA_HOME/bin/java

JAVA=`type -p java`
[ $? -ne 0 ] && JAVA=`type java | cut -d " " -f 3`
[ -f /etc/java.conf ] && . /etc/java.conf 
[ "X$JAVA_HOME" != "X" ] && JAVA=$JAVA_HOME/bin/java

#
# Checking Java 6
#
JAVA6=""

ls /usr/java/jre1.6* > /dev/null 2>&1
if [ $? -eq 0 ] ; then
        JAVA6=`ls /usr/java | grep jre1.6 | tail -n 1`
        JAVA="/usr/java/$JAVA6/bin/java"
fi
ls /usr/java/jdk1.6* > /dev/null 2>&1
if [ $? -eq 0 ] ; then
        JAVA6=`ls /usr/java | grep jdk1.6 | tail -n 1`
        JAVA="/usr/java/$JAVA6/bin/java"
fi

#
# java available ?
#
if [ "X$JAVA" = "X" ]; then
    echo "`date` [`uname -n` $PROG] ERROR : can't find JAVA"
    echo "`date` [`uname -n` $PROG] ERROR : can't find JAVA" >> $LOGFILE
    return $ERRFILE
else
    JAVAPATH=`dirname $JAVA`
    JAVAHOME=`dirname $JAVAPATH`
fi



#
# java main class
#
[ "X$PROG" = "Xxtremweb.worker" ] && MAINCLASS="xtremweb.common.HTTPLauncher"
[ "X$PROG" = "Xxtremweb.client" ] && MAINCLASS="xtremweb.client.Client"
[ "X$PROG" = "Xxtremweb.rpc"    ] && MAINCLASS="xtremweb.rpcd.client.Client"
[ "X$PROG" = "Xxtremweb.server" ] && MAINCLASS="xtremweb.dispatcher.Dispatcher"
[ "X$PROG" = "Xxwhep.probe"     ] && MAINCLASS="xtremwebstatscollector.Main"



PIDFILE=""
[ -d /var/run ] && PIDFILE="/var/run/$PROG.pid"

if [ "X$PIDFILE" = "X" ]; then
    [ -d /private/var/run ] && PIDFILE="/private/var/run/$PROG.pid"
fi

if [ "X$PIDFILE" = "X" ]; then
    if [ "X$PROG" != "Xxtremweb.client" ] ; then
	echo "`date` [`uname -n` $PROG] ERROR : can't determine PIDFILE"
	echo "`date` [`uname -n` $PROG] ERROR : can't determine PIDFILE" >> $LOGFILE
	return $ERRFILE
    fi
fi

IBISPIDFILE=`dirname $PIDFILE`/xwhep-ibishub.pid

LOCKFILE=""
if [ -d /var/lock/subsys ] ; then
    LOCKFILE="/var/lock/subsys/$PROG"
    touch $LOCKFILE > /dev/null 2>&1
    [ $? -ne 0 ]  && LOCKFILE=""
fi

if [ "X$LOCKFILE" = "X" ]; then
    [ -d /var/lock ] && LOCKFILE="/var/lock/$PROG"
    touch $LOCKFILE > /dev/null 2>&1
    [ $? -ne 0 ]  && LOCKFILE=""
fi

if [ "X$LOCKFILE" = "X" ]; then
    [ -d /private/var/run ] && LOCKFILE="/private/var/run/$PROG"
    touch $LOCKFILE > /dev/null 2>&1
    [ $? -ne 0 ]  && LOCKFILE=""
fi

if [ "X$LOCKFILE"  = "X" ]; then
    [ -d /tmp ]  && LOCKFILE="/tmp/$PROG"
    touch $LOCKFILE > /dev/null 2>&1
    [ $? -ne 0 ]  && LOCKFILE=""
fi

if [ "X$LOCKFILE" = "X" ]; then
    if [ "X$PROG" != "Xxtremweb.client" ] ; then
	echo "`date` [`uname -n` $PROG] ERROR : can't determine LOCKFILE"
	echo "`date` [`uname -n` $PROG] ERROR : can't determine LOCKFILE" >> $LOGFILE
	return $ERRFILE
    fi
fi


#
# Loggert level
#
DEFAULTLOGGERLEVEL="info"
LOGGERLEVEL=`grep -i -E "^[[:space:]]*loggerlevel" $CFGFILE | cut -d '=' -f2 | sed "s/[[:space:]][[:space:]]*//g" | tr [:upper:] [:lower:]`
[ "X$LOGGERLEVEL" = "X" ] && LOGGERLEVEL=$DEFAULTLOGGERLEVEL

IBISHUBPORT=`grep -i -E "^[[:space:]]*$IBISHUBPORTNAME" $CFGFILE | cut -d '=' -f2 | sed "s/[[:space:]][[:space:]]*//g" | tr [:upper:] [:lower:]`
[ "X$IBISHUBPORT" = "X" ] && IBISHUBPORT=$IBISHUBPORTDEFAULT

IBISHUBADDRESS=`grep -i -E "^[[:space:]]*$IBISHUBADDRESSNAME" $CFGFILE | cut -d '=' -f2 | sed "s/[[:space:]][[:space:]]*//g" | tr [:upper:] [:lower:]`

JAVANETDEBUG=""
#if [ "X$LOGGERLEVEL" = "Xfinest" ]; then
#    JAVANETDEBUG="-Djavax.net.debug=all"
#fi

JETTYDEBUG=""
if [ "X$LOGGERLEVEL" = "Xfinest" ]; then
    JETTYDEBUG="-Dorg.eclipse.jetty.LEVEL=DEBUG"
fi


#
# is there any keystore ?
#
KEYSTORE=`grep -i -E "^[[:space:]]*SSLKeyStore" $CFGFILE | head -1 | cut -d '=' -f2 | sed "s/[[:space:]][[:space:]]*//g"`
JAVATRUSTKEY=""
if [ "X$KEYSTORE" != "X" ]; then
    echo $KEYSTORE |  grep -E "^[[:space:]]*\/" > /dev/null  2>&1
    if [ $? -ne 0 ] ; then
	echo $KEYSTORE |  grep -E "^[[:space:]]*\.\.\/" > /dev/null  2>&1
	if [ $? -eq 0 ] ; then
#
# this is not an absolute path
# this is a relative path from config dir
#
	    KEYSTORE="$CFGDIR/$KEYSTORE"
	fi
    fi
    JAVATRUSTKEY="-Djavax.net.ssl.trustStore=$KEYSTORE"
    if [ ! -s $KEYSTORE ] ; then
	echo "`date` [`uname -n` $PROG] ERROR : $KEYSTORE does not exist or is empty" >> $LOGFILE
	return $ERRFILE
    fi
fi

echo "`date` [`uname -n` $PROG] INFO : JAVATRUSTKEY=$JAVATRUSTKEY" >> $LOGFILE



#
# Set Java options
#

export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:."
export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:."

#JAVAOPTS="$USERJAVAOPTS -Dfile.encoding=UTF-8 -Dxtremweb.cache=$SCRATCH -Djava.library.path=$SCRATCH:$LD_LIBRARY_PATH:$DYLD_LIBRARY_PATH -Dxtremweb.cp=$LIBDIR -server -XX:+HeapDumpOnOutOfMemoryError"
JAVAOPTS="$USERJAVAOPTS -Dfile.encoding=UTF-8 -Dxtremweb.cache=$SCRATCH -Djava.library.path=$SCRATCH:$LD_LIBRARY_PATH:$DYLD_LIBRARY_PATH -Dxtremweb.cp=$LIBDIR -XX:+HeapDumpOnOutOfMemoryError"
# raspberrypi : -server is not a valid option
uname -m | grep armv6
if [ $? -ne 0 ] ; then
  JAVAOPTS="$JAVAOPTS -server"
fi
TMPFILE="/tmp/xtremweb_jvmtest.tmp"
rm -f $TMPFILE

if [ $JVMOPTS -eq 1 ] ; then
    TMPFILE="tmp."$PROG
    rm -f $TMPFILE
    JOPT="-Xdebug"
#    $JAVA $JOPT 2> $TMPFILE 1> /dev/null
    $JAVA $JOPT 2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
    JOPT="-Xms128m"
#    $JAVA $JOPT  2> $TMPFILE 1> /dev/null
    $JAVA $JOPT  2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
    JOPT="-Xmx128m"
#    $JAVA $JOPT  2> $TMPFILE 1> /dev/null
    $JAVA $JOPT  2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
    JOPT="-Xss128m"
#    $JAVA  $JOPT  2> $TMPFILE 1> /dev/null
    $JAVA  $JOPT  2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
    JOPT="-XX:+UseParallelGC"
#    $JAVA $JOPT 2> $TMPFILE 1> /dev/null
    $JAVA $JOPT 2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
    JOPT="-XX:+UseAdaptiveSizePolicy"
#    $JAVA $JOPT 2> $TMPFILE 1> /dev/null
    $JAVA $JOPT 2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
    JOPT="-XX:+UseTLAB"
#    $JAVA $JOPT 2> $TMPFILE 1> /dev/null
    $JAVA $JOPT 2> $TMPFILE
    if [ ! -s $TMPFILE ]; then
        JAVAOPTS=$JAVAOPTS" $JOPT"
    fi
    rm -f $TMPFILE
fi

#
# java CLASSPATH
#
ZIPS=""
JARS=""
RESOURCES=""

ls $LIBDIR/*.zip > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    ZIPS=`ls $LIBDIR/*.zip`
fi
ls $LIBDIR/*.jar > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    JARS=`ls $LIBDIR/*.jar`
fi
ls $RESOURCESDIR/* > /dev/null 2>&1
if [ $? -eq 0 ] ; then
    RESOURCES=`ls $RESOURCESDIR/*`
fi

XW_CLASSES=""
for i in $RESOURCES $ZIPS $JARS ; do
    baseFileName=$(basename $i)
    if [ "X${baseFileName}" = "Xxtremweb.jar" ]; then
        [ -z ${XW_CLASSES} ] && XW_CLASSES="${i}" || XW_CLASSES="${i}:${XW_CLASSES}"
    else
        [ -z ${XW_CLASSES} ] && XW_CLASSES="${i}" || XW_CLASSES="${XW_CLASSES}:${i}"
    fi
done

if [ "X$V_NICE" = "X" ]; then
    CMDNICE=""
else
    CMDNICE="renice $V_NICE -u $XWUSER"
fi



PROFILER=""
PROFCLASS=""
# This is the Extensible Java Profiler agent
# http://ejp.sourceforge.net/
#PROFILER="-Xruntracer"
# Don't forget to set the classpath
#PROFCLASS=/opt/ejp/lib/tracerapi.jar

# This is Yourkit java profiler
# http://www.yourkit.com
#PROFILER="-agentlib:yjpagent"

# agent startup options
# Options are comma separated: -agentlib:yjpagent[=<option>, ...]. 
# e.g. : one may want to change default port value
#PROFILER="-agentlib:yjpagent=port=10001"

# Don't forget to set the classpath
#PROFCLASS=/
#export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/yjp-7.5.7/yjp-7.5.7/bin/linux-x86-32"
#export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:/Applications/YourKit_Java_Profiler_9.5.4.app/bin/mac"


#[ "$PROFILER" != "" ] && JAVAOPTS=""


#
# Sept 10th, 2015: determine machine RAM
# HWMEM is in Gb
#
HWMEM=0

case $OSTYPE in
  
  darwin* )
	HWMEMBYTES=`sysctl -a| grep hw\.mem | cut -d : -f 2`
	HWMEM=$(($HWMEMBYTES/(1024*1024)))
    ;;
  
  linux* )
	HWMEMKILOBYTES=`more /proc/meminfo | grep MemTotal | cut -d : -f 2 | sed "s/kB//g"`
	HWMEM=$(($HWMEMKILOBYTES/1024))
    ;;
  
  * )
    ;;
  
esac

LOG4JCONFIGFILE=$RESOURCESDIR/$LOG4JCONFIGFILENAME
LOG4JOPTS="-Dlog4j.configurationFile"
[ -f $LOG4JCONFIGFILE ] && JAVAOPTS="$JAVAOPTS $LOG4JOPTS=$LOG4JCONFIGFILE"

JAVACMD="$JAVA -DHWMEM=$HWMEM $JAVAOPTS -DLOGFILE=$LOGFILE  $JAVANETDEBUG $JETTYDEBUG $JAVATRUSTKEY $PROFILER -cp $XW_CLASSES:$PROFCLASS:$MAINJAR:"
JAVA="$JAVACMD $MAINCLASS --xwconfig $CFGFILE $XWVERBOSE $XWDOWNLOAD $XWFORMAT $XWSTATUS $PARAMS"
if [ "X$IBISHUBADDRESS" = "X" ] ; then
	IBISHUB="$JAVACMD -Dsmartsockets.hub.port=$IBISHUBPORT $IBISHUBCLASS"
else
	IBISHUB="$JAVACMD -Dsmartsockets.hub.port=$IBISHUBPORT -Dsmartsockets.external.manual=$IBISHUBADDRESS $IBISHUBCLASS"
fi

#
# End Of File
#
