#!/bin/sh

# Adjust path to lib_msg.sh as necessary
# shellcheck source=./lib_msg.sh
. "./lib_msg.sh"

# Your script logic here
msg "Script started."
info "Here's some information."
warn "Something to be cautious about."
err "An error occurred (but not fatal)."
die 1 "A fatal error occurred, exiting."