# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mina_provision/version'

Gem::Specification.new do |spec|
  spec.name          = "mina-provision"
  spec.version       = MinaProvision::VERSION
  spec.authors       = ["Chong-Yee Khoo"]
  spec.email         = ["mail@cykhoo.com"]

  spec.summary       = %q{Tasks to provision servers with mina.}
  spec.description   = %q{Adds tasks to mina to aid in the provision of servers.}
  spec.homepage      = "http://bitbucket.org/cykhoo/mina-provision"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.post_install_message = <<-MESSAGE
You need to add:

    require 'mina_provision/tasks'

in your deploy.rb to use the tasks in this gem
MESSAGE

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_runtime_dependency 'mina'
end
