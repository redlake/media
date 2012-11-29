#!/Users/cdavies/.rvm/rubies/ruby-1.9.3-p194/bin/ruby

require 'rubygems'
require 'open-uri'
require 'net/http'
require 'rexml/document'
require "ap"
require 'terminal-table'
require 'simple_progressbar'
require 'hpricot'
require 'timeout'


$newF = Hash.new
$theOut = Hash.new
# Search for nodes by xpath

class Videofile
   attr_accessor :dir, :series_name, :series_number, :episode_number, :episode_name, :the_file, :new_name, :url_name, :base, :ext

   def initialize(the_file = "", series_name = "", episode_name = "", episode_number = "", series_number = "" )
      if File.exists?(the_file)
         @ext = File.extname(the_file)
         @dir = File.dirname("#{File.absolute_path(the_file)}")
         @the_file = the_file

         @series_name = series_name
         @episode_name = episode_name
         @episode_number = episode_number
         @series_number = series_number

         @base = File.basename(the_file, File.extname(the_file))
         #puts "@base #{@base}"
         parse_file_name
         @url_name = @series_name.gsub(/ /, '%20')
         check_episode_name
      end
      return self
   end


   def parse_file_name
      # ap @base.match(/^(?<seriesName>.+)\.s(?<seriesno>\d+)e(?<episodeno>\d+)\.(?<episodeName>.+)$/)
      # ap @base.match(/^(?<seriesName>.+)\.s(?<seriesno>\d+)e(?<episodeno>\d+)$/)
      # ap @base.match(/^(?<seriesName>.+)\.(?<episodeName>.+)$/)
      # ap @base.match(/^(?<seriesName>.+)$/)
      # puts __LINE__
      case
      when @base.match(/^(.+)\.(s|S)(\d+)(e|E|x)(\d+)/)
        @series_name = $1.to_s
        @series_number = $3.to_s
        @episode_number = $5.to_s   
        #print "Show: %s, Series:%s, Episode:%s\t%s.s%se%s" % [ @series_name, @series_number, @episode_number, @series_name, @series_number, @episode_number ]
          
      end
      
   end

   def check_episode_name
      begin
         url="http://services.tvrage.com/feeds/episodeinfo.php?show=#{@url_name}&exact=0&ep=#{@series_number}x#{@episode_number}"
         #puts url
         doc = Hpricot(open(url).read)
         raise StandardError, "More than 1 show found. Please check name." if (doc/"show").count > 1
         raise StandardError, "No shows found. Please check name." if (doc/"show").count < 1
         @series_name = doc.search("show/name").inner_text
         @episode_name = doc.search("episode/title").inner_text
      end
   end

   def new_name
      @newName = @series_name + ".s" + @series_number + "e" + @episode_number + "." + @episode_name + @ext
   end

   def check_exists
      puts @newName
      puts @dir
      puts "#{@dir}/@newName"
      if FileTest.exists?("#{@dir}/new_name")
         #                # @newName = @series_name + ".s" + @series_number + "e" + @episode_number + "." + @episode_name + ".new" + @fileExt
         puts "#{self.new_name} already exists in #{@dir}\n"
         @newName = "#{new_name}-1"
      end
   end
end

def wikiguide
  puts "wikiguide"
  url = "http://en.wikipedia.org/wiki/List_of_The_Golden_Girls_episodes"
  doc = Hpricot(open(url).read)
  ap doc.search("tr.vevent/td.summary/b").inner_text
  ap doc.search("td.description").inner_text 
end


begin
   #wikiguide
   #raise ArgumentError, "You must choose some files" unless ARGV.count > 0
   puts "Starting..."
   allowed = ['.mp4', '.avi', '.mkv', '.m4v', '.mov']
   videofiles = Array.new
   max_new_name_length = 0
   max_the_file_length = 0

   results = Terminal::Table.new :headings => ['Original Name', 'New Name' ]

   i = 1
   progress_bar = SimpleProgressbar.new.show("Checking TV Rage...") do
      ARGV.each do|theFile|
         if allowed.include? File.extname(theFile)
            videofile = Videofile.new("#{theFile}")
            videofile.new_name
            if videofile.new_name.length > max_new_name_length then
               max_new_name_length = videofile.new_name.length
            end
            videofiles << ["#{videofile.the_file}", "#{videofile.new_name}"]
            results << [ "#{videofile.base}#{videofile.ext}", videofile.new_name ]
            complete = ((1/ARGV.length.to_f) * i * 100).to_i
            progress(complete)
            # print progress_bar
            i = i + 1
         end
      end
   end
   puts results
   puts "\nRename (y/n)?"

   if $stdin.gets.chomp.start_with? "y"
      puts "OK"
      videofiles.each do |a|
         #ap a
         #puts File.dirname(a[0])
         Dir.chdir(File.dirname(a[0]))
         File.rename("#{a[0]}", "#{a[1]}")
      end
   end
rescue ArgumentError => msg
   print "\n%s\n" % [msg]
rescue StandardError => msg
   #puts "/n"
   #ap msg.backtrace
   print "\n%s\n" % [msg]
end
