# encoding: ascii-8bit
# 
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#   http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
# 

require 'socket'
require 'openssl'

module Thrift
	class SSLServerSocket < ServerSocket
		# call-seq: initialize(host = nil, port)
		def initialize(host_or_port, port = nil, key, cert)
			super(host_or_port, port)

			@ssl_context = OpenSSL::SSL::SSLContext.new()
			@ssl_context.cert = OpenSSL::X509::Certificate.new(File.open(cert))
			@ssl_context.key = OpenSSL::PKey::RSA.new(File.open(key))
		end

		def listen
			socket = TCPServer.new(@host, @port)
			@handle = OpenSSL::SSL::SSLServer.new(socket, @ssl_context)
		end

		def accept
			begin
				super
			rescue OpenSSL::SSL::SSLError
				retry
			end
		end
	end
end
