# setup deploying rutines
BlackStack::Deployer::add_routine({
  :name => 'install-webserver',
  :commands => [{
    :command => '
      # remove old code folder
      rmdir -rf ~/code/connectionsphere/app >>~/connectionsphere.app.output 2>&1

      # create code folder
      mkdir -p ~/code/connectionsphere >>~/connectionsphere.app.output 2>&1
      mkdir -p ~/code/connectionsphere >>~/connectionsphere.app.output 2>&1

      # clone the project
      git clone https://%git_username%:%git_password%@github.com/connectionsphere/app ~/code/connectionsphere >>~/connectionsphere.app.output 2>&1

      # pull the last version of the source code
      cd ~/code/connectionsphere
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/%git_branch% >>~/connectionsphere.app.output 2>&1

      # pull the last version of the source code
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/%git_branch% >>~/connectionsphere.app.output 2>&1

      # update extension i2p
      cd ~/code/connectionsphere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/i2p ~/code/connectionsphere/extensions/i2p >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionsphere/extensions/i2p >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/master >>~/connectionsphere.app.output 2>&1

      # update extension monitoring
      cd ~/code/connectionsphere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/monitoring ~/code/connectionsphere/extensions/monitoring >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionsphere/extensions/monitoring >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension content
      cd ~/code/connectionsphere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/content ~/code/connectionsphere/extensions/content >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionsphere/extensions/content >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension selectrowsjs
      cd ~/code/connectionsphere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/selectrowsjs ~/code/connectionsphere/extensions/selectrowsjs >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionsphere/extensions/selectrowsjs >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension filtersjs
      cd ~/code/connectionsphere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/filtersjs ~/code/connectionsphere/extensions/filtersjs >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionsphere/extensions/filtersjs >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension templatesjs
      cd ~/code/connectionsphere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/templatesjs ~/code/connectionsphere/extensions/templatesjs >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionsphere/extensions/templatesjs >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # upload configuration file
      cd ~/code/connectionsphere >>~/connectionsphere.app.output 2>&1
      [ -f ./config.rb ] && mv ./config.rb ./config.%timestamp%.rb >>~/connectionsphere.app.output 2>&1
      echo "%config_rb_content%" > ./config.rb

      # update gems
      #cd ~/code/connectionsphere >>~/connectionsphere.app.output 2>&1
      #bundler update >>~/connectionsphere.app.output 2>&1
    ',
  }],
});