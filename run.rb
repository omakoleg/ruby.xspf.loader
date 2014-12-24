require 'open-uri'
require 'nokogiri'
require 'fileutils'
require 'colorize'

INPUT_DIR_PATH = File.join(Dir.getwd, 'input')
OUTPUT_DIR_PATH = File.join(Dir.getwd, 'output')

class String
  def sanitize_as_path
    self.gsub(/\/\s+/,'')
  end
end

class XspfProcessor
  
  def self.is_applied(name)
    File.extname(name) == '.xspf'
  end
    
  def initialize(content)
    @content = content
  end
  
  def run
    puts "Run XspfProcessor".green
    doc = Nokogiri::XML(@content)
    folder = doc.css('playlist title').first.content.to_s.sanitize_as_path
    #
    puts "Found:".green
    doc.css('playlist trackList track').to_a.each do |track|
      puts track.css('title').first.content.yellow
    end
    puts "Start loading".green
    
    doc.css('playlist trackList track').to_a.each do |track|
      title = track.css('title').first.content
      filename = title.sanitize_as_path
      url = track.css('location').first.content
      puts "Loading #{title} from #{url} to #{filename}"
      dir_to = File.join(OUTPUT_DIR_PATH, folder)
      path_to = File.join(dir_to, filename)
      FileUtils.mkdir_p(dir_to)
      File.open(path_to, "wb") do |saved_file|
        begin
          open(url, "rb") do |read_file|
            saved_file.write(read_file.read)
          end
        rescue OpenURI::HTTPError => e
          puts "Error: #{e.message}".red
        end
      end
      puts "Completed loading of #{title}"
    end
    puts "End XspfProcessor run".green
  end
end

Dir.foreach(INPUT_DIR_PATH) do |item|
  next if item == '.' or item == '..'
  next if Dir.exists? item
  puts "Processing #{item}"
  file = File.join(INPUT_DIR_PATH, item)
  content = File.read(file)
  XspfProcessor.new(content).run if XspfProcessor.is_applied(item) 
  puts "Remove file: #{file}".red
  FileUtils.rm file
end
