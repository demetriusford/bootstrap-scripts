#!/usr/bin/env ruby
# frozen_string_literal: true

# @author: Demetrius Ford
# @date: 13 Oct 2023
# @docs: https://www.namecheap.com/support/api/intro/

require "yaml"
require "faraday"
require "faraday/decode_xml"

class Namecheap
  BASE_URI = "https://api.namecheap.com/"

  attr_reader :api_user, :api_key, :client_ip

  def initialize(options = {})
    config = YAML.load_file(
      "#{File.dirname(__FILE__)}/credentials.yml",
    ).transform_keys!(&:to_sym)

    @api_user = options[:api_user] || config[:api_user]
    @api_key = options[:api_key] || config[:api_key]
    @client_ip = options[:client_ip] || config[:client_ip]
  end

  def check_domains
    results = list_domains.results["Domain"]

    domains = {}
    domains[results["Name"]] = Date.strptime(results["Expires"], "%m/%d/%Y")
    domains.keep_if { |_, future| (future - Date.today).to_i >= 90 }
  end

  def list_domains
    response = request(
      "namecheap.domains.getList",
      {
        "ListType": "ALL",
        "SortBy": "EXPIREDATE",
      },
    )

    NamecheapResponse.new(response)
  end

  private

  def request(command, params = {})
    globals = {
      "ApiUser" => @api_user,
      "ApiKey" => @api_key,
      "Username" => @api_user,
      "Command" => command,
      "ClientIp" => @client_ip,
    }

    connection = Faraday.new(
      url: BASE_URI,
      params: params.empty? ? globals : globals.merge(params),
    ) do |faraday|
      faraday.response(:xml)
    end

    connection.get("/xml.response")
  end
end

class NamecheapError < StandardError; end

class NamecheapResponse
  def initialize(response)
    unless response.is_a?(Faraday::Response)
      raise NamecheapError("Not a Faraday::Response class")
    end

    @response = response
  end

  def errors
    errors_object = @response.body["ApiResponse"]["Errors"]
    return errors_object.first[1] unless errors_object.nil?

    {}
  end

  def results
    if errors.any?
      raise NamecheapError, "(#{errors["Number"]}) #{errors["__content__"]}"
    end

    @response.body["ApiResponse"]["CommandResponse"]["DomainGetListResult"]
  end
end

pp Namecheap.new.check_domains if __FILE__ == $PROGRAM_NAME
