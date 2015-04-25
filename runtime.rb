require 'rubygems'
require 'bundler/setup'
require 'rugged'
require 'sinatra'
require 'json'
require 'thread'

@language = ''
@cores = ''
@ram = ''
@repo = ''
@cloned = false
@started = false
@finished = false

before do
	@req_data = JSON.parse(request.body.read.to_s)
end

get '/language' do
	content_type :json
	{'language' => @language}.to_json
end

get '/cores' do
	content_type :json
	{'cores' => @cores}.to_json
end

get '/ram' do
	content_type :json
	{'ram' => @ram}.to_json
end

get '/spec' do
	content_type :json
	{'cores' => @cores, 'ram' => @ram, 'language' => @language}.to_json
end

get '/repo' do
	content_type :json
	{'repo' => @repo}.to_json
end

post '/spec' do
	@language = @req_data.['language']
	@cores = @req_data.['cores']
	@ram = @req_data.['ram']
	halt 200
end

post '/repo' do
	@repo = @req_data.['repo']
	halt 200
end

def clone
	#Clone the repository to computer
	if @repo.nil?
		return false
	else
		Rugged::Repository.clone_at @repo, './Project'
		@cloned = true
		return true
	end
end

get '/clone' do
	if clone()
		halt 200
	else
		halt 401
	end
end

def RunProgram
	#open Requiremwnt file
	#Check the programming language
	#install dependency
	#Run program with argument
	#Catch STDOUT and STDERR
	@finished = true;
end

get '/start' do
	clone() unless @cloned
	if @cloned
		t = Thread.new{RunProgram()}
		@started = true
		halt 200
	else
		halt 401
	end
end

get '/status' do
	content_type :json
	{'started' => @started, 'finished' => @finished}.to_json
end

get '/usage' do
	content_type :json
	#return CPU and RAM usage
end
