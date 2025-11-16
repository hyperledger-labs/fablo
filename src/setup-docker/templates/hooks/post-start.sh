#!/usr/bin/env bash

# The code from this file is called after Fablo starts the Hyperledger Fabric network (after 'up' or 'start')
echo "Executing post-start hook"

<%- hooks.postStart %>
