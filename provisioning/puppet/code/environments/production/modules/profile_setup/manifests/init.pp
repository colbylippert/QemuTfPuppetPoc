class profile_setup {
  $home_dirs = $facts['home_directories']

  # Ensure each home directory has a .profile with the specified alias
  $home_dirs.each |$dir| {
    # Ensure the .profile file exists and contains the desired alias
    file { "${dir}/.profile":
      ensure  => file,
      content => "alias ls='ls -al --color=auto'\n",
      owner   => profile_setup::get_owner($dir),
      group   => profile_setup::get_group($dir),
      mode    => '0644',
    }
  }
}
