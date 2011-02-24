#!/bin/bash
function kill_unicorn() {
  pid=$(ps ax | grep "unicorn master -p 7000" | grep -v grep | awk '{print $1}')
  if [ -n "$pid" ]; then
    kill $pid
  fi
}
if [ "$1" = "org" ]; then
  WANT_ORG_OUTPUT="--org"
fi

kill_unicorn
# Env
export RUBYLIB=$RUBYLIB:$(pwd)
export RACK_ENV=test
export DOCUMENT=curl-tests

if [ -n "$WANT_ORG_OUTPUT" ]; then
  export EXT=.org
else
  export EXT=.md
fi

# Start unicorn
unicorn -p 7000 &
echo Waiting for unicorn to start up && sleep 3
ruby run-curl-tests.rb $WANT_ORG_OUTPUT commands.yml | sed -r 's/\x0D//g' > ${DOCUMENT}${EXT}
kill_unicorn

# format using org-mode if requested
if [ -n "$WANT_ORG_OUTPUT" ]; then
  echo Generating HTML output
  emacs -q --batch --visit=${DOCUMENT}${EXT} --funcall org-export-as-html-batch &> /dev/null
  gnome-open ${DOCUMENT}.html
fi

