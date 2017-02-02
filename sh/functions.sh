declare -A ARGS
declare -r CURL_CMD="curl -s --connect-timeout 3"

errorAndExit() {
  echo -e "\e[31m$(date '+%x %X') ERROR: $1\e[0m"
  exit $2
}

info() {
  echo -e "\e[34m$(date '+%x %X') INFO: ${1}\e[0m"
}

getInstanceId() {
  ${CURL_CMD} http://169.254.169.254/latest/meta-data/instance-id
}

getRegion() {
  ${CURL_CMD} http://169.254.169.254/latest/meta-data/public-hostname | cut -d '.' -f 2
}

getStackName() {
  if [[ -z "${ARGS[--instance-id]}" ]]; then
    ARGS[--instance-id]=$(getInstanceId)
    [[ "$?" -ne "0"  ]] || errorAndExit "Failed to resolve instance-id. Exit 1." 1
  fi
  if [[ -z "${ARGS[--region]}" ]]; then
    ARGS[--region]=$(getRegion)
    [[ "$?" -ne "0"  ]] || errorAndExit "Failed to resolve region. Exit 1." 1
  fi
  aws ec2 describe-tags --region ${ARGS[--region]} --filters "Name=resource-id,Values=${ARGS[--instance-id]}" --output text | grep aws:cloudformation:stack-name | awk '{print $5}'
  if [[ "$?" -ne "0" ]]; then
    errorAndExit "Failed to get stack name" 1
  fi

}

printCliArgs() {
  for each in "${!ARGS[@]}"
  do
    echo "ARGS[${each}]=${ARGS[${each}]}"
  done
}

processCliArgs() {
  #Reads arguments into associative array ARGS[]
  #Key-Value argument such as --myarg="argvalue" adds an element ARGS[--myarg]="argvalue"
  #
  # USAGE: processCliArgs $*
  for each in $*; do
    if [[ "$(echo ${each} | grep '=' >/dev/null ; echo $?)" == "0" ]]; then
      key=$(echo ${each} | cut -d '=' -f 1)
      value=$(echo ${each} | cut -d '=' -f 2)
      [[ "${ARGS[--debug]}" ]] &&  info "Processing Key-Value argument ${key}=${value}"
      ARGS[${key}]="${value}"
    else
      errorAndExit "Agument must contain = character as in --key=value"
    fi
  done
}

validateVariables() {
  #ARGS: a list of strings that represent variable names
  for each in $@; do
    [[ "${ARGS[--debug]}" ]] &&  info "Validating variable $each"
    if [[ -z ${!each} ]]; then
      errorAndExit "Required variable \$${each} unset"
    fi
  done
}

warn() {
  echo -e "\e[33m$(date '+%x %X') WARNING: ${1}\e[0m"
}
