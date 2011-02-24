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

*** Output
#+BEGIN_EXAMPLE
<%= stdout %>

#+END_EXAMPLE

EOT

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
