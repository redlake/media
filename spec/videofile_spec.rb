#!/usr/local/bin/ruby
require 'spec_helper.rb'
require 'mediainfo'


describe Videofile do
  before :each do
    @videofile = Videofile.new("/Volumes/iTunes/BBC/How to Build.../How to Build....s02e01.A Super Jumbo Wing.mp4")
  end
  
  it 'should do something' do
      @fileBase.should == "How to Build....s02e01.A Super Jumbo Wing"
    end
end
