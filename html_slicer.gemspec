# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require "html_slicer/version"

Gem::Specification.new do |s|
  s.name        = "html_slicer"
  s.version     = HtmlSlicer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Valery Kvon"]
  s.email       = ["addagger@gmail.com"]
  s.homepage    = %q{http://vkvon.ru/projects/html_slicer}
  s.summary     = %q{HTML text slicer}
  s.description = %q{HtmlSlicer is a smart way to cut an HTML text into pieces. It also provides on option to resize "width"/"height" attributes of HTML tags, such as <iframe>, <object>, <img> or any other.}
  
  s.add_development_dependency "actionpack", ['>= 3.0.0']

  s.rubyforge_project = "html_slicer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.licenses = ['MIT']
  
end