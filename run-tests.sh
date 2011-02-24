#!/bin/bash
function kill_unicorn() {
  pid=$(ps ax | grep "unicorn master -p 7000" | grep -v grep | awk '{print $1}')
  if [ -n "$pid" ]; then
    kill $pid
  fi
}
kill_unicorn
# Env
export RUBYLIB=$RUBYLIB:$(pwd)
export RACK_ENV=test
export DOCUMENT=curl-tests.org
# Delete old test.db
if [ -e $RACK_ENV.db ]; then
  rm $RACK_ENV.db
fi
# Start unicorn
unicorn -p 7000 &
echo Waiting for unicorn to start up
sleep 3
echo Running tests
ruby run-curl-tests.rb commands.yml | sed -r 's/\x0D//g' > $DOCUMENT
kill_unicorn
# less curl-tests.org
echo Generating HTML output
emacs -q --batch --visit=$DOCUMENT --funcall org-export-as-html-batch &> /dev/null
gnome-open curl-tests.html
