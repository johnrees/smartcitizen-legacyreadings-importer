require 'rubygems'
require 'bundler'
Bundler.require(:default)

Figaro.application = Figaro::Application.new(environment: "production", path: "application.yml")
Figaro.load

puts ENV['test']

