#!/bin/bash
##############################################
#
#	  PURPOSE: The script to predict expiring SSL certificates.
#
# 	AUTHOR: 'Abhishek.Tamrakar'
#
# 	VERSION: 0.0.1
#
# 	COMPANY: Self
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
script=${0##/}
exitcode=''
# functions here
usage()
{
cat <<EOF

  USAGE: $script -[cdewh]"

  DESCRIPTION: This script predicts the expiring SSL certificates based on the end date.

  OPTIONS:

  -c|   sets the value for configuration file which has server:port or host:port details.

  -d|   sets the value of directory containing the certificate files in crt or pem format.

  -e|   sets the value of certificate extention, e.g crt, pem, cert.
        crt: default

  -w|   sets the value for writing the script output to a file.

  -h|   prints this help and exit.

EOF
exit 1
}

info()
{
  printf '\n%s: %6s\n' "INFO" "$@"
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

getExpiry()
{
  local expdate=$1
  local certname=$2
  today=$(date +%s)
  timetoexpire=$(( ($today - $expdate)/(60*60*24) ))
  timetoexpire=${timetoexpire##*-}

  case $timetoexpire in
    0 )
    expday0=( ${expday0[@]} "${certname}:$timetoexpire" )
    ;;
    [2-10] )
    expday10=( ${expday10[@]} "${certname}:$timetoexpire" )
    ;;
    1[1-9]|2[0-9] )
    expday30=( ${expday30[@]} "${certname}:$timetoexpire" )
    ;;
    3[1-9]|4[0-9]|5[1-9] )
    expday60=( ${expday60[@]} "${certname}:$timetoexpire" )
    ;;
    6[0-9]|7[1-9]|8[0-9]|9[1-9] )
    expday90=( ${expday90[@]} "${certname}:$timetoexpire" )
    ;;
    * )
    expday300=( ${expday300[@]} "${certname}:$timetoexpire" )
    ;;
  esac
}

printExpiry()
{
  local args=$#
  i=0
  if [[ $args -ne 0 ]]; then
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
    for file in $TARGETDIR/*.${EXT:-crt}
    do
      expdate=$($sslcmd x509 -in $file -noout -enddate)
      expepoch=$(date -d "${expdate##*=}" +%s)
      certificatename=${file##*/}
      getExpiry $expepoch ${certificatename%%.*}
    done
  elif [[ $CONFIG -eq 1 ]]; then
    #statements
    while read line
    do
      if echo "$line" | \
      egrep -q '^[a-zA-Z0-9.]+:[0-9]+|^[a-zA-Z0-9]+_.*:[0-9]+';
      then
        expdate=$(echo | \
        openssl s_client -connect $line 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null);
        if [[ $expdate = '' ]]; then
          #statements
          warn "[error:0906D06C] Cannot fetch certificates for $line"
        else
          expepoch=$(date -d "${expdate##*=}" +%s);
          certificatename=${line%%:*};
          getExpiry $expepoch ${certificatename};
        fi
      else
        warn "[format error] $line is not in required format!"
      fi
    done < $CONFIGFILE
  fi
}
# your script goes here
while getopts ":c:d:w:e:h" options
do
case $options in
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
    info "Extention check complete."
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
  WRITEFILE=1
  OUTFILE="$OPTARG"
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
if [[ $WRITEFILE -eq 0 ]]; then
  #statements
  printExpiry ${expday0[@]} ${expday10[@]} ${expday30[@]} \
  ${expday60[@]} ${expday90[@]} ${expday300[@]}
else
  printExpiry ${expday0[@]} ${expday10[@]} ${expday30[@]} \
  ${expday60[@]} ${expday90[@]} ${expday300[@]} > $OUTFILE
fi
