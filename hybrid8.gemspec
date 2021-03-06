# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'h8/version'
require "rake/extensiontask"
require 'rubygems/package_task'

spec = Gem::Specification.new do |spec|
  spec.name          = "h8"
  spec.version       = H8::VERSION
  spec.authors       = ["sergeych"]
  spec.email         = ["real.sergeych@gmail.com"]
  spec.summary       = %q{Minimalistic and sane v8 bindings}
  spec.description   = %q{Should be more or less replacement for broken therubyracer gem and ruby 2.1+ }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib', 'ext']

  spec.extensions = FileList["ext/**/extconf.rb"]

  spec.platform = Gem::Platform::RUBY

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "rspec", '>= 2.14.0'

  # spec.add_dependency 'libv8'
end

Gem::PackageTask.new(spec) do |pkg|
end

Rake::ExtensionTask.new "h8", spec do |ext|
  ext.lib_dir  = "lib/h8"
  ext.source_pattern = "*.{c,cpp}"
  ext.gem_spec = spec
end

spec

