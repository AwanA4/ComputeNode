require 'rubygems'
require 'bundler/setup'
require 'rugged'
require 'sinatra'
require 'json'
require 'thread'
require 'usagewatch'
require 'open3'

@language = ''
@cores = ''
@ram = ''
@repo = ''
@cloned = false
@started = false
@finished = false
@stdin = ''
@stdout = ''
@stderr = ''

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
	Dir.chdir('./Project')
	supported_language = ['ruby', 'python', 'python3', 'nodejs', 'perl']
	#open Requiremwnt file
	if FILE.exist?('./requrement.json')
		file_content = FILE.read('./requrement.json')
		converted = JSON.parse(file_content)
		#Check the programming language
		if supported_language.members? converted['language']
			#install dependency
			converted['depend'].members.each{ |m|
				if converted['language'] == 'ruby'
					#Install dependency using rubygem
				elsif converted['language'] == 'python'
					#install using pip
				elsif converted['language'] == 'python3'
					#install using pip3
				elsif converted['language'] == 'nodejs'
					#install using npm
				elsif converted['language'] == 'perl'
					#install using something
				end
			}
			@stdin, @stdout, @stderr, wait_thr = Open3.popen3(converted['language'], converted['execute'], converted['argument'])
			exit_status = wait_thr.value
		end
	end
	@finished = true;
end

get '/start' do
	clone() unless @cloned
	if @cloned
		Dir.chdir('/root')
		t = Thread.new{RunProgram()}
		@started = true
		halt 200
	else
		halt 401
	end
end

get '/output' do
	content_type :json
	{'stdout' => @stdout.read, 'stderr' => @stderr.read}.to_json
end

post '/input' do
	@stdin.puts(@req_data['input'])
end

get '/status' do
	content_type :json
	{'started' => @started, 'finished' => @finished}.to_json
end

get '/usage' do
	content_type :json
	#return CPU and RAM usage
	usw = Usagewatch
	{'cpu' => usw.uw_cpuused, 'ram' => usw.uw_memused, 'read' => usw.uw_diskioreads, 'write' => usw.uw_diskiowrite}.to_json
end
