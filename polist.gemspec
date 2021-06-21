# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "polist/version"

Gem::Specification.new do |spec|
  spec.required_ruby_version = ">= 2.7.0"

  spec.name = "polist"
  spec.version = Polist::VERSION
  spec.authors = ["Yuri Smirnov"]
  spec.email = ["tycooon@yandex.ru", "oss@umbrellio.biz"]

  spec.summary = "A gem for creating simple service classes and more."
  spec.description = "Polist is a gem for creating simple service classes and more."
  spec.homepage = "https://github.com/umbrellio/polist"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^spec/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activemodel", ">= 3.0"
  spec.add_runtime_dependency "plissken", ">= 0.3"
  spec.add_runtime_dependency "tainbox"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-config-umbrellio"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
end
