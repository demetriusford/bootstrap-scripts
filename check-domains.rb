#!/usr/bin/env ruby
# frozen_string_literal: true

# @author: Demetrius Ford
# @date: 13 Oct 2023
# @docs: https://www.namecheap.com/support/api/intro/

class Namecheap
  BASE_URI = "https://api.namecheap.com/"

  attr_reader :client_ip, :api_key, :username

  def initialize(config)
    @client_ip = config[:client_ip]
    @api_key = config[:api_key]
    @username = config[:username]
  end

  private

  def request(command, options = {})
    params = {
      "ApiUser" => @username,
      "ApiKey" => @api_key,
      "UserName" => @username,
      "Command" => command,
    }

    Faraday.get(
      BASE_URI + "/xml.response",
      options.empty? ? params : params.merge(options),
      { content_type: "application/xml" },
    )
  end
end

class NamecheapResponse
  def initialize(response)
    @response = response
  end

  def results
    @response["ApiResponse"]["CommandResponse"]
  end
end

if __FILE__ == $PROGRAM_NAME
  Namecheap.new(
    {
      client_ip: "0.0.0.0",
      api_key: "s3cr3t",
      username: "username",
    },
  )
end
