#!/bin/bash
##############################################
#
#	  PURPOSE: The script to predict expiring SSL certificates.
#
# 	AUTHOR: 'Abhishek.Tamrakar'
#
# 	VERSION: 1.0.0
#
# 	EMAIL: abhishek.tamrakar08@gmail.com
#
# 	GENERATED: on 2018-05-20
#
#	  LICENSE: Copyright (C) 2018 Abhishek Tamrakar
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
##############################################

#your Variables go here
SCRIPT=${0##/}
EXITCODE=''
WRITEFORMAT=table
CONFIG=0
DIR=0
LOGLEVEL=info
EXT=crt
# functions here
usage()
{
cat <<EOF

  USAGE: $SCRIPT -[cdewh]"

  DESCRIPTION: This script predicts the expiring SSL certificates based on the end date.

  OPTIONS:

  -c|   sets the value for configuration file which has server:port or host:port details.

  -d|   sets the value of directory containing the certificate files in crt or pem format.

  -e|   sets the value of certificate extention [crt, pem, cert], default: crt

  -w|   sets the value for output format of the script [table, csv, json, yaml], default: table

  -l|   sets the log level [info, debug, error, warn], default: info

  -h|   prints this help and exit.

EOF
exit 1
}

error()
{
  printf '\n%s: %6s\n' "ERROR" "$@"
  exit 1
}

warn()
{
  printf '\n%s: %6s\n' "WARN" "$@"
}

log()
{
  local LEVEL=$LOGLEVEL
  local SEVERITY=$1
  local MESSAGE=$2
  if [[ "${LEVEL}" = "${SEVERITY}" ]]; then
  # check if loglevel is same as severity or one of the valid log levels.
    case $SEVERITY in
      info|debug ) printf '\n%s: %6s\n' "${SEVERITY}" "$MESSAGE";;
      * ) error "invalid log level $LOGLEVEL";;
    esac
  fi
}

getExpiry()
{
  local EXPDATE=$1
  local CERTNAME=$2
  TODAY=$(date +%s)
  TIMETOEXPIRE=$(( ($EXPDATE - $TODAY)/(60*60*24) ))
  log debug "${CERTNAME}.${EXT} will expire in ${TIMETOEXPIRE} days"

  EXPCERTS=( ${EXPCERTS[@]} "${CERTNAME}:$TIMETOEXPIRE" )
  log debug "Expiring certificates ${EXPCERTS[@]}"
}

printCSV()
{
  local ARGS=$#
  i=0
  if [[ $ARGS -ne 0 ]]; then
    #statements
    printf '%s,%s,%s\n' "serial" "name" "expiry"
    printf '%s\n' "$@"  | \
      sort -t':' -g -k2 | \
      awk -F: '{printf "%d,%s,%s\n", NR, $1, $2}'
  fi
}

printTable()
{
  local ARGS=$#
  i=0
  if [[ $ARGS -ne 0 ]]; then
    #statements
    printf '%s\n' "---------------------------------------------"
    printf '%s\n' "List of expiring SSL certificates"
    printf '%s\n' "---------------------------------------------"
    printf '%s\n' "$@"  | \
      sort -t':' -g -k2 | \
      column -s: -t     | \
      awk '{printf "%d.\t%s\n", NR, $0}'
    printf '%s\n' "---------------------------------------------"
  fi
}

printJSON()
{
  local ARGS="$#"
  local DATA="$@"
  if [[ $ARGS -ne 0 ]]; then
    count=1
    printf '%s' "{ \"items\": [ "
      for VALUE in ${DATA}; do
        printf '%s' "{ \"${VALUE%%:*}\": { \"days\": \"${VALUE##*:}\" } }, "
      done| sed -r 's/(.*), /\1/'
    printf '%s' " ] }"
  fi
}

calcEndDate()
{
  sslcmd=$(which openssl)
  if [[ x$sslcmd = x ]]; then
    #statements
    error "$sslcmd command not found!"
  fi
  # when cert dir is given
  if [[ $DIR -eq 1 ]]; then
    #statements
    checkcertexists=$(ls -A $TARGETDIR| egrep "*.$EXT$")
    if [[ -z ${checkcertexists} ]]; then
      #statements
      error "no certificate files at $TARGETDIR with extention $EXT"
    fi
    for FILE in $TARGETDIR/*.${EXT}
    do
      log debug "Scanning certificate ${FILE}"
      EXPDATE=$($sslcmd x509 -in $FILE -noout -enddate)
      log debug "Certificate ${FILE} expires on ${EXPDATE}"
      EXPEPOCH=$(date -d "${EXPDATE##*=}" +%s)
      CERTIFICATENAME=${FILE##*/}
      getExpiry $EXPEPOCH ${CERTIFICATENAME%%.*}
    done
  elif [[ $CONFIG -eq 1 ]]; then
    #statements
    while read LINE
    do
      log debug "Scanning certificate for ${LINE}"
      if echo "$LINE" | \
      egrep -q '^[a-zA-Z0-9.]+:[0-9]+|^[a-zA-Z0-9]+_.*:[0-9]+';
      then
        EXPDATE=$(echo | \
        openssl s_client -connect $LINE 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null);
        if [[ $EXPDATE = '' ]]; then
          #statements
          warn "[error:0906D06C] Cannot fetch certificates for $LINE"
        else
          log debug "Certificate ${LINE} expires on ${EXPDATE}"
          EXPEPOCH=$(date -d "${EXPDATE##*=}" +%s);
          CERTIFICATENAME=${LINE%%:*};
          getExpiry $EXPEPOCH ${CERTIFICATENAME};
        fi
      else
        warn "[format error] $LINE is not in required format!"
      fi
    done < $CONFIGFILE
  fi
}
# your script goes here
while getopts ":c:d:w:e:h" OPTIONS
do
case $OPTIONS in
c )
  CONFIG=1
  CONFIGFILE="$OPTARG"
  if [[ ! -e $CONFIGFILE ]] || [[ ! -s $CONFIGFILE ]]; then
    #statements
    error "$CONFIGFILE does not exist or empty!"
  fi
	;;
e )
  EXT="$OPTARG"
  case $EXT in
    crt|pem|cert )
    log info "Extention check complete."
    ;;
    * )
    error "invalid certificate extention $EXT!"
    ;;
  esac
  ;;
d )
  DIR=1
  TARGETDIR="$OPTARG"
  [ $TARGETDIR = '' ] && error "$TARGETDIR empty variable!"
  ;;
w )
  WRITEFORMAT="$OPTARG"
  ;;
l )
  LOGLEVEL="$OPTARG"
  ;;
h )
	usage
	;;
\? )
	usage
	;;
: )
	fatal "Argument required !!! see \'-h\' for help"
	;;
esac
done
shift $(($OPTIND - 1))
#
calcEndDate
#finally print the list
case $WRITEFORMAT in
  table ) printTable ${EXPCERTS[@]};;
  json ) printJSON ${EXPCERTS[@]};;
  yaml ) printTable ${EXPCERTS[@]};;
  csv ) printCSV ${EXPCERTS[@]};;
  * ) error "invalid format $WRITEFORMAT";;
esac
