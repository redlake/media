#!/Users/cdavies/.rvm/rubies/ruby-1.9.3-p194/bin/ruby
# coding: ISO-8859-1
# system("clear")

require 'rubygems'
require 'awesome_print'
require 'pathname'
require 'optparse'
require 'terminal-table'
require 'benchmark'
require 'drx'
require 'colored'
require 'open3'
require 'English'
require 'YAML'
# require "ruby-debug/debugger"

# require 'minitest/spec'
# require 'minitest/autorun'

#puts __FILE__
#puts File.dirname(__FILE__)
#puts "#{File.dirname(__FILE__)}/constants"

# puts File.dirname("#{$0}")
MP4TAGGER = "/usr/local/bin/mp4tagger"
FFMPEG = "/usr/local/bin/ffmpeg"
MAX_WIDTH = 1280
MAX_HEIGHT = 720
MAX_FPS = 25

if ENV["_"] =~ /macruby/
   #check if macruby and add in icon changing extras
   BINARY = "macruby"
   puts "Running macruby".red
   #puts "Icon changing only suported with macruby".red
   framework "Cocoa"
   framework 'Foundation'
else
   #puts "Icon changing only suported with macruby".red
   BINARY = "ruby"
   puts "Running ruby".red
end

class OptparseExample
   def self.parse(args)
      # The options specified on the command line will be collected in *options*.
      # We set default values here.
      $options = {}
      $options[:time] = 0
      $options[:crf] = 22
      $options[:icon] = false
      $options[:iconpath] = nil
      $options[:debug] = false
      $options[:convert] = false
      $options[:write] = false
      $options[:parse] = false
      $options[:genre] = ""
      $options[:media_type] = "tv show"

      opts = OptionParser.new do |opts|
         opts.banner = "Usage: convert.rb [options]"
         opts.separator ""
         opts.separator "Specific options:"

         # Cast 'delay' argument to a Float.
         opts.on("-t", "--time N", Float, "Process a given number of frames") do |n|
            $options[:time] = n.to_i
         end

         # Set new icon.
         opts.on("-i", "--icon", "Set new icon") do |n|
            $options[:icon] = true
         end
         
         # Set new icon path
         opts.on("--iconpath=MANDATORY", "Set new icon path") do |iconpath|
            $options[:iconpath] = iconpath.to_s
            #$options.iconpath = iconpath.to_s
         end

         # Set debug.
         opts.on("-d", "--debug", "Set debug") do |n|
            $options[:debug] = true
         end

         # Set genre.
         opts.on("-g", "--genre GENRE", "Genre") do |g|
            $options[:genre] = g.to_s
         end

         # Set media type to movie
         opts.on("-m", "--movie", "Movie") do |m|
            if m == true
               $options[:media_type] = "movie"
            end
         end

         # Parse the filename
         opts.on("-p", "--parse", "Parse the filename") do |c|
            $options[:parse] = true
         end

         # Set convert
         opts.on("-c", "--convert", "Convert") do |c|
            $options[:convert] = true
         end

         # Write
         opts.on("-w", "--write", "Write") do |w|
            $options[:write] = true
         end

         # Set crf
         opts.on("--crf [CRF]", Float, "Enter CRF (lower number for higher quality") do |crf|
            $options[:crf] = crf.to_i
         end

         opts.separator ""
         opts.separator "Common options:"

         # No argument, shows at tail.  This will print an options summary.
         # Try it and see!
         opts.on("-h", "--help", "Show this message") do
            puts opts
            exit
         end
      end #OptsParser
      opts.parse!(args)
      $options

   end  # parse()

end  # class OptparseExample

class Videofile
   #:section: Videofile Info
   #file variables
   attr_accessor :dir, :file_ext, :file_base, :file_path, :the_file
   
   #mediainfo variables
   attr_accessor :aspect, :fps, :rate, :width, :height, :duration
   
   attr_accessor :current_time, :secs
   # parsed media details
   attr_accessor :parsed_tags, :vid
   attr_accessor :genre, :content_rating, :artwork, :mediakind, :pep, :pse, :pepn, :psen, :name

   #testing variables
   attr_accessor :mediainfovars
   #mediainfovars = Hash.new
   #mediainfovars.rate = 0
   
 
   
   
   def initialize(the_file)
      begin
         if isFFmpegVideo?(the_file)
            @vid = Hash.new
            @mediaInfoVars = Hash.new
            @mediaInfoVars.default = 0
            @metaVars = Hash.new
            @metaVars.default = "empty"
            @mp4InfoVars = Hash.new
            @mp4InfoVars.default ="empty"
            
            
            @parsed_tags = Hash.new
            @mediakind = ""
            @file_ext = File.extname(the_file)

            @dir = File.dirname("#{File.absolute_path(the_file)}")
            @the_file = the_file
            @file_path = File.path(the_file)
            @file_base = File.basename(the_file, File.extname(the_file))

            @duration = 0
            @width = 0
            @height = 0
            @current_time = 0
            self.changedir
            self.parse_file_name
            self.my_mediainfo

            return self
         else
            raise ArgumentError, "#{the_file} is not a valid file for ffmpeg."
         end
      end
   end

   def isFFmpegVideo?(the_file)
      # checks if file can be processed by ffmpeg
      allowed = [".mp4", ".mp4", ".avi", ".flv", ".mkv", ".rmvb", ".m4v", ".mov", ".mpg", ".m1v", ".divx" ]
      allowed.include?(File.extname(the_file)) ? true : false
   end
  
   def ismp4?
      allowed = [".mp4", ".mp4", ".mkv", ".m4v" ]
      allowed.include?(@file_ext)
   end

   def method_missing (method_name, *args, &block  )
      puts "#{self.class} has no method called '#{method_name}'"
     require "#{File.dirname(__FILE__)}/constants"
   end

   def changedir
      # puts self.dir
      Dir.chdir(@dir)
   end

   def parse_file_name
      # ap @file_base.match(/^(?<seriesName>.+)\.s(?<seriesno>\d+)e(?<episodeno>\d+)\.(?<episodeName>.+)$/)
      # ap @file_base.match(/^(?<seriesName>.+)\.s(?<seriesno>\d+)e(?<episodeno>\d+)$/)
      # ap @file_base.match(/^(?<seriesName>.+)\.(?<episodeName>.+)$/)
      # ap @file_base.match(/^(?<seriesName>.+)$/)
      # puts __LINE__
      case
      when @file_base.match(/^(.+)\.s(\d+)e(\d+)\.(.+)$/)
         @psen = $2.to_s
         @pepn = $3.to_s
         @pse = $1.to_s
         #@pep = $4.to_s
         @name = $4.to_s
         @pep = "#{@pse}.s#{@psen}e#{@pepn}.#{@name}"
         #puts "#{@pse}  #{@pep}  #{@psen}  #{@pepn} name #{@name}"
      when @file_base.match(/^(.+)\.s(\d+)e(\d+)$/)
         @psen = $2.to_s
         @pepn = $3.to_s
         @pse = $1.to_s
         #@pep = "Episode #{$3.to_s}"
         @name = "Episode #{$3.to_s}"
         @pep = "#{@pse}.s#{@psen}e#{@pepn}.#{@name}"
         #puts "#{@pse}  #{@pep}  #{@psen}  #{@pepn} name #{@name}"
      when @file_base.match(/^(.+)\.(.+)$/)
         @psen = ""
         @pepn = ""
         @pse = $1.to_s
         #@pep = $2.to_s
         @name = $2.to_s
         @pep = "#{@pse}.#{@name}"
      when @file_base.match(/^(.+)$/)
         #puts "MOVIE"
         @psen = ""
         @pepn = ""
         @pse = $1.to_s
         #@pep = $1.to_s
         @name = $1.to_s
         @pep = $1.to_s
      end
      if $options[:debug] == true
          print "series>%s, season no>%s, episode no>%s, episode id>%s, name>%s\n" % [@pse, @psen, @pepn, @pep, @name]
      end
      #@pse -- parsed series name    @psen -- parsed series number     @pep -- parsed episode name    @name -- parsed episode name
   end

   def has_artwork
      the_art = %x{#{MP4TAGGER} -i "#{self.the_file}" -t}
      if the_art =~ %r|Artwork: File contains artwork|
         @artwork = "Y"
      end
   end

   def change_artwork
      
      list = Dir.entries(self.dir)
      images = [".jpg", ".png", ".jpeg"]
      choice = []
      user_choice = 0
      artwork_path = ""

      list.each do |line|
         if images.include?(File.extname(line))
            choice << line
         end
      end

      puts "Choose image to use for cover art:"
      choice.each_with_index {|item, index| puts "\t#{index} #{item}"}
      $stdout.flush
      $stdin.sync = true
      user_choice = $stdin.gets.chomp.to_i
      $stdout.flush
      artwork_path = choice[user_choice].to_s
      puts "Setting icon on #{videofile.file_base}#{videofile.file_ext} to #{artwork_path}"

      if BINARY == "macruby"
         NSWorkspace.sharedWorkspace.setIcon(NSImage.alloc.initWithContentsOfFile(artwork_path), forFile:videofile.the_file, options:0)
      end
   end

   def my_mediainfo
      @mi = Hash.new

      
      wanted = ["display_aspect_ratio", "complete_name", "frame_rate", "overall_bit_rate", "height", "width", "duration",
      "cover", "tvsh", "tven", "tvsn", "tves", "hdvd", "stik", "rtng", "genre", "complete_name" ]
      
      wantedMediaInfoVars = ["display_aspect_ratio", "frame_rate", "overall_bit_rate", "height", "width", "duration" ]
      wantedMetaVars = [ "cover", "tvsh", "tven", "tvsn", "tves", "hdvd", "stik", "rtng", "genre", "complete_name" ]
      
      shell = %x|/usr/local/bin/mediainfo "#{@the_file}"|

      shell.split("\n").each do |line|
         if line.include?(" : ") && line.split(" : ").count == 2
            parts = line.split(" : ")
            thesym = parts[0].downcase.chomp.strip.gsub(" ", "_").gsub(%r{[,|(|)|*|/]}, "").to_s
            # puts "checking " + thesym
            #puts parts[0].downcase.chomp.strip.gsub(" ", "_").gsub(%r{[,|(|)|*|/]}, "").to_s
            
            if wanted.include?("#{thesym}")
               self.instance_variable_set("@#{thesym.to_s}", parts[1].chomp.strip.to_s)
            end
            
            if wantedMediaInfoVars.include?("#{thesym}")
               @mediaInfoVars["#{thesym.to_s}"] = parts[1].chomp.strip.to_s
            end
            
            if wantedMetaVars.include?("#{thesym}")
               @metaVars["#{thesym.to_s}"] = parts[1].chomp.strip.to_s
            end
          end
      end
      # ap self, indent => -10
 

      #run mp4info if my ismp4? returns true
      if ismp4? == true
      wanted = ["tv show", "tv episode", "tv season", "name", "genre", "tv episode number"]
      shell = %x|/usr/local/bin/mp4info "#{@the_file}"|
      shell.split("\n").each do |line|
        if line.include?(": ")
          parts = line.split(": ")
          
          if wanted.include?(parts[0].downcase.chomp.strip)
            thesymp = parts[0].downcase.chomp.strip.gsub(%r{ }, "_")
            #Here we check if the data for a line from mp4info is nil. If it is, set the string as "", else the chomp will fail
            parts[1].nil? ? parts[1] = "" : nil
            thesym = "#{thesymp}".to_s

            
            @mp4InfoVars["#{thesym.to_s}"] = parts[1].chomp.strip
            
            self.instance_variable_set("@#{thesym.to_s}", parts[1].chomp.strip)
          end
        end
      end
      
      #ap @mediaInfoVars
      #ap @metaVars
      #ap @mp4InfoVars
      
    end
 
 
   end

   def height
      # @height = @height.to_s[/\d+/]
      @mediaInfoVars["height"].to_s[/\d+\s?\d+/].gsub(" ", "")
      #@height.to_s[/\d+/]
   end
   
   def width
      #@width = @width.to_s[/\d+\s?\d+/].gsub(" ", "")
      @mediaInfoVars["width"].to_s[/\d+\s?\d+/].gsub(" ", "")
      
   end
   
   def duration
      # in seconds
      hrs = @mediaInfoVars["duration"].to_s[/\d+(?=h)/]
      min = @mediaInfoVars["duration"].to_s[/\d+(?=mn)/]
      sec = @mediaInfoVars["duration"].to_s[/\d+(?=s)/]
      # puts "#{hrs} #{min} #{sec}"
      ((hrs.to_f * 60 * 60) + (min.to_f * 60) + sec.to_f).to_i
   end
   
   def secs
      if $options[:time]
         @secs = $options[:time]
      else
         @secs = @duration
      end
   end   

  

   def rate
      @mediaInfoVars["overall_bit_rate"].to_s[/\d+.\d+/].gsub(" ", "")
   end

   def fps
      @mediaInfoVars["frame_rate"].to_s[/\d+\.\d\d/]
   end

   def aspect
      @mediaInfoVars["display_aspect_ratio"].to_s.chomp.strip
   end

   def genre     
      if @metaVars["rtng"].to_s == "4"
         #ADD marker for explicit
         "*" + @mp4InfoVars["genre"].to_s
      else
         @mp4InfoVars["genre"].to_s
      end
   end

   def type
      @metaVars["stik"] == "10" ? @type = "TV Show" : @type = "Movie"
   end

   def artwork
      @metaVars["cover"] == "Yes" ? @artwork = "Yes" : @artwork = "No"
   end

   def tv_show
      @metaVars["tvsh"]
   end

   def tv_season
      @metaVars["tvsn"]
   end

   def tv_episode_no
      @metaVars["tves"]
   end

   def tv_episode_id
     @metaVars["tven"]
   end
   
   def parsed_info
     @parsedShow + ".s" + @parsedSeason + "e" + @parsedEpisode + "." + @parsedName
   end
   
   def parsedShow
     @mp4InfoVars["tv_show"].nil? == true ? @parsedShow = "empty" : @mp4InfoVars["tv_show"]
   end
   
   def parsedSeason
     @mp4InfoVars["tv_season"].nil? == true ? @parsedSeason = "00" : @mp4InfoVars["tv_season"]
   end
   
   def parsedEpisode
     @mp4InfoVars["tv_episode"].nil? == true ? @parsedEpisode = "00" : @mp4InfoVars["tv_episode"]  
   end
   
   def parsedEpisodeID
     @mp4InfoVars["tv_episode_number"].nil? == true ? @mp4InfoVars["name"] : @mp4InfoVars["tv_episode_number"]  
     
   end
   
   def parsedName
     @mp4InfoVars["name"].nil? == true ? @parsedName = "empty" : @mp4InfoVars["name"]
   end
end

class Ffmpeg_process
   attr_reader :cmd, :out, :timer, :duration, :time, :percent_done, :chart, :progress, :mypid
   def initialize(videofile, time, crf, options)
      @duration = videofile.duration
      @time = time
      @crf = crf
      @percent_done = 0
      @progress = @out = @chart = @mypid = nil
      $options = options
      return self
   end

   def setup(videofile)
      ffmpeg = Array.new
      if File.exists?(Dir.getwd + "/convert#{@time.to_s}#{@crf.to_s}") == false
         Dir.mkdir(Dir.getwd + "/convert#{@time.to_s}#{@crf.to_s}",  0700)
      end

      # Check if over writing an existing file
      i = 1
      new_file = "./convert#{@time.to_s}#{@crf.to_s}/#{videofile.file_base}"
      while File.exists?("#{new_file}.mp4") == true
         new_file = "./convert#{@time.to_s}#{@crf.to_s}/#{videofile.file_base}-#{i.to_s}"
         i = i + 1
      end

      framerate = videofile.fps.to_s
      videofile.width.to_i > MAX_WIDTH ? newwidth = MAX_WIDTH : newwidth = videofile.width
      videofile.height.to_i > MAX_HEIGHT ? newheight = MAX_HEIGHT : newheight = videofile.height
      @aspect = ( newwidth.to_f/newheight.to_f )
      ffmpeg << "#{FFMPEG}"
      # puts "time #{time}"
      ffmpeg << "-y"
      if @time > 0
         ffmpeg << "-ss 500 -t #{@time.to_s}"
      end
      ffmpeg << %Q[-i "#{videofile.the_file}"]
      ffmpeg << %Q[-acodec libfaac]
      ffmpeg << %Q[-ab 128k]
      ffmpeg << %Q[-ar 48000]
      ffmpeg << %Q[-ac 2]
      ffmpeg << %Q[-s #{newwidth}x#{newheight}]
      #ffmpeg << %Q[-s 640x480]
      #ffmpeg << %Q[-aspect #{videofile.aspect}]
      
      # ffmpeg << %Q[-aspect 1.333333]
      # ffmpeg << %Q[-s 544x576 -aspect 24:17]
      #ffmpeg << %Q[-filter delogo=x=56:y=46:w=70:h=49:band=4:show=0]

      ffmpeg << %Q[-vcodec libx264]
      ffmpeg << %Q[-preset faster]
      ffmpeg << %Q[-profile main]
      # ffmpeg << %Q[-preset medium]
      ffmpeg << %Q[-crf #{@crf.to_s}]
      # ffmpeg << %Q[-r #{framerate}]
      ffmpeg << %Q[-r 25]
      ffmpeg << %Q[-threads 0]
      ffmpeg << %Q["#{new_file}.mp4"]
      # ffmpeg << %Q[2>&1]
      # ffmpeg << '-b 950k'

      @cmd = ffmpeg.join(" ")
      #$options[:debug] == true ? err = @cmd.green : err = nil
      #puts err
      #{}`logger -i -t ffmpeg -p local0.info #{@cmd}`
      if $options[:debug] == true
         print " \nVideo to be sized at %d x %d at aspect ratio of %s\n%s\n" % [ newwidth, newheight, videofile.aspect.to_s, @cmd.green]
      end
   end

   def start()
     if $options[:debug] == true
       puts "time is #{@time}"
     end

     if @time > 0 then
         # override duration if only part of file is being done
         #duration is now taken from the initalisation of the videofile object
         #no need to do from ffmpeg bits
         @duration = @time
         puts "#{@time}s to process"
      end
      @timer = Thread.new{
         Open3.popen3(@cmd) do |stdin, stdout, stderr|
            @mypid == nil ? @mypid = Process.pid : nil
            #yield(0.0) if block_given?
            stderr.each("\r") do |line|
               if line =~ %r|time=(\d\d):(\d\d):(\d\d).\d\d bitrate|
                  # ap $~
                  # number of seconds done
                  @complete = (($1.to_f * 60 * 60) + ($2.to_f * 60) + $3.to_f).to_i
                  # percentage done
                  @complete.integer? ? @complete = @complete : @complete = 0

                  @percent_done = ((@complete.to_f / @duration.to_f) * 100)
                  #puts "@complete #{@complete} @duration #{@duration}"
                  #puts "@percent_done #{@percent_done.to_i}"
                  
                  #@duration > 0 ? @percent_done = ((@complete.to_f / @duration.to_f) * 100) : @percent_done = 0
               end
            end
         end
      }
   end

   def progress
      print "%-8s \t %8d / %-8d\r" % [ "#{@percent_done.to_i}%", @complete.to_i, @duration.to_i ]
   end

   def chart
      #interval if 0-100% split into 20 blocks, so at 50% we want 10 blocks, 100% - 20 blocks
      #so we divide percentage by 20 to get the display number
      # 100-0 / 50 => each block is 2%
      dis_done = (@percent_done/2).to_i
      dis_os = 50 - dis_done
      display_array = []
      dis_done.times { display_array << "◾" }
      dis_os.times { display_array << "◽" }
      display_string = "[ #{display_array * ""} ]"
      print "%-8s \t %8d / %-8d \t %-54s \t pid▸%s\r" % [ "#{@percent_done.to_i}%", @complete.to_i, @duration.to_i, display_string, @mypid ]
      # print "%-54s \t pid▸%s\r" % [ display_string, @mypid ]
   end
end

def print_fixed_width(command)
   words = command.split(" ")
   command = ""
   count = 0
   words.each do |word|
      count = count + word.length
      if count >= 70 then
         command = "#{command} #{word}\n"
         count = 0
      else
         command = "#{command} #{word}"
      end
   end
   puts command
end

def line_divider
   display_line = []
   count = `tput cols`.chomp.to_i
   (count-4).times { display_line << "-" }
   display_string = "[ #{display_line * ""} ]"
   puts display_string
end

def write_tags(videofile)
   #ap videofile
   tags_command = []
   tags_command << "#{MP4TAGGER}"
   tags_command << %Q[-i "#{videofile.the_file}"]
   tags_command << "--media_kind='#{$options[:media_type]}'"
   #tags_command << %Q[--name="#{videofile.vid[:base]}"]
   $options[:genre] != "" ? tags_command << "--genre='#{$options[:genre]}'" : nil
   videofile.psen != nil ? tags_command << "--tv_season='#{videofile.psen}'" : nil
   videofile.psen != nil ? tags_command << "--disk_n='#{videofile.psen}'" : nil
   
   videofile.pepn != nil ? tags_command << "--tv_episode_n='#{videofile.pepn}'" : nil
   videofile.pepn != nil ? tags_command << "--track_n='#{videofile.pepn}'" : nil
   
   videofile.pep != nil ? tags_command << %Q[--tv_episode_id="#{videofile.pep}"] : tags_command << %Q[--tv_episode_id="#{videofile.file_base}"]
   videofile.pse != nil ? tags_command << %Q[--tv_show="#{videofile.pse}"] : tags_command << %Q[--tv_show="#{videofile.file_base}"]
   videofile.name != nil ? tags_command << %Q[--name="#{videofile.name}"] : tags_command << %Q[--name="#{videofile.file_base}"]

   if $options[:genre] == "Porn"
      tags_command << "--content_rating='Explicit'"
   else
      tags_command << "--content_rating='Clean'"
   end

   tags_command << "-o"
   # line_divider
   command = tags_command.join(" ")
   if $options[:debug] == true
     print "%s\n" % [ command ]
   end
   #puts %x|command|
   # puts rewrite
   
   IO.popen(command) do |mi|
      puts mi
   end
   
   # IO.popen(tags_command.join(" "))
   line_divider
end

def artwork(artwork_path, videofile)
   if !artwork_path.nil?
      #Delete the old art
      existing_art = []
      the_art = %x{#{MP4TAGGER} -i "#{videofile.the_file}" -t}
      if the_art =~ %r|Artwork: File contains artwork|
         puts "File has art already, deleting"
         %x[/usr/local/bin/mp4art --remove "#{videofile.the_file}"]
      end
      Thread.new {|| %x[#{MP4TAGGER} -i "#{videofile.the_file}" --artwork "#{artwork_path}"]}.join

      if BINARY == "macruby"
         puts "Setting icon on #{videofile.file_base}#{videofile.file_ext} to #{artwork_path}"
         full_icon_path = "#{Dir.getwd}/#{artwork_path}"
         NSWorkspace.sharedWorkspace.setIcon(NSImage.alloc.initWithContentsOfFile(full_icon_path), forFile:videofile.the_file, options:0)
      end
   end
end

def check_extension(the_ext)
   allowed = [".mp4", ".mp4", ".avi", ".flv", ".mkv", ".rmvb", ".m4v", ".mov", "mpg", "m1v", "divx" ]
   allowed.include?(the_ext)
end

def check_mp4(the_ext)
   allowed = [".mp4", ".mp4", ".mkv", ".m4v" ]
   allowed.include?(the_ext)
end


begin
   raise StandardError, "You must choose some files" unless ARGV.count > 0
   timing = Benchmark.measure do
      $options = OptparseExample.parse(ARGV)
      results = Terminal::Table.new(:headings => ['          ', 'Art', 'type', 'genre', 'Time', 'W', 'H', 'fps', 'rate', 'S#', 'E#', 'Show', 'Name', 'Episode ID' ])
      results.style = {:border_x => "─", :border_y => "▏", :border_i => "─"} # _x horiz, _y vert, _i join
      ARGV.each do |the_file|
         begin
         @start = Time.now
         # checks the extension to see if it is a valid video file
         videofile = Videofile.new("#{the_file}")
         raise ArgumentError, "#{the_file} is not a valid file for ffmpeg." unless videofile.isFFmpegVideo?(the_file)
         case
         when $options[:convert] == true
            line_divider
            ffmpeg = Ffmpeg_process.new(videofile, $options[:time], $options[:crf], $options)
            ffmpeg.setup(videofile)
            ffmpeg.start()
            #puts ffmpeg.timer.alive?
            while ffmpeg.timer.alive? == true
               ffmpeg.chart
               sleep 2
            end
         when $options[:write] == true
            write_tags(videofile)
            videofile.my_mediainfo
         when $options[:icon] == true
            puts "$options[:iconpath] #{$options[:iconpath]}"
            #puts "$options.iconpath #{$options.iconpath}"

            
            if BINARY == "macruby"
              #Checks if user entered a predefined artwork path, if not a directory listing is presented
              if $options[:iconpath] == nil
                choice = []
                user_choice = 0
                artwork_path = ""
                Dir.entries(videofile.dir).each do |line|
                   [".jpg", ".png", ".jpeg"].include?(File.extname(line)) ? choice << line : nil
                end
                puts "#{videofile.file_base} => choose image for cover art:"
                choice.each_with_index {|item, index| puts "\t#{index} #{item}"}
                user_choice = $stdin.gets.chomp.to_i
                artwork_path = choice[user_choice].to_s
              else
                artwork_path = $options[:iconpath].to_s
              end
              
              #Then the path is passed to the artwork change method
               artwork(artwork_path, videofile)
               videofile.my_mediainfo
            else
               line_divider
               puts "Icon changing only possible with macruby"
               line_divider
            end
         else
            nil
         end
         # results.add_row [{:value => "#{the_file}", :colspan => 11}]
         # results << [ videofile.artwork, videofile.type, videofile.genre, videofile.duration, videofile.width, videofile.height, videofile.fps, videofile.rate, videofile.tv_season, videofile.tv_episode_no, videofile.tv_show, videofile.tv_episode_id ]
         # results << [ '',"%0.2fs" % [Time.now - @start],'','','','','','', videofile.psen, videofile.pepn, videofile.pse, videofile.pep]
         
         if $options[:parse] == true
           #only print the information contained in the file
           results << [ 'mp4info', videofile.artwork, videofile.type, videofile.genre, videofile.duration, videofile.width, videofile.height, videofile.fps, videofile.rate, videofile.parsedSeason, videofile.parsedEpisode, videofile.parsedShow, videofile.parsedName, videofile.parsedEpisodeID ]
           #the_file = ARGV.last ? results.add_separator : nil
         else
           #print the information contained in the file AND the parsed info from the filename
           
           results << [ 'mp4info', videofile.artwork, videofile.type, videofile.genre, videofile.duration, videofile.width, videofile.height, videofile.fps, videofile.rate, videofile.parsedSeason, videofile.parsedEpisode, videofile.parsedShow, videofile.parsedName, videofile.parsedEpisodeID ]
           results << [ 'to write', '',"%0.2fs" % [Time.now - @start],'','','','','','', videofile.psen, videofile.pepn, videofile.pse, videofile.name, videofile.pep]
           the_file != ARGV.last ? results.add_separator : nil
         end   
         
         
         logcmd = "#{the_file} - #{Time.now - @start}s - crf #{$options[:crf]} - t #{$options[:time]}s - duration #{videofile.duration}s"
         `logger -i -t ffmpeg -p local0.info "#{logcmd}"`
         #end #check_extension
         rescue ArgumentError => msg
            puts msg
            next
         end
      end #ARGV loop
      puts results
   end #timing
   puts timing
rescue StandardError => msg
   print "%s\n" % [msg.to_s.green]
   exit 1
rescue Interrupt => msg
   msg = "Conversion ended"
   print "\n%s\n" % [msg]
end



=begin

rescue ArgumentError   # => msg
   #next
   print "\n%s\n" % [msg]
rescue StandardError # => msg
   next
   #puts "/n"
   #ap msg.backtrace
   print "\n%s\n" % [msg]
   return
   
   # display the system generated error message
   puts $ERROR_POSITION
   #puts $ERROR_INFO
   #require "#{File.dirname(__FILE__)}/constants"
   exit 1
rescue Interrupt => msg
   msg = "Conversion ended"
   print "\n%s\n" % [msg]
end #begin
=end