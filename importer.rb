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
    :collation => 'utf8_general_ci',
    :pool => 16
  )
end

class Feed < MySQL; end
class Device < MySQL; end

class RawStorer

  attr_accessor :sensors, :commands

  def bat i, v
    return i/10.0
  end

  def co i, v
    return i/1000.0
  end

  def light i, v
    return i/10.0
  end

  def nets i, v
    return i
  end

  def no2 i, v
    return i/1000.0
  end

  def noise i, v
    return i
  end

  def panel i, v
    return i/1000.0
  end

  def hum i, v
    if v.to_s == "1.0"
      i = i/10.0
    end
    return i
  end

  def temp i, v
    if v.to_s == "1.0"
      i = i/10.0
    end
    return i
  end

  def initialize device 

      keys = %w(temp bat co hum light nets no2 noise panel)

      Feed.where(device_id: device.id).each do |feed|
	begin
      ts = feed.timestamp.to_i * 1000

      _data = []
      self.commands = []

      keys.each do |sensor|
        metric = sensor
        value = feed[sensor]
        value = method(sensor).call( (Float(value) rescue value), device.kit_version)
        self.commands << "#{metric} #{ts} #{value} device=#{device.id} identifier=#{device.kit_version}"
      end

    rescue Exception => e
      commands = ['FAIL']
    end
end
  end


end

Parallel.each(Device.order(id: :desc).limit(500)) do |device|
begin
  File.open("imports/#{device.id}.txt", 'w') do |file|
    file.write RawStorer.new(device).commands.join("\n")
  end
rescue
puts device.id
end
end
#Feed.connection.reconnect!
 
