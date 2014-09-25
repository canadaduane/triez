lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordtriez/version'

Gem::Specification.new do |s|
  s.name = "wordtriez"
  s.version = Wordtriez::VERSION
  s.author = ["Zete Lui", "Duane Johnson"]
  s.homepage = "https://github.com/canadaduane/triez"
  s.platform = Gem::Platform::RUBY
  s.summary = "fast, efficient, unicode aware HAT trie with prefix / suffix support"
  s.description = "fast, efficient, unicode aware HAT trie with prefix / suffix support."
  s.required_ruby_version = ">=1.9.2"

  s.files = Dir.glob("{copying,changes,readme.md,{lib,test}/*.rb,ext/*.{c,cc,h,rb},ext/hat-trie/*}")
  s.require_paths = ["lib"]
  s.extensions = ["ext/extconf.rb"]
  s.rubygems_version = '1.8.24'
  s.has_rdoc = false
end
