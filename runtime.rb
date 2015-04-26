require 'bundler/setup'
require 'rugged'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'json'
require 'thread'
require 'usagewatch'
require 'open3'

configure { set :server, :puma }

$language = ''
$cores = ''
$ram = ''
$repo = ''
$cloned = false
$started = false
$finished = false
$initialized = false
$stdin
$stdout
$stderr
$t

before do
	next unless request.post?
	request.body.rewind
	$req_data = JSON.parse(request.body.read)
end

get '/language' do
	content_type :json
	{'language' => $language}.to_json
end

get '/cores' do
	content_type :json
	{'cores' => $cores}.to_json
end

get '/ram' do
	content_type :json
	{'ram' => $ram}.to_json
end

get '/spec' do
	content_type :json
	{'cores' => $cores, 'ram' => $ram, 'language' => $language}.to_json
end

get '/repo' do
	content_type :json
	{'repo' => $repo}.to_json
end

post '/spec' do
	$language = $req_data['language']
	$cores = $req_data['cores']
	$ram = $req_data['ram']
	halt 200
end

post '/repo' do
	#request.body.rewind
	#$req_data = JSON.parse(request.body.read)
	$repo = $req_data['repo']
	content_type :json
	puts $req_data
	{'repo' => $req_data}.to_json
	halt 200
end

def clone
	#Clone the repository to computer
	if $repo.nil?
		return false
	else
		Rugged::Repository.clone_at $repo, './Project'
		$cloned = true
		return true
	end
end

get '/clone' do
	clone unless $cloned
	if $cloned
		halt 200
	else
		halt 401
	end
end

def run_program
	Dir.chdir('./Project')
	supported_language = ['ruby', 'python', 'python3', 'nodejs', 'perl']
	#open Requiremwnt file
	if File.exist?('./requirement.json')
		file_content = File.read('./requirement.json')
		converted = JSON.parse(file_content)
		#Check the programming language
		if supported_language.include? converted['language']
			#install dependency
			converted['depend'].each{ |m|
				if converted['language'] == 'ruby'
					#Install dependency using rubygem
					`gem install #{m}`
				elsif converted['language'] == 'python'
					#install using pip
					`pip install #{m}`
				elsif converted['language'] == 'python3'
					#install using pip3
					`pip3 install #{m}`
				elsif converted['language'] == 'nodejs'
					#install using npm
					`npm install #{m}`
				elsif converted['language'] == 'perl'
					#install using something
					`cpan #{m}`
				end
			} unless converted['depend'].nil?
			program_argument = ''
			program_argument = converted['argument'] unless converted['argument'].nil?
			$stdin, $stdout, $stderr, wait_thr = Open3.popen3(converted['language'], converted['execute'], program_argument)
			$started = true
			exit_status = wait_thr.value
		end
	end
	$finished = true;
end

get '/start' do
	clone() unless $cloned
	if $cloned
		#Dir.chdir('/root')
		$initialized = true
		$t = Thread.new{
			run_program()
			#sleep 100
		}
		#$t.join
		halt 200
	else
		halt 401
	end
end

get '/output' do
	if $started
		stdout_now = $stdout.read
		stderr_now = $stderr.read
		stdout_file = File.open('../stdout.txt', 'a')
		stderr_file = File.open('../stderr.txt', 'a')
		stdout_file << stdout_now
		stderr_file << stderr_now
		stdout_file.close
		stderr_file.close
		content_type :json
		{'stdout' => stdout_now, 'stderr' => stderr_now}.to_json
	end
end

get '/all_output' do
	if $started
		all_stdout = File.open('../stdout.txt', 'a+')
		all_stderr = File.open('../stderr.txt', 'a+')
		stdout_now = $stdout.read
		stderr_now = $stderr.read
		all_stdout << stdout_now
		all_stderr << stderr_now
		all_stdout.close
		all_stderr.close
		content_type :json
		{'stdout' => File.read('../stdout.txt'), 'stderr' => File.read('../stderr.txt')}.to_json
	end
end

post '/input' do
	$stdin.puts($req_data['input'])
end

get '/status' do
	content_type :json
	{'started' => $started, 'finished' => $finished}.to_json
end

get '/usage' do
	content_type :json
	#return CPU and RAM usage
	usw = Usagewatch
	{'cpu' => usw.uw_cpuused, 'ram' => usw.uw_memused, 'read' => usw.uw_diskioreads, 'write' => usw.uw_diskiowrite}.to_json
end
