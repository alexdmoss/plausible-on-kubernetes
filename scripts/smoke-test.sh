#!/usr/bin/env bash
set -euoE pipefail

DOMAIN=visits.alexos.dev
export DOMAIN

function main() {

  local error=0

  _assert_variables_set DOMAIN

  _console_msg "Running smoke tests for https://${DOMAIN}/ ..."
  
  _smoke_test "${DOMAIN}" https://"${DOMAIN}"/login "Enter your account credentials" "Login Page" "200"
  _smoke_test "${DOMAIN}" https://"${DOMAIN}"/js/plausible.outbound-links.js "addEventListener" "Tag Script" "200"
  _smoke_test "${DOMAIN}" https://"${DOMAIN}"/js/script.file-downloads.hash.outbound-links.pageview-props.tagged-events.js "addEventListener" "Tag Script Full" "200"

  if [[ "${error:-}" != "0" ]]; then
      _console_msg "Tests FAILED - see messages above for for detail" ERROR
      exit 1
  else
      _console_msg "All tests passed!"
  fi

}

function _smoke_test() {

    local domain=$1
    local url=$2
    local match=$3
    local description=$4
    local expected_rc=$5

    output=$(curl -H "Host: ${domain}" -s -k -L -w "\n%{http_code}" "${url}" || true)
    actual_rc=$(echo "${output}" | tail -n1)

    if [[ "${actual_rc}" != "${expected_rc}" ]]; then
        _console_msg "Test FAILED - $description : ${url} - return code not correct (expected ${expected_rc}, received ${actual_rc}" ERROR
        error=1
    fi

    if [[ $(echo "${output}" | grep -c "${match}") -eq 0 ]]; then 
        _console_msg "Test FAILED - ${description} ::: ${url} - missing phrase (expected ${match})" ERROR
        error=1
    else
        _console_msg "Test PASSED - ${description} ::: ${url}" INFO
    fi

}



function _assert_variables_set() {
  local error=0
  local varname
  for varname in "$@"; do
    if [[ -z "${!varname-}" ]]; then
      echo "${varname} must be set" >&2
      error=1
    fi
  done
  if [[ ${error} = 1 ]]; then
    exit 1
  fi
}

function _console_msg() {
  local msg=${1}
  local level=${2:-}
  local ts=${3:-}
  if [[ -z ${level} ]]; then level=INFO; fi
  if [[ -n ${ts} ]]; then ts=" [$(date +"%Y-%m-%d %H:%M")]"; fi

  echo ""
  if [[ ${level} == "ERROR" ]] || [[ ${level} == "CRIT" ]] || [[ ${level} == "FATAL" ]]; then
    (echo 2>&1)
    (echo >&2 "-> [${level}]${ts} ${msg}")
  else 
    (echo "-> [${level}]${ts} ${msg}")
  fi
}

main "$@"
