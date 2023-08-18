require 'sinatra'
require 'mysaas'
require 'lib/stubs'

# 
parser = BlackStack::SimpleCommandLineParser.new(
  :description => 'This command will launch a Sinatra-based BlackStack webserver.', 
  :configuration => [{
    :name=>'port', 
    :mandatory=>false, 
    :description=>'Listening port.', 
    :type=>BlackStack::SimpleCommandLineParser::INT,
    :default => 3000,
  }, {
    :name=>'config', 
    :mandatory=>false, 
    :description=>'Name of the configuration file.', 
    :type=>BlackStack::SimpleCommandLineParser::STRING,
    :default => 'config',
  }]
)

#
require parser.value('config')
require 'version'
DB = BlackStack::CRDB::connect
require 'lib/skeletons'

# helper to redirect with the params
# TODO: move this to a helper
def redirect2(url, params)
  redirect url + '?' + params.reject { |key, value| key=='agent' }.map{|key, value| "#{key}=#{value}"}.join("&")
end

# enable this line if you want to work with the live version of blackstack-core.
#require_relative '../blackstack-core/lib/blackstack-core' 

puts '

/\ "-./  \   /\ \_\ \   /\  ___\   /\  __ \   /\  __ \   /\  ___\   
\ \ \-./\ \  \ \____ \  \ \___  \  \ \  __ \  \ \  __ \  \ \___  \  
 \ \_\ \ \_\  \/\_____\  \/\_____\  \ \_\ \_\  \ \_\ \_\  \/\_____\ 
  \/_/  \/_/   \/_____/   \/_____/   \/_/\/_/   \/_/\/_/   \/_____/ 
                                                                    
Welcome to MySaaS '+MYSAAS_VERSION.green+'.

---> '+'https://github.com/leandrosardi/mysaas'.blue+' <---

Sandbox Environment: '+(BlackStack.sandbox? ? 'yes'.green : 'no'.red)+'.

'

#print "Saving PID... "
#File.open('./app.pid', 'w') { |f| f.write(Process.pid) }
#puts "done."

# include the libraries of the extensions
# reference: https://github.com/leandrosardi/mysaas/issues/33
BlackStack::Extensions.extensions.each { |e|
  require "extensions/#{e.name.downcase}/main"
}

# Load skeleton classes
BlackStack::Extensions.extensions.each { |e|
  require "extensions/#{e.name.downcase}/lib/skeletons"
}

PORT = parser.value("port")

configure { set :server, :puma }
set :bind, '0.0.0.0'
set :port, PORT
enable :sessions
enable :static

configure do
  enable :cross_origin
end  

before do
  headers 'Access-Control-Allow-Origin' => '*', 
          'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']  
end

set :protection, false

# Setting the root of views and public folders in the `~/code` folder in order to have access to extensions.
# reference: https://stackoverflow.com/questions/69028408/change-sinatra-views-directory-location
set :root,  File.dirname(__FILE__)
set :views, Proc.new { File.join(root) }

# Setting the public directory of MySaaS, and the public directories of all the extensions.
# Public folder is where we store the files who are referenced from HTML (images, CSS, JS, fonts).
# reference: https://stackoverflow.com/questions/18966318/sinatra-multiple-public-directories
# reference: https://github.com/leandrosardi/mysaas/issues/33
use Rack::TryStatic, :root => 'public', :urls => %w[/]
BlackStack::Extensions.extensions.each { |e|
  use Rack::TryStatic, :root => "extensions/#{e.name.downcase}/public", :urls => %w[/]
}

# page not found redirection
not_found do
  if !logged_in?
    redirect '/'
  else
    redirect '/404'
  end
  #redirect "/404?url=#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}#{CGI::escape(request.path_info)}"
end

# unhandled exception redirectiopn
error do
  max_lenght = 8000
  s = "message=#{CGI.escape(env['sinatra.error'].to_s)}&"
  s += "backtrace_size=#{CGI.escape(env['sinatra.error'].backtrace.size.to_s)}&"
  i = 0
  env['sinatra.error'].backtrace.each { |a| 
    a = "backtrace[#{i.to_s}]=#{CGI.escape(a.to_s)}&"
    and_more = "backtrace[#{i.to_s}]=..." 
    if (s+a).size > max_lenght - and_more.size
      s += and_more
      break
    else
      s += a
    end
    i += 1 
  }
  redirect "/500?#{s}"
end

# condition: if there is not authenticated user on the platform, then redirect to the signup page 
set(:auth) do |*roles|
  condition do
    if !logged_in?
      # remember the internal page I have to return to after login or signup
      session['redirect_on_success'] = "#{request.path_info.to_s}?#{request.query_string.to_s}"
      redirect "/login"
    elsif unavailable?
      redirect "/unavailable"      
    else
      @login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
      @service = @login.user.preference('service', '', params[:service])
    end
  end
end

# condition: if there is not authenticated user on the platform
# it must either be a sysadmin or has a subecription (active or not);
# Otherwise, redirect to /offer
if BlackStack::Extensions.exists?(:i2p)
  set(:premium) do |*roles|
    condition do
      if !logged_in?
        redirect "/plans"
      else
        a = BlackStack::I2P::Account.where(:id=>@login.user.id_account).first
        if !a.premium?
          redirect "/plans?err=You+must+have+a+premium+subscription+to+unlock+that+feature."
        end
      end
    end
  end
end

# condition: api_key parameter is required too for the access points
set(:api_key) do |*roles|
  condition do
    @return_message = {}
    
    @return_message[:status] = 'success'

    # validate: the pages using the :api_key condition must work as post only.
    if request.request_method != 'POST'
      @return_message[:status] = 'Pages with an `api_key` parameter are only available for POST requests.'
      @return_message[:value] = ""
      halt @return_message.to_json
    end

    @body = JSON.parse(request.body.read)

    if !@body.has_key?('api_key')
      # libero recursos
      DB.disconnect 
      GC.start
      @return_message[:status] = "api_key is required on #{@body.to_s}"
      @return_message[:value] = ""
      halt @return_message.to_json
    end

    if !@body['api_key'].guid?
      # libero recursos
      DB.disconnect 
      GC.start
  
      @return_message[:status] = "Invalid api_key (#{@body['api_key']}))"
      @return_message[:value] = ""
      halt @return_message.to_json      
    end
    
    validation_api_key = @body['api_key'].to_guid.downcase

    @account = BlackStack::MySaaS::Account.where(:api_key => validation_api_key).first
    if @account.nil?
      # libero recursos
      DB.disconnect 
      GC.start
      #     
      @return_message[:status] = 'Api_key not found'
      @return_message[:value] = ""
      halt @return_message.to_json        
    end
  end
end

def nav1(name1, beta=false)
  login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
  user = BlackStack::MySaaS::User.where(:id=>login.id_user).first  

  ret = 
  "<p>" + 
  "<a class='simple' href='/dashboard'><b>#{CGI.escapeHTML(user.account.name.encode_html)}</b></a>" + 
  " <i class='icon-chevron-right'></i> " + 
  CGI.escapeHTML(name1)

  ret += "  <span class='badge badge-mini badge-important'>beta</span>" if beta
  
  ret += "</p>"
end

def nav2(name1, url1, name2)
  login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
  user = BlackStack::MySaaS::User.where(:id=>login.id_user).first  

  "<p>" + 
  "<a class='simple' href='/dashboard'><b>#{user.account.name.encode_html}</b></a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url1}'>#{CGI.escapeHTML(name1)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  CGI.escapeHTML(name2) +
  "</p>"
end

def nav3(name1, url1, name2, url2, name3)
  login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
  user = BlackStack::MySaaS::User.where(:id=>login.id_user).first  
  "<p>" + 
  "<a class='simple' href='/dashboard'><b>#{user.account.name.encode_html}</b></a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url1}'>#{CGI.escapeHTML(name1)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url2}'>#{CGI.escapeHTML(name2)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  name3 +
  "</p>"
end

def nav4(name1, url1, name2, url2, name3, url3, name4)
  login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
  user = BlackStack::MySaaS::User.where(:id=>login.id_user).first  
  "<p>" + 
  "<a class='simple' href='/dashboard'><b>#{user.account.name.encode_html}</b></a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url1}'>#{CGI.escapeHTML(name1)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url2}'>#{CGI.escapeHTML(name2)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url3}'>#{CGI.escapeHTML(name3)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  name4 +
  "</p>"
end

def nav5(name1, url1, name2, url2, name3, url3, name4, url4, name5)
  login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
  user = BlackStack::MySaaS::User.where(:id=>login.id_user).first  
  "<p>" + 
  "<a class='simple' href='/dashboard'><b>#{user.account.name.encode_html}</b></a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url1}'>#{CGI.escapeHTML(name1)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url2}'>#{CGI.escapeHTML(name2)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url3}'>#{CGI.escapeHTML(name3)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url4}'>#{CGI.escapeHTML(name4)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  name5 +
  "</p>"
end

def nav6(name1, url1, name2, url2, name3, url3, name4, url4, name5, url5, name6)
  login = BlackStack::MySaaS::Login.where(:id=>session['login.id']).first
  user = BlackStack::MySaaS::User.where(:id=>login.id_user).first  
  "<p>" + 
  "<a class='simple' href='/dashboard'><b>#{user.account.name.encode_html}</b></a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url1}'>#{CGI.escapeHTML(name1)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url2}'>#{CGI.escapeHTML(name2)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url3}'>#{CGI.escapeHTML(name3)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url4}'>#{CGI.escapeHTML(name4)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  "<a class='simple' href='#{url5}'>#{CGI.escapeHTML(name5)}</a>" + 
  " <i class='icon-chevron-right'></i> " + 
  name6 +
  "</p>"
end

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# External pages: pages that don't require login

# TODO: here where you have to develop notrial? feature
get '/', :agent => /(.*)/ do
  # decide to which landing redirect, based on the extensions and configuration
  # reference: https://github.com/leandrosardi/i2p/issues/3
  #redirect '/landing'
  redirect '/signup'
end

get '/404', :agent => /(.*)/ do
  erb :'views/404', :layout => :'/views/layouts/public'
end

get '/500', :agent => /(.*)/ do
  erb :'views/500', :layout => :'/views/layouts/public'
end

get '/login', :agent => /(.*)/ do
  # TODO: decide to which landing redirect, based on the extensions and configuration
  # reference: https://github.com/leandrosardi/i2p/issues/3
  erb :'views/login', :layout => :'/views/layouts/public'
end
post '/login' do
  erb :'views/filter_login'
end
get '/filter_login' do
  erb :'views/filter_login'
end

get '/signup', :agent => /(.*)/ do
  # TODO: decide to which landing redirect, based on the extensions and configuration
  # reference: https://github.com/leandrosardi/i2p/issues/3
  erb :'views/signup', :layout => :'/views/layouts/public'
end
post '/signup' do
  erb :'views/filter_signup'
end

get '/confirm/:nid' do
  erb :'views/filter_confirm'
end

get '/logout' do
  erb :'views/filter_logout'
end

get '/recover', :agent => /(.*)/ do
  erb :'views/recover', :layout => :'/views/layouts/public'
end
post '/recover' do
  erb :'views/filter_recover'
end

get '/reset/:nid', :agent => /(.*)/ do
  erb :'views/reset', :layout => :'/views/layouts/public'
end
post '/reset' do
  erb :'views/filter_reset'
end

get '/unavailable' do
  erb :'views/unavailable', :layout => :'/views/layouts/public'
end

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# User dashboard

get '/', :auth => true do
  #redirect '/dashboard'
  redirect BlackStack::Funnel.url_after_login(@login, 'funnels.main')
end
get '/dashboard', :auth => true, :agent => /(.*)/ do
  erb :'views/dashboard', :layout => :'/views/layouts/core'
end

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Funnel

get '/offer', :agent => /(.*)/ do
  erb :'views/offer', :layout => :'/views/layouts/public'
end

get '/plans', :auth => true, :agent => /(.*)/ do
  erb :'views/plans', :layout => :'/views/layouts/public'
end

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Configuration screens

# main configuration screen
get '/settings', :auth => true do
  redirect '/settings/dashboard'
end
get '/settings/', :auth => true do
  redirect '/settings/dashboard'
end
get '/settings/dashboard', :auth => true, :agent => /(.*)/ do
  erb :'views/settings/dashboard', :layout => :'/views/layouts/core'
end

# account information
get '/settings/account', :auth => true, :agent => /(.*)/ do
  erb :'views/settings/account', :layout => :'/views/layouts/core'
end
post '/settings/filter_account', :auth => true do
  erb :'views/settings/filter_account'
end
=begin
# 
# UNDER CONSTRUCTION
# 
# white label configuration
get '/settings/whitelabel', :auth => true, :agent => /(.*)/ do
  erb :'views/settings/whitelabel', :layout => :'/views/layouts/core'
end
post '/settings/filter_whitelabel', :auth => true do
  erb :'views/settings/filter_whitelabel'
end
=end
# change password
get '/settings/password', :auth => true, :agent => /(.*)/ do
  erb :'views/settings/password', :layout => :'/views/layouts/core'
end
post '/settings/filter_password', :auth => true do
  erb :'views/settings/filter_password'
end

# change password
get '/settings/apikey', :auth => true, :agent => /(.*)/ do
  erb :'views/settings/apikey', :layout => :'/views/layouts/core'
end
post '/settings/filter_apikey', :auth => true do
  erb :'views/settings/filter_apikey'
end

## users management screen
get '/settings/users', :auth => true, :agent => /(.*)/ do
  erb :'views/settings/users', :layout => :'/views/layouts/core'
end

get '/settings/filter_users_add', :auth => true do
  erb :'views/settings/filter_users_add'
end
post '/settings/filter_users_add', :auth => true do
  erb :'views/settings/filter_users_add'
end

get '/settings/filter_users_delete', :auth => true do
  erb :'views/settings/filter_users_delete'
end
post '/settings/filter_users_delete', :auth => true do
  erb :'views/settings/filter_users_delete'
end

get '/settings/filter_users_update', :auth => true do
  erb :'views/settings/filter_users_update'
end
post '/settings/filter_users_update', :auth => true do
  erb :'views/settings/filter_users_update'
end

get '/settings/filter_users_send_confirmation_email', :auth => true do
  erb :'views/settings/filter_users_send_confirmation_email'
end
post '/settings/filter_users_send_confirmation_email', :auth => true do
  erb :'views/settings/filter_users_send_confirmation_email'
end

get '/settings/filter_users_set_account_owner', :auth => true do
  erb :'views/settings/filter_users_set_account_owner'
end
post '/settings/filter_users_set_account_owner', :auth => true do
  erb :'views/settings/filter_users_set_account_owner'
end

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# API access points

# ping
get '/api1.0/ping.json', :api_key => true do
  erb :'views/api1.0/ping'
end
post '/api1.0/ping.json', :api_key => true do
  erb :'views/api1.0/ping'
end

# notifications
get '/api1.0/notifications/open.json' do
  erb :'views/api1.0/notifications/open'
end
post '/api1.0/notifications/open.json' do
  erb :'views/api1.0/notifications/open'
end

get '/api1.0/notifications/click.json' do
  erb :'views/api1.0/notifications/click'
end
post '/api1.0/notifications/click.json' do
  erb :'views/api1.0/notifications/click'
end

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Require the app.rb file of each one of the extensions.
# reference: https://github.com/leandrosardi/mysaas/issues/33
BlackStack::Extensions.extensions.each { |e|
  require "extensions/#{e.name.downcase}/app.rb"
}

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------
# adding storage sub-folders
BlackStack::Extensions.add_storage_subfolders