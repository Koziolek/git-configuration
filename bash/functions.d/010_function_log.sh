#!/usr/bin/env bash

# Log a message with specified log level and color formatting
# Usage: log_message <level> <message...>
#
# Parameters:
#   level    - Log level (debug|info|warn|error|man). Determines message prefix and color
#   message  - One or more message strings to output
#
# Example:
#   log_message "info" "Starting process" "with parameters"
function log_message() {
  local level="$1"
  shift
  local messages=("$@")

  if [ -z "$level" ] || [ -z "$messages" ]; then
    echo "${C_RED}NOTHING TO LOG${C_NC}: Empty log call at ${FUNCNAME[*]}"
  fi

  local prefix=""
  case "$level" in
  "debug")
    prefix="${C_BLUE}${level^^}: ${C_NC}"
    ;;
  "info")
    prefix="${C_GREEN}${level^^}: ${C_NC}"
    ;;
  "warn")
    prefix="${C_ORANGE}${level^^}: ${C_NC}"
    ;;
  "error")
    prefix="${C_RED}${level^^}: ${C_NC}"
    ;;
  "man")
    prefix="${C_NC}"
    ;;
  *)
    prefix="${C_NC}${level^^} "
    ;;
  esac
  echo -e "${prefix}${messages[*]}${C_NC}"
}

function log_debug() {
  log_message "debug" "$@"
}

function log_info() {
  log_message "info" "$@"
}

function log_warn() {
  log_message "warn" "$@"
}
function log_error() {
  log_message "error" "$@"
  print_stack_trace
}

function log_man() {
  log_message "man" "$@"
}

function print_stack_trace() {
    local frame=0
    echo "Stack trace:"
    while [[ ${FUNCNAME[frame]} ]]; do
        echo "  ${frame}: ${FUNCNAME[frame]}() in ${BASH_SOURCE[frame]}:${BASH_LINENO[frame-1]}"
        ((frame++))
    done
}

export -f log_message
export -f log_debug
export -f log_info
export -f log_warn
export -f log_error
export -f log_man
export -f print_stack_trace
