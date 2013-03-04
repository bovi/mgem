Gem::Specification.new do |s|
  s.name        = 'mgem'
  s.version     = '0.1.7'
  s.summary     = 'A program to manage GEMs for mruby.'
  s.description = 'mgem helps you search and find GEMs specifically written for mruby. It also supports by creating a mruby build configuration.'
  s.author      = 'Daniel Bovensiepen'
  s.email       = 'daniel@bovensiepen.net'
  s.files       = ['bin/mgem', 'lib/mgem.rb']
  s.bindir      = 'bin'
  s.executables << 'mgem'
  s.homepage    = 'http://github.com/bovi/mgem'
  s.license     = 'MIT'
end
