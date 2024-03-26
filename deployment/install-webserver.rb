# setup deploying rutines
BlackStack::Deployer::add_routine({
  :name => 'install-webserver',
  :commands => [{
    :command => '
      # remove old code folder
      rmdir -rf ~/code/connectionshere/app >>~/connectionsphere.app.output 2>&1

      # create code folder
      mkdir -p ~/code/connectionshere >>~/connectionsphere.app.output 2>&1
      mkdir -p ~/code/connectionshere >>~/connectionsphere.app.output 2>&1

      # clone the project
      git clone https://%git_username%:%git_password%@github.com/connectionsphere/app ~/code/connectionshere >>~/connectionsphere.app.output 2>&1

      # pull the last version of the source code
      cd ~/code/connectionshere
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/%git_branch% >>~/connectionsphere.app.output 2>&1

      # pull the last version of the source code
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/%git_branch% >>~/connectionsphere.app.output 2>&1

      # update extension i2p
      cd ~/code/connectionshere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/i2p ~/code/connectionshere/extensions/i2p >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionshere/extensions/i2p >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/master >>~/connectionsphere.app.output 2>&1

      # update extension monitoring
      cd ~/code/connectionshere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/monitoring ~/code/connectionshere/extensions/monitoring >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionshere/extensions/monitoring >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension content
      cd ~/code/connectionshere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/content ~/code/connectionshere/extensions/content >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionshere/extensions/content >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension selectrowsjs
      cd ~/code/connectionshere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/selectrowsjs ~/code/connectionshere/extensions/selectrowsjs >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionshere/extensions/selectrowsjs >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension filtersjs
      cd ~/code/connectionshere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/filtersjs ~/code/connectionshere/extensions/filtersjs >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionshere/extensions/filtersjs >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # update extension templatesjs
      cd ~/code/connectionshere/extensions >>~/connectionsphere.app.output 2>&1
      git clone https://github.com/leandrosardi/templatesjs ~/code/connectionshere/extensions/templatesjs >>~/connectionsphere.app.output 2>&1
      git config --global credential.helper store >>~/connectionsphere.app.output 2>&1
      cd ~/code/connectionshere/extensions/templatesjs >>~/connectionsphere.app.output 2>&1
      git fetch --all >>~/connectionsphere.app.output 2>&1
      git reset --hard origin/main >>~/connectionsphere.app.output 2>&1

      # upload configuration file
      cd ~/code/connectionshere >>~/connectionsphere.app.output 2>&1
      [ -f ./config.rb ] && mv ./config.rb ./config.%timestamp%.rb >>~/connectionsphere.app.output 2>&1
      echo "%config_rb_content%" > ./config.rb

      # update gems
      #cd ~/code/connectionshere >>~/connectionsphere.app.output 2>&1
      #bundler update >>~/connectionsphere.app.output 2>&1
    ',
  }],
});