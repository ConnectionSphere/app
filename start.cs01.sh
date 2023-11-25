# kill all micro.data processed except postgress
ps ax | grep "code/app" | grep -v postgres | grep -v grep | cut -b1-7 | xargs -t kill -9 >/dev/null 2>&1;
# start webserver
export RUBYLIB=~/code
cd ~/code/app
ruby $HOME/code/app/app.rb port=3000 config=./config.rb > /dev/null 2>&1 &
