#!/usr/bin/env bash

# Query EC2 instance tag aws:cloudformation:stack-name value based on instance ID
# With aws:cloudformation:stack-name query ALB DNSName and update DynDNS record for
# ${aws:cloudformation:stack-name}-read-alb-up.ft.com and
# ${aws:cloudformation:stack-name}-write-alb-up.ft.com
# Author: jussi.heinonen@ft.com - 27.1.2017
#
source $(dirname $0)/functions.sh || echo "$(date '+%x %X') $0: Failed to source functions.sh"

usage() {
  echo "USAGE: $0  [--debug=true] [--instance-id=i-0123abc] [--region=aws-region] --dynkey=sercret"
  exit 0
}

[[ "$#" -lt "1" ]] && usage

processCliArgs $*
validateVariables ARGS[--dynkey]

STACKNAME=$(getStackName)
if [[ ${STACKNAME} == '' ]]; then
  errorAndExit "Failed to get stack-name. Exit 1." 1
else
  [[ "${ARGS[--debug]}" ]] &&  info "Stack name is ${STACKNAME}"
fi
