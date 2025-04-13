#!/bin/bash

set -x

LOGFILE=/root/install.log

function start_logging {
  ## Log everything to a empty log file
  [ -e $LOGFILE ] && rm -- $LOGFILE
  touch $LOGFILE
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1> $LOGFILE 2>&1
}
function end_logging {
  # Restore file descriptors
  exec 2>&4 1>&3
}

start_logging
{
# set -e
## Download the test client.
curl  "http://10.0.2.2:3003/test-client" -f -o /root/test-client
chmod 755 /root/test-client

## Download the function yaml and list.
curl  "http://10.0.2.2:3003/functions.yaml" -f -o /root/functions.yaml
curl  "http://10.0.2.2:3003/functions.list" -f -o /root/functions.list


## List all functions can be commented out
FUNCTIONS=$(cat /root/functions.list | sed '/^\s*#/d;/^\s*$/d')

for function_name in $FUNCTIONS
  do
    echo "Pulling function: ${function_name}"
    docker-compose -f /root/functions.yaml pull "${function_name}"
  done

## Catch for failiure ----------
} || {
  echo "\033[0;31m----------------"
  echo "FAIL"
  echo "----------------\033[0m"
  cat /root/results.log
}
# set +e
end_logging

## Upload the log file.
curl  "http://10.0.2.2:3003/upload" -F "files=@${LOGFILE}"

shutdown -h now
