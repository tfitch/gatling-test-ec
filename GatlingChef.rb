#!/usr/bin/env ruby
# encoding: UTF-8

require 'thor'
require 'base64'
require 'openssl'
require 'time'

class GatlingChef < Thor
  desc 'update FILE', 'Update timestamps and re-sign Chef authentication ' +
                      'headers in a Gatling http://gatling-tool.org/ simulation file.'
  long_desc <<-LONGDESC
    Reads a Gatling simulation file and outputs the content with Chef
    authentication headers updated in the following ways.

    Updates the Chef authentication headers with a timestamp ten minutes into
    the future in order to lengthen the amount of time they will be valid for a
    Gatling run.

    Re-signs the Chef authentication headers with a chosen client or user name
    and its corresponding private key. This is especially helpful when sharing
    a Gatling simulation file.
  LONGDESC
  method_option :debug, type: :boolean, default: false, aliases: '-d',
                        desc: 'Enable debug output'
  method_option :key, required: true, aliases: '-k',
                      desc: 'The private key that Knife will use to sign ' +
                            'requests made by the API client to the server.'
  method_option :user, required: true, aliases: '-u',
                       desc: 'The user name used by Knife to sign requests ' +
                             'made by the API client to the server.'
  def update(file)
    content = []

    headers_name = ''
    part_of_headers = false
    headers = Hash.new { |hash, key| hash[key] = {
        'content_hash' => '',
        'headers_lines' => [],
        'indent' => '',
        'insertion_index' => nil,
        'request_method' => '',
        'request_endpoint' => '' } }

    request_method = ''
    request_endpoint = ''
    part_of_request = false

    File.open(file, 'r').each do |line|
      if line.strip.match(/^val (headers_\d+) = Map\($/)
        headers_name = Regexp.last_match[1]
        part_of_headers = true
      end

      headers[headers_name]['headers_lines'].push line if part_of_headers
      headers[headers_name]['content_hash'] = Regexp.last_match[1] if part_of_headers && line.match(/"+X-Ops-Content-Hash"+ -> "+(.*?)"+/)

      if part_of_headers && line.strip.match(/\)$/)
        headers[headers_name]['indent'] = line.match(/^\s*/)[0]
        headers[headers_name]['insertion_index'] = content.length + 1

        if line.match /X-Ops-(Authorization|Timestamp|Userid)/
          headers[headers_name]['insertion_index'] -= 1
        else
          line.sub!(/\)(\s*)$/, ',\\1')
        end

        headers_name = ''
        part_of_headers = false
      end

      if line.match /\.(post|get|put|delete)\("+(.*?)"+\)/
        request_method = Regexp.last_match[1].upcase
        request_endpoint = Regexp.last_match[2]
        part_of_request = true
      elsif part_of_request && line.match(/\.headers\((.*?)\)/)
        headers[Regexp.last_match[1]]['request_method'] = request_method
        headers[Regexp.last_match[1]]['request_endpoint'] = request_endpoint
        request_method = ''
        request_endpoint = ''
        part_of_request = false
      end

      content.push line unless line.match /X-Ops-(Authorization|Timestamp|Userid)/
    end

    headers.sort { |a, b| a[0].match(/\d+/)[0].to_i <=> b[0].match(/\d+/)[0].to_i }.reverse.each do |headers_name, headers_values|
      if options[:debug]
        puts 'Header: ' + headers_name
        puts 'Method: ' + headers_values['request_method']
        puts 'Endpoint: ' + headers_values['request_endpoint']
        puts 'Content Hash: ' + headers_values['content_hash']

        headers_values['headers_lines'].each do |headers_line|
          puts 'Line: ' + headers_line
        end
        puts
      end

      hashed_path = Base64.encode64(Digest::SHA1.digest(headers_values['request_endpoint'])).chomp
      timestamp = (Time.now.utc + 10 * 60).iso8601

      canonical_request = "Method:#{headers_values['request_method']}\n"
      canonical_request += "Hashed Path:#{hashed_path}\n"
      canonical_request += "X-Ops-Content-Hash:#{headers_values['content_hash']}\n"
      canonical_request += "X-Ops-Timestamp:#{timestamp}\n"
      canonical_request += "X-Ops-UserId:#{options[:user]}"

      private_key = OpenSSL::PKey::RSA.new File.read(options[:key])
      signature_lines = Base64.encode64(private_key.private_encrypt(canonical_request)).chomp.split(/\n/)

      auth_headers = []
      signature_lines.each_index do |idx|
        auth_headers.push "#{headers_values['indent']}\"\"\"X-Ops-Authorization-#{idx + 1}\"\"\" -> \"\"\"#{signature_lines[idx]}\"\"\","
      end
      auth_headers.push "#{headers_values['indent']}\"\"\"X-Ops-Timestamp\"\"\" -> \"\"\"#{timestamp}\"\"\","
      auth_headers.push "#{headers_values['indent']}\"\"\"X-Ops-Userid\"\"\" -> \"\"\"#{options[:user]}\"\"\")"

      content.insert(headers_values['insertion_index'], auth_headers)
    end

    content.each do |line|
      puts line
    end
  end
end

GatlingChef.start