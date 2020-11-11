#!/bin/sh

config="/network/fabrikka-config.json"
target="/network/target"

if [ "$(id -u)" = 0 ]; then
  echo "Root user detected, running as yeoman user"
  (sudo chown -R yeoman:yeoman "$target" &&
    (cd "$target" && sudo -u yeoman yo --no-insight fabrikka:setup-docker "../..$config") &&
    sudo chown -R root:root "$target")
else
  (cd "$target" && yo --no-insight fabrikka:setup-docker "../..$config")
fi

rm -rf "$target/.cache" "$target/.config"

#
# Additional script and yaml formatting
#
# Why? Yeoman output may contain some additional whitespaces or the formatting
# might not be ideal. Keeping those whitespaces, however, might be useful
# in templates to improve the brevity. That's why we need additional formatting.
# Since the templates should obey good practices, we don't use linters here
# (i.e. shellcheck and yamllint).

echo "Formatting generated files"
shfmt -i=2 -l -w "$target"

for yaml in "$target"/**/*.yaml; do
  # remove trailing spaces
  sed --in-place 's/[ \t]*$//' "$yaml"

  # remove duplicated empty/blank lines
  content="$(awk -v RS= -v ORS='\n\n' '1' "$yaml")"
  echo "$content" >"$yaml"
done
