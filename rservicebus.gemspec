Gem::Specification.new do |s|
  s.name        = 'rservicebus'
  s.version     = '0.0.43'
  s.date        = '2013-03-09'
  s.summary     = "RServiceBus"
  s.description = "A Ruby interpretation of NServiceBus"
  s.authors     = ["Guy Irvine"]
  s.email       = 'guy@guyirvine.com'
  s.files       = Dir["{lib}/**/*.rb", "bin/*", "LICENSE", "*.md"]
  s.homepage    = 'http://rubygems.org/gems/rservicebus'
  s.executables << 'rservicebus'
  s.executables << 'rservicebus-init'
  s.executables << 'ReturnErroredMessagesToSourceQueue'
  s.executables << 'ReturnErroredMessagesToSourceQueueBeanstalk'
  s.executables << 'ReturnErroredMessagesToSourceQueueBunny'
  s.executables << 'SendEmptyMessage'
end
