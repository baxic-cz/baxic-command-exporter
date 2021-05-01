#!/bin/bash

PROGNAME='baxic-command-exporter.sh'

CONFFILE="/opt/prometheus-apps/${PROGNAME%.sh}/${PROGNAME%.sh}.conf"

export PROGNAME CONFFILE


# read_config_file
#   read configuration file
read_config_file() {

  unset COMMAND

  if [[ ! -f "$CONFFILE" || ! -r "$CONFFILE" ]]; then
    echo "$PROGNAME: configuration file '$CONFFILE' not found"
    exit 2
  fi

  . "$CONFFILE"

}

read_config_file


# get_metrics
#   get all metrics, i.e. run all commands
get_metrics() {

  local httpget

  local commconf metric comm value
  local metrics metrics_len

  read httpget

  metrics="$(for commconf in "${COMMAND[@]}"; do

    metric="$(echo "$commconf" | cut -d: -f1)"
    comm="$(echo "$commconf" | cut -d: -f2-)"

    value="$(bash -c "$comm" | head -1)"

    echo "$value" | grep -Eq '^[[:digit:]]+$' || continue
    [[ "${value:0:1}" = '0' && "$value" != '0' ]] && continue
    echo "$metric" "$value"

  done)"

  metrics_len="$(echo "$metrics" | wc -c)"

  echo 'HTTP/1.1 200 OK'
  echo "Content-Length: $metrics_len"
  echo 'Content-Type: text/plain'
  echo "Date: $(date -R -u | sed -r 's#\+0000$#GMT#')"
  echo
  echo "$metrics"

  return 0

}


export -f get_metrics
export -f read_config_file


# periodically return metrics when requested
ncat -k -l 9088 -c 'read_config_file && get_metrics'


# exit
exit 0

