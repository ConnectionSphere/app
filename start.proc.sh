# kill all micro.data processed except postgress
ps ax | grep "code/connectionsphere" | grep -v postgres | grep -v grep | cut -b1-7 | xargs -t kill -9 >/dev/null 2>&1;
# start webserver
export RUBYLIB=~/code/connectionsphere
cd ~/code/connectionsphere
#ruby $HOME/code/connectionsphere/p/actions.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/deletion.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/delivery.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/export.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/leads.upload.import.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/leads.upload.ingest.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/planner.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/p/timeline.rb > /dev/null 2>&1 &
#ruby $HOME/code/connectionsphere/p/receive.rb > /dev/null 2>&1 &
ruby $HOME/code/connectionsphere/extensions/i2p/p/ipn.rb > /dev/null 2>&1 & # ==> Test this process before put it on production.
#ruby $HOME/code/connectionsphere/extensions/i2p/p/baddebt.rb > /dev/null 2>&1 & # ==> Test this process before put it on production.
#ruby $HOME/code/connectionsphere/extensions/i2p/p/expire.rb > /dev/null 2>&1 & # ==> Test this process before put it on production.
