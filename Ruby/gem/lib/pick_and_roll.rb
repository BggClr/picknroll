require 'json'
require 'hash_deep_merge'
#require 'awesome_print'

class PickAndRoll
  MASTER_CONFIG = 'config.json'
  PARCONFIG_FILE_NAME = '.parconfig'

	def initialize(config_path = '')
    @parconfig = read_configuration
    @config_file = config_path.to_s
  end

  def pick
    master_config_name = @parconfig.has_key?('config') ? @parconfig['config'] : MASTER_CONFIG
    if File.exist?(master_config_name)
      @config = JSON.parse(File.read(master_config_name))
      puts "pick config: #{master_config_name}"
    else
      @config = Hash.new
    end

    if @config_file.strip.empty? == false && File.exists?("#{@config_file}.json")
      @config.deep_merge!(JSON.parse(File.read("#{@config_file}.json")))
      puts "pick config: #{@config_file}.json"
    elsif File.exist?("#{ENV["COMPUTERNAME"]}.json")
      @config.deep_merge!(JSON.parse(File.read("#{ENV["COMPUTERNAME"]}.json")))
      puts "pick config: #{ENV["COMPUTERNAME"]}.json"
    end

    if @config.empty?
      printf 'Please set configuration path or create config.json file'
      exit
    end
  end

  def roll
    file_patterns = get_file_patterns()

    file_patterns.each {|file_pattern|
      Dir.glob("**/#{file_pattern}"){ |file_name|
        File.open(file_name,'r'){ |config_file|
          puts "roll file: #{file_name}"
          File.open(file_name.gsub(/\.generic\./,'.'), 'w'){ |f|
            f.write config_file.read().gsub(/@@([\w\.]*)@@/) {|s| find_config_value $1}
          }
        }
      }
    }
  end

  def get_file_patterns
    @parconfig.has_key?('files') ? @parconfig['files'] : Array.new
  end

  def read_configuration
    result = Hash.new
    if File.exist?(PARCONFIG_FILE_NAME)
      result = JSON.parse(File.read(PARCONFIG_FILE_NAME))
    end

    result
  end

  def find_config_value(key)
    key.split('.').inject(@config) { |config, name| config[name] }
  end

  def go
    pick
    roll
  end
end