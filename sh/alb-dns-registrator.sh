#!/usr/bin/env bash
#
# Query EC2 instance tag aws:cloudformation:stack-name value based on instance ID
# With aws:cloudformation:stack-name query ALB DNSName and update DynDNS record for
# ${aws:cloudformation:stack-name}-read-alb-up.ft.com and
# ${aws:cloudformation:stack-name}-write-alb-up.ft.com
# © jussi.heinonen@ft.com - 2.2.2017
#
source $(dirname $0)/functions.sh || echo "$(date '+%x %X') $0: Failed to source functions.sh"

ARGS[--zone]="ft.com"
ARGS[--ttl]="300"
ARGS[--interval]="300"

usage() {
  echo "USAGE: $0  [--debug=true] [--instance-id=i-0123abc] [--region=aws-region] [--zone=ft.com] [--ttl=300] [--interval=300] --dynkey=sercret"
  exit 0
}

[[ "$#" -lt "1" ]] && usage

processCliArgs $*
validateVariables ARGS[--dynkey]

STACKNAME=$(getStackName)
if [[ ${STACKNAME} == '' ]]; then
  errorAndExit "Failed to get stack-name. Exit 1." 1
else
  READALBCNAME="${STACKNAME}-read-alb-up"
  WRITEALBCNAME="${STACKNAME}-write-alb-up"
  if [[ "${ARGS[--debug]}" ]]; then
    info "Stack name: ${STACKNAME}"
    info "Read ALB CNAME: ${READALBCNAME}.${ARGS[--zone]}"
    info "Write ALB CNAME: ${WRITEALBCNAME}.${ARGS[--zone]}"
  fi
fi

while true; do
  READALB=$(getAlbDnsName ${STACKNAME}-read-alb)
  if [[ ${READALB} == '' ]]; then
    errorAndExit "Failed to get DNS name for ${READALBCNAME}. Exit 1." 1
  else
    [[ "${ARGS[--debug]}" ]] &&  info "DNS name for ${READALBCNAME}: ${READALB}"
    cnameCreateOrUpdate ${READALBCNAME} ${ARGS[--zone]} ${READALB} ${ARGS[--ttl]}
  fi

  WRITEALB=$(getAlbDnsName ${STACKNAME}-write-alb)
  if [[ ${WRITEALB} == '' ]]; then
    errorAndExit "Failed to get DNS name for ${WRITEALBCNAME}. Exit 1." 1
  else
    [[ "${ARGS[--debug]}" ]] &&  info "DNS name for ${WRITEALBCNAME}: ${WRITEALB}"
    cnameCreateOrUpdate ${WRITEALBCNAME} ${ARGS[--zone]} ${WRITEALB} ${ARGS[--ttl]}
  fi
  sleep ${ARGS[--interval]}
done
