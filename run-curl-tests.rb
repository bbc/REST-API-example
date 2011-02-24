require 'yaml'
require 'pp'
require 'erb'
require 'systemu'

module ErbBinding
  extend self

  ## create_binding_object
  # create a throw-away object to hold parameters as methods
  def create_binding_object(params)
    o = Object.new
    o.instance_eval do
      klass = class << self; self; end
      # fake
      params.each do |key, value|
        klass.send(:define_method, key) do value end
      end
    end
    def o.context
      self.instance_eval { binding }
    end
    o
  end
  ## erb
  def erb(template, params = { })
    o = create_binding_object(params)
    ERB.new(template, nil, '%<>').result(o.context)
  end
end


$APP_DEBUG = ARGV.delete("--debug")
def dbg(*a)
  STDERR.puts a.pretty_inspect if $APP_DEBUG
end

tests = YAML.load(ARGF.read)
dbg tests

want_org = ARGV.delete("--org")

def indent(txt, level = 4)
  txt.split(/\n/).map{ |line| (" " * level) + line }.join("\n")
end

if want_org
  header = <<EOT
#+BEGIN_HEADER
#+TITLE: curl tests of REST API
#+SETUPFILE: ~/org/setup.org
#+END_HEADER
EOT

  template = <<EOT
** <%= title %>

: <%= url %>

#+BEGIN_SRC sh
<%= cmd %>

#+END_SRC

*** Response
#+BEGIN_EXAMPLE
<%= stdout %>

#+END_EXAMPLE

EOT
else
  # markdown template

  header = <<EOT
# REST API example

The REST API to the example app is described below.

EOT

  template = <<EOT
## <%= title %>

### Request

`<%= url %>`

<%= indent(cmd) %>


### Response

<%= indent(stdout) %>


EOT
end

puts header

tests["tests"].each do |title, url, cmd|
  status, stdout, stderr = systemu(cmd)
  params = {
    :title => title,
    :url => url,
    :cmd => cmd,
    :stdout => stdout,
    :stderr => stderr,
  }

  dbg params
  puts ErbBinding.erb(template, params)
end
