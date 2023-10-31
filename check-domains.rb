#!/usr/bin/env ruby
# frozen_string_literal: true

# @author: Demetrius Ford
# @date: 13 Oct 2023
# @docs: https://www.namecheap.com/support/api/intro/

require "yaml"
require "faraday"
require "faraday/decode_xml"

module Namecheap
  class Config
    OK = [:api_user, :api_key, :client_ip]

    attr_reader :globals

    def initialize
      @globals = YAML.load_file(
        "#{File.dirname(__FILE__)}/secrets.yml",
      ).transform_keys!(&:to_sym)
    end

    def valid?
      OK.all? { |key| @globals.key?(key) } && @globals.values.none?(&:empty?)
    end
  end
end

module Namecheap
  class Response
    def initialize(response)
      unless response.is_a?(Faraday::Response)
        raise "Invalid object - expected a Faraday::Response"
      end

      @response = response
    end

    def errors
      errors_object = @response.body["ApiResponse"]["Errors"]
      return errors_object.first[1] unless errors_object.nil?

      {}
    end

    def results
      if !errors.nil? && errors.any?
        raise "(#{errors["Number"]}) #{errors["__content__"]}"
      end

      @response.body["ApiResponse"]["CommandResponse"]["DomainGetListResult"]
    end
  end
end

module Namecheap
  class Results
    def initialize(results)
      cleansed = results.is_a?(Array) ? results["Domain"] : [results["Domain"]]

      @domains = {}
      cleansed.each do |domain|
        @domains[domain["Name"]] = Date.strptime(domain["Expires"], "%m/%d/%Y")
      end
    end

    def expires_soon
      @domains.select { |_, later| (later - Date.today).to_i <= 90 }
    end
  end
end

module Namecheap
  class API
    URL = "https://api.namecheap.com"

    def initialize
      config = Namecheap::Config.new

      raise "Config is not valid" unless config.valid?

      @api_user = config.globals[:api_user]
      @api_key = config.globals[:api_key]
      @client_ip = config.globals[:client_ip]
    end

    def check
      response = request(
        "namecheap.domains.getList", {
          "SortBy": "EXPIREDATE",
        }
      )

      parsed = Namecheap::Response.new(response)

      Namecheap::Results
        .new(parsed.results)
        .expires_soon
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
        url: URL,
        params: params.empty? ? globals : globals.merge(params),
      ) do |faraday|
        faraday.response(:xml)
      end

      connection.get("/xml.response")
    end
  end
end

pp Namecheap::API.new.check.keys if __FILE__ == $PROGRAM_NAME
