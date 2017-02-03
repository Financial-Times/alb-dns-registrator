declare -A ARGS
declare -r CURL_CMD="curl -s --connect-timeout 3"

cnameCreateOrUpdate() {
  RECORD="${1}"
  ZONE="${2}"
  FQDN="${1}.${2}"
  ALBDNS="${3}"
  TTL="${4}"

  if [[ "$(cnameExist ${FQDN})" ]]; then
    if [[ "$(cnameUpToDate ${FQDN} ${ALBDNS})" ]]; then
      info "Cname ${FQDN} is up to date"
    else
      info "Cname ${FQDN} requires update"
      deleteCname ${ZONE} ${RECORD}
      createCname ${ZONE} ${RECORD} ${ALBDNS} ${TTL}
    fi
  else
    warn "CNAME ${FQDN} does not exist. Creating CNAME."
    createCname ${ZONE} ${RECORD} ${ALBDNS} ${TTL}
  fi
}

cnameExist() {
  #ARG1: cname to lookup
  #returns: true if cname exists
  host -t cname $1 &>/dev/null && echo "true"

}

cnameUpToDate() {
  host -t cname $1 | grep -o $2 && echo "true"
}

createCname() {
  info "Creating record zone: $1, name: $2, record: $3, ttl: $4"
  python $(dirname $0)/../python/create-dns -z $1 -n $2 -r $3 -t $4 -k ${ARGS[--dynkey]} || errorAndExit "Failed to create CNAME for $2.$1 Exit 1." 1
}

deleteCname() {
  python $(dirname $0)/../python/delete-dns -z $1 -n $2 -k ${ARGS[--dynkey]} || errorAndExit "Failed to delete CNAME for $2.$1 Exit 1." 1
}

errorAndExit() {
  echo -e "\e[31m$(date '+%x %X') ERROR: $1\e[0m"
  exit $2
}

info() {
  echo -e "\e[34m$(date '+%x %X') INFO: ${1}\e[0m"
}

getAlbDnsName() {
  #ARG1: name of the ALB to LOOKUP
  #returns: ALB DNS name
  if [[ -z $1 ]]; then
    errorAndExit "${FUNCNAME}: ALB name must be provided. Exit 1." 1
  else
    aws elbv2 describe-load-balancers --region ${ARGS[--region]} --name $1 --query="LoadBalancers[].DNSName" --output text
  fi
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
      if [[ "${ARGS[--debug]}" ]]; then
        if [[ "${key}" == "--dynkey" ]]; then
          info "Processing Key-Value argument ${key}=${value:0:4}********************"
        else
          info "Processing Key-Value argument ${key}=${value}"
        fi
      fi
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
