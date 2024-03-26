# kill all micro.data processed except postgress
ps ax | grep "code/connectionshere" | grep -v postgres | grep -v grep | cut -b1-7 | xargs -t kill -9 >/dev/null 2>&1;
# start webserver
export RUBYLIB=~/code/connectionshere
cd ~/code/connectionshere
#ruby $HOME/code/connectionshere/p/actions.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/deletion.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/delivery.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/export.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/leads.upload.import.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/leads.upload.ingest.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/planner.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/p/timeline.rb > /dev/null 2>&1 &
#ruby $HOME/code/connectionshere/p/receive.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionshere/extensions/i2p/p/ipn.rb > /dev/null 2>&1 & # ==> Test this process before put it on production.
#ruby $HOME/code/connectionshere/extensions/i2p/p/baddebt.rb > /dev/null 2>&1 & # ==> Test this process before put it on production.
#ruby $HOME/code/connectionshere/extensions/i2p/p/expire.rb > /dev/null 2>&1 & # ==> Test this process before put it on production.
