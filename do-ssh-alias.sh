#!/usr/bin/env bash
set -Eeu
set -o pipefail

# https://stackoverflow.com/a/8574392
elementIn () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# wrap in a sub-shell for json error handling
doctl_get_droplets () {(
    set +e
    droplets=$(doctl compute droplet list -o json)
    errors=$(echo "$droplets" | jq -r 'if type=="object" then .errors[]? | [.detail] | join("\n") else " " end')
    jqStatus=$?

    if [[ $jqStatus -eq 0 && -z "${errors// }" ]]; then
        echo "$droplets"
        return
    fi

    echo "Error fetching Droplets" >&2
    [[ -n "${errors// }" ]] && echo "$errors" >&2
    exit 1
)}

# check for dependencies
{ command -v jq >/dev/null 2>&1; } || { echo "Missing dependency jq: https://stedolan.github.io/jq/download/"; exit 1; }
{ command -v doctl >/dev/null 2>&1; } || { echo "Missing dependency doctl: https://github.com/digitalocean/doctl#installing-doctl"; exit 1; }

# set variables
declare -a ignoredHostnames=()
declare sshUser=""
declare stripSuffix=""

# read arguments
while getopts "i:u:s:" ARG; do
    case "$ARG" in
        i)
            ignoredHostnames+=("$OPTARG")
            ;;

        u)
            sshUser="$OPTARG"
            ;;

        s)
            stripSuffix="$OPTARG"
            ;;

        *)
            break
            ;;
    esac
done

# optional ssh user
if [[ -n "$sshUser" ]]; then
    sshUser="User ${sshUser}"
fi

# get list of droplets
echo Fetching Droplets... >&2
droplets=$(doctl_get_droplets)

# print config
# https://starkandwayne.com/blog/bash-for-loop-over-json-array-using-jq/
echo >&2
for droplet in $(echo "$droplets" | jq -r '.[] | @base64'); do
    _jq() {
        echo "${droplet}" | base64 --decode | jq -r "${1}"
    }

    # extract fields
    hostnames=$(_jq '.name')
    ip=$(_jq '.networks.v4[] | select(.type == "public") | .ip_address')

    echo -n Processing "$hostnames" >&2
    # check if ignored
    if elementIn "$hostnames" "${ignoredHostnames[@]-}"; then
        echo " - ignored" >&2
        continue
    fi

    # strip suffix
    if [[ $stripSuffix != "" &&  $hostnames == *$stripSuffix ]]; then
        hostnames="${hostnames} ${hostnames%$stripSuffix}"
        echo -n " - stripped suffix" >&2
    fi

    echo >&2
    # print config
    cat << CONF
Host $hostnames
    Hostname $ip
    $sshUser

CONF
done
