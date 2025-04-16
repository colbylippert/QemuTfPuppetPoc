Puppet::Functions.create_function(:'profile_setup::get_group') do
  dispatch :get_group do
    param 'String', :dir
    return_type 'String'
  end

  def get_group(dir)
    require 'etc'
    Etc.getgrgid(File.stat(dir).gid).name
  end
end
