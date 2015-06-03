#!/usr/bin/env ruby

require 'optparse'
require 'tmpdir'

options = {host: 'localhost',
           port: 9000,
           thrift_command: 'thrift',
           protocol: 'Thrift::CompactProtocolFactory',
           transport: 'Thrift::FramedTransportFactory',
           socket: 'Thrift::ServerSocket',
           server: 'Thrift::SimpleServer'
          }
parser = OptionParser.new do |op|
  op.on '--host HOST', 'host to launch Thrift server on' do |host|
    options[:host] = host
  end
  op.on '-p', '--port PORT', 'port to launch Thrift server on' do |port|
    options[:port] = port.to_i
  end
  op.on '-t', '--thrift-command COMMAND', 'thrift compiler' do |cmd|
    options[:thrift_command] = cmd
  end
  op.on '--protocol PROTOCOL', 'protocol ( Thrift::CompactProtocolFactory, Thrift::BinaryProtocolFactory )' do |proto|
    options[:protocol] = proto
  end
  op.on '--transport TRANSPORT', 'transport ( Thrift::BufferedTransportFactory, Thrift::FramedTransportFactory )' do |trans|
    options[:transport] = trans
  end
  op.on '--socket SOCKET', 'socket ( Thrift::ServerSocket )' do |sock|
    options[:socket] = sock
  end
  op.on '--server SERVER', 'server ( Thrift::SimpleServer )' do |serv|
    options[:server] = serv
  end
  op.on '-h', '--help' do
    puts parser
    exit 0
  end
end

begin
  parser.parse!
rescue
  puts parser
  exit 0
end

Dir.mktmpdir do |out|
  path = File.expand_path(File.join(File.dirname(__FILE__), 'example.thrift'))
  puts (cmd = "#{options[:thrift_command]} --gen rb:namespaced --out #{out} #{path}")
  puts `#{cmd}`
  $LOAD_PATH.unshift out
  Dir["#{out}/**/*.rb"].each {|file| require file}
  $LOAD_PATH.delete out
end

class ExampleServiceImpl
  include ExampleService

  # Example with map and struct in response.
  def textStats(text)
    words = text.split(/\b/).map {|w| w.gsub(/\W/, '').downcase}.reject(&:empty?)
    results = {}
    words.uniq.each do |word|
      results[word] = WordStats.new count: words.count(word),
                                    percentage: words.count(word).to_f / words.count.to_f,
                                    palindrome: word == word.reverse
    end
    results
  end

  # Example with set, struct, and optional field in request.
  GREETINGS = {1 => "Stay warm!",
               2 => "Watch out for eldritch horrors!",
               3 => "Try to calm down."}
  def greet(people)
    str = ""
    people.each do |person|
      str << "Hello, #{person.name}! #{GREETINGS[person.favoriteWord]}\n"
    end
    str
  end

  # Example with no request params.
  def random
    rand
  end

  def voidMethod(throwException)
    raise Tantrum.new("We're out of hot chocolate!") if throwException
  end

  def onewayMethod(message)
    puts "I received the following message, which I fully intend to ignore: #{message}"
  end
end

processor = ExampleServiceImpl::Processor.new(ExampleServiceImpl.new)

# Here's the dynamic part
socket = Object::const_get(options[:socket]).new(options[:host], options[:port])
transport = Object::const_get(options[:transport]).new
protocol = Object::const_get(options[:protocol]).new

server = Object::const_get(options[:server]).new(processor, socket, transport, protocol)

puts "Starting example service as #{options[:server]} #{options[:socket]} #{options[:transport]} #{options[:protocol]} for #{options[:host]} on port #{options[:port]}"

server.serve