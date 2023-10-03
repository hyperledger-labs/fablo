#!/usr/bin/env bash

set -eu

target_dir="$1"

(cd "$target_dir" && curl -L https://istio.io/downloadIstio | sh -)

path_change="export PATH=\"\$PATH:$target_dir/$(cd "$target_dir" && find istio-* | head -n 1)/bin\""

echo "Istio is installed in $target_dir."
echo "Please add the following line to your .bashrc or .zshrc:"
echo "$path_change"
echo "and then run: 'source ~/.bashrc' or 'source ~/.zshrc'"