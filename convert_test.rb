#!/usr/local/bin/ruby
# coding: ISO-8859-1
# Created by cdavies on 2012-04-17.
# untitled
# system("clear")

#require 'rubygems'
#require 'awesome_print'
# require 'minitest/spec'
# require 'minitest/autorun'



class TestVideofile < MiniTest::Unit::TestCase
  attr_accessor :video
  def setup
    the_files = ["/Volumes/WD/XTorrent/Complete/Porn/avi/Catalina.Black Wishes.mp4", 
      "/Volumes/iTunes/iTunes/TV Shows/Golden Girls/Season 4/Golden Girls.s4e2.The Days and Nights of Sophia Petrillo.mp4"]
    the_files = ["/Volumes/iTunes/iTunes/TV Shows/Golden Girls/Season 4/Golden Girls.s4e2.The Days and Nights of Sophia Petrillo.mp4"]
    
    the_files.each do |the_file|
      @video = Videofile.new(the_file)
      
      describe @video do
        it "can be created with a specific size" do
          @video.must_be_instance_of Videofile
        end
      end
      
    end
  end
  def test_default_is_zero
    assert_equal 0, @video.current_time
  end
  
  def test_default_width
    assert_equal "640", @video.width
  end
  def test_default_height
    assert_equal "480", @video.height
  end  
  def test_default_duration
    #1hr 48m
    #assert_equal 5280, @video.duration
    assert_equal 1449, @video.duration
  end

  puts @video
  
end


# describe Videofile do
#   it "can be created with a specific size" do
#     Videofile.new(ARGV).must_be_instance_of Videofile
#   end
# end