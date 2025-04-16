Puppet::Functions.create_function(:'profile_setup::get_owner') do
  dispatch :get_owner do
    param 'String', :dir
    return_type 'String'
  end

  def get_owner(dir)
    require 'etc'
    Etc.getpwuid(File.stat(dir).uid).name
  end
end
