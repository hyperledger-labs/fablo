#!/usr/bin/bash

retry()
{
        local n=0
        local try=$1
        local cmd="${@: 2}"
        [[ $# -le 1 ]] 

        until [[ $n -ge $try ]]
        do
            $cmd && break || {
            echo $(printf '\033[31m') "Previous command FAILED"
            ((n++))
            echo $(printf '\033[34m') "RETRYING..."
            sleep 1;
        }

        done
}
retry $*