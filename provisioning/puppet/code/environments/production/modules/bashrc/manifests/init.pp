class profile_setup {
  $home_dirs = $facts['home_directories']

  # Ensure each home directory has a .profile with the specified alias
  $home_dirs.each |$dir| {
    # Ensure the .profile file exists and contains the desired alias
    file { "${dir}/.profile":
      ensure  => file,
      content => "alias ls='ls -al'\n",
      owner   => get_owner($dir),
      group   => get_group($dir),
      mode    => '0644',
    }
  }
}

# Function to determine the owner of a directory
function profile_setup::get_owner(String $dir) {
  return $facts['home_directories_owners'][$dir]
}

# Function to determine the group of a directory
function profile_setup::get_group(String $dir) {
  return $facts['home_directories_groups'][$dir]
}
