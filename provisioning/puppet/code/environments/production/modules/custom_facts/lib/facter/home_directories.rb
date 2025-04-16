#!/opt/puppetlabs/puppet/bin/ruby
require 'facter'

Facter.add('home_directories') do
  setcode do
    dirs = Dir['/home/*'].select { |entry| File.directory?(entry) && entry != '/home/lost+found' }
    dirs
  end
end
