require 'sinatra/base'
require 'data_mapper'

env = ENV['RACK_ENV'] || 'development'

DataMapper.setup(:default, "postgres://localhost/bookmark_manager_#{env}")

require './lib/link.rb'
require './lib/tag.rb'
require './lib/user.rb'

DataMapper.finalize
DataMapper.auto_upgrade!


class BookmarkManager < Sinatra::Base
  set :views, proc { File.join(root,'views') }
  enable :sessions
  set :session_secret, 'super secret'

  get '/' do
    @links = Link.all
    erb :index
  end

  post '/links' do
    url = params['url']
    title = params['title']
    tag = params['tags'].split(' ').map do |tag|
        Tag.first_or_create(text: tag)
    end
    Link.create(url: url, title: title, tags: tag)
    redirect to('/')
  end

  get '/tags/:text' do
    tag = Tag.first(text: params[:text])
    @links = tag ? tag.links : []
    erb :index
  end

  get '/users/new' do
    erb :'users/new'
  end

  post '/users' do
    user = User.create(email: params[:email],
                 password: params[:password],
                 password_confirmation: params[:password_confirmation])
    session[:user_id] = user.id
    redirect to('/')
  end

    helpers do

      def current_user
        @current_user ||= User.get(session[:user_id]) if session[:user_id]
      end

    end

  run! if app_file == $0
end