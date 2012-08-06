Gem::Specification.new do |s|
  s.name        = 'rservicebus'
  s.version     = '0.0.13'
  s.date        = '2012-08-06'
  s.summary     = "RServiceBus"
  s.description = "A Ruby interpretation of NServiceBus"
  s.authors     = ["Guy Irvine"]
  s.email       = 'guy@guyirvine.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.homepage    = 'http://rubygems.org/gems/rservicebus'
  s.executables << 'rservicebus'
  s.executables << 'ReturnErroredMessagesToSourceQueue'
end
