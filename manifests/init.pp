class rvm($version=undef, $install_rvm=true, $proxy=undef) {
  stage { 'rvm-install': before => Stage['main'] }

  if $install_rvm {
    if $proxy {
      class {
        'rvm::dependencies': stage => 'rvm-install';
        'rvm::system':       stage => 'rvm-install', version => $version, proxy => $proxy;
      } 
    } else {
      class {
        'rvm::dependencies': stage => 'rvm-install';
        'rvm::system':       stage => 'rvm-install', version => $version;
      }
    }
  }
}
