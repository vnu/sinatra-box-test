require 'rubygems' if RUBY_VERSION < '1.9'

#BoxApp using Sinatra , Box-API and Haml

require 'box-api'
require 'sinatra'
require 'rack-flash'

# Sessions are used to keep track of user logins.
enable :sessions
@signed_in = false

# This is where we set the API key given by Box.
# Get a key here: https://www.box.net/developers/services
set :box_api_key, ENV['BOX_API_KEY']
Box_API = "z6uq0jbsoiz3qe3qhp4s5wrx08j05j7f"

helpers do
	
	# Requires the user to be logged into Box, or redirect them to the login page.
 	 def require_login
      #box_login(settings.box_api_key, session) do |auth_url|
      box_login(Box_API, session) do |auth_url|
      redirect auth_url
    end
  end
    def update_box_login
	    # update the variables if passed parameters (such as during a redirect)
	    session[:box_ticket] ||= params[:ticket]
	    session[:box_token] ||= params[:auth_token]
  	end



	# Authenticates the user using the given API key and session information.
    # The session information is used to keep the user logged in.
    def box_login(box_api_key, session)
      # make a new Account object using the API key
      account = Box::Account.new(box_api_key)

      # use a saved ticket or request a new one
      ticket = session[:box_ticket] || account.ticket
      token = session[:box_token]

      # try to authorize the account using the ticket and/or token
      authed = account.authorize(:ticket => ticket, :auth_token => token) do |auth_url|
        # this block is called if the authorization failed

        # save the ticket we used for later
        session[:box_ticket] = ticket

        # yield with the url the user must visit to authenticate
        yield auth_url if block_given?
      end

      if authed
        # authentication was successful, save the token for later
        session[:box_token] = account.auth_token

        # return the account
        return account
      end
    end

    def signed_in?
      require_login
    end

    # Removes session information so the account is forgotten.

    # Note: This doesn't actually log the user out, it just clears the session data.
    def box_logout(session)
      session.delete(:box_token)
      session.delete(:box_ticket)
    end


end
#Root of BoxApp

get '/' do 
  puts "Hello" 
  haml :index  
end  
get '/about' do  
  haml :about  
end  
get '/login' do 

  update_box_login            # updates login information if given
  account = require_login     # make sure the user is authorized
  @signed_in = true
  root = account.root         # get the root folder of the account 
  haml :login
   
end 

# Handles logout requests.
get "/logout" do
  box_logout(session)
  @signed_in = false

  redirect "/" # redirect to the home page
end 