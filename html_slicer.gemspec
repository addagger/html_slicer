# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "html_slicer/version"

Gem::Specification.new do |s|
  s.name        = "html_slicer"
  s.version     = HtmlSlicer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Valery Kvon"]
  s.email       = ["addagger@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{HTML text slicer}
  s.description = %q{A "smart" way to slice HTMLsed text to pages, also it can optionally resize included "width/height" attributes of HTML tags like <iframe>, <object>, <img> etc.}
  
  s.add_development_dependency "actionpack", ['>= 3.0.0']

  s.rubyforge_project = "html_slicer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.licenses = ['MIT']
  
end