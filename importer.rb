require 'rubygems'
require 'bundler'
Bundler.require
require 'active_record'
Figaro.application = Figaro::Application.new(environment: "production", path: "application.yml")
Figaro.load

class My < ActiveRecord::Base
  self.abstract_class = true
  establish_connection(
    :adapter  => 'mysql',
    :database => ENV['mysql_database'],
    :host     => ENV['mysql_host'],
    :username => ENV['mysql_username'],
    :password => ENV['mysql_password'],
    :encoding => 'utf8',
    :collation => 'utf8_general_ci',
    :pool => 30
  )
end

class Feed < My; end
class Device < My; end

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
      batch_size = 8000
      count = Feed.where(device_id: device.id).count
      count = count/batch_size
      count += 1 if count%batch_size > 0
      total = count
      last_id = 0
      self.commands = []
      while count >= 0
        print "#{device.id} - #{count}/#{total}\n"
        ids = Feed.where("device_id = ? and id > ?", device.id, last_id).limit(batch_size).ids
        Feed.find(ids).each do |feed|
	  begin
            ts = feed.timestamp.to_i * 1000
            keys.each do |sensor|
              metric = sensor
              value = feed[sensor]
              value = method(sensor).call( (Float(value) rescue value), device.kit_version)
              self.commands << "put #{metric} #{ts} #{value} device_id=#{device.id} identifier=sck#{device.kit_version}"
            end
          rescue Exception => e
            raise "FAIL"
          end
        end
        last_id = ids.last
        count -= 1
      end
  end

end

Parallel.each(Device.order(id: :desc)) do |device|
		begin
			File.open("imports/#{device.id}.txt", 'w') do |file|
    				file.write RawStorer.new(device).commands.join("\n")
  			end
  			print [device.id,"OK\n".green].join("\t")
		rescue Exception => e
			print [device.id,"ERROR".red,"#{e.message.strip}\n"].join("\t")
		end
	end
#Feed.connection.reconnect!
 
