#!/usr/bin/env ruby
# frozen_string_literal: true

# @author: Demetrius Ford
# @date: 13 Oct 2023
# @docs: https://www.namecheap.com/support/api/intro/

require "faraday"
require "faraday/decode_xml"
require "logger"
require "yaml_vault"

module Namecheap
  class Config
    attr_reader :params

    def initialize
      secrets = "#{File.dirname(__FILE__)}/secrets.yml"
      targets = [["$", "vault"]]
      passphrase = ENV["YAML_VAULT_PASSPHRASE"]

      raise "passphrase is not set!" if passphrase.nil?

      @params = YAML.load(
        YamlVault::Main.from_file(
          secrets,
          targets,
          passphrase: passphrase,
        ).decrypt_yaml,
      )
    end
  end
end

module Namecheap
  class Response
    def initialize(response)
      @response = response
    end

    def results
      raise "(#{errors["Number"]}) #{errors["__content__"]}" if errors&.any?

      @response.body["ApiResponse"]["CommandResponse"]["DomainGetListResult"]
    end

    private

    def errors
      errors_object = @response.body["ApiResponse"]["Errors"]
      return errors_object.first[1] unless errors_object.nil?

      {}
    end
  end
end

module Namecheap
  class Account
    EXPIRE_DAYS = 90

    def initialize(results)
      list_result = [results["Domain"]].flatten(1)

      @domains = {}

      list_result.each do |domain|
        @domains[domain["Name"]] = Date.strptime(domain["Expires"], "%m/%d/%Y")
      end
    end

    def expires_soon
      @domains.select { |_, future| (future - Date.today).to_i <= EXPIRE_DAYS }
    end
  end
end

module Namecheap
  class API
    URL = "https://api.namecheap.com"

    GET_LIST = {
      command: "namecheap.domains.getList",
      options: {
        "SortBy": "EXPIREDATE",
      },
    }

    def initialize
      vault = Namecheap::Config.new.params["vault"]

      @api_user = vault["api_user"]
      @api_key = vault["api_key"]
      @client_ip = vault["client_ip"]
    end

    def check
      response = fetch(
        GET_LIST[:command],
        GET_LIST[:options],
      )

      content = Namecheap::Response.new(response).results

      Namecheap::Account
        .new(content)
        .expires_soon
    end

    private

    def fetch(command, params = {})
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

if __FILE__ == $PROGRAM_NAME
  logger = Logger.new($stderr, level: Logger::WARN)

  namecheap = Namecheap::API.new
  domains = namecheap.check.keys

  logger.warn(domains.join(", ")) unless domains.empty?
end
