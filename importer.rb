require 'rubygems'
require 'bundler'
Bundler.require(:default)

Figaro.application = Figaro::Application.new(environment: "production", path: "application.yml")
Figaro.load

class MySQL < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(
    :adapter  => 'mysql',
    :database => ENV['mysql_database'],
    :host     => ENV['mysql_host'],
    :username => ENV['mysql_username'],
    :password => ENV['mysql_password'],
    :encoding => 'utf8',
    :collation => 'utf8_general_ci'
  )
end

class Device < MySQL 
end

puts Device.last.id
 
