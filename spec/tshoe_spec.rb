=begin
    TwitterShoes
    tshoe_spec.rb
    ruby script created to be a Twitter (http://www.twitter.com) client,
    that uses Shoes.rb to be run on various platforms (Linux, MacOSX, Windows).
    Copyright (C) 2007, 2008 Pedro Mg <http://blog.tquadrado.com>
    Copyright (C) 2008 Terence Lee <hone02@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'spec/mocks'
require File.expand_path( File.join( File.dirname(__FILE__), 'spec_helper' ) )

# mock Shoes class
class Shoes
  class << self
    # not sure how to stub! with arguments
    def url( path, symbol )
    end
  end

  def debug( message )
  end
end

# stub class methods
Shoes.stub!(:setup)
Shoes.stub!(:app)

# need to mock Shoes before requiring lib/tshoe
require File.expand_path( File.join( File.dirname(__FILE__), '..', 'twittershoes' ) )
require_local 'lib/tshoe'

module TshoeSpecHelper
  def setup_tshoe
    # need to mock Twitter4r library
    @twitter_client = mock( "Twitter Client" )
    @twitter_client.stub!(:favorites).and_return( [] )
    @twitter_client.stub!(:timeline_for)
    Twitter::Client.stub!(:new).and_return( @twitter_client )

    @tshoe = TwitterShoes::Tshoe.new
    # stub the rest of the Shoes methods
    @tshoe.stub!(:clear)
    @tshoe.stub!(:background)
    @tshoe.stub!(:gutter)
    @tshoe.stub!(:flow)
    @tshoe.stub!(:stack)
    @tshoe.index
  end

  def generate_link( address )
    "link('#{address}', :click => '#{address}', :font => 'Arial', :size => 8, :underline => false, :stroke => '#397EAA' )"
  end

  def generate_username_link( username )
    @tshoe.generate_link( username, "http://www.twitter.com/#{username}" )
  end
end

describe TwitterShoes::Tshoe, "generate_link" do
end

describe TwitterShoes::Tshoe, "link_parse" do
  include TshoeSpecHelper

  before(:each) do
    setup_tshoe
  end

  it "should parse normal text" do
    text = "normal twit text."

    @tshoe.link_parse( text ).should == "\"#{text}\""
  end

  it "should parse an isolated hyperlink" do
    @tshoe.link_parse( "Go here: http://www.google.com sweet" ).should == "\"Go \", \"here: \", #{@tshoe.generate_link('http://www.google.com')}, \" \", \"sweet\""
  end

  it "should parse a link with surrounding parentheses" do
    @tshoe.link_parse( "Go here (http://www.google.com) sweet" ).should == "\"Go \", \"here \", \"(\", #{@tshoe.generate_link('http://www.google.com')}, \") \", \"sweet\""
  end

  it "should parse a link with a left parenethesis" do
    @tshoe.link_parse( "Go here (http://www.google.com sweet" ).should == "\"Go \", \"here \", \"(\", #{@tshoe.generate_link('http://www.google.com')}, \" \", \"sweet\""
  end

  # not sure if program should parse the ) or not
  it "should parse a link with a right parenthesis" do
    @tshoe.link_parse( "Go here http://www.google.com) sweet" ).should == "\"Go \", \"here \", #{@tshoe.generate_link('http://www.google.com)')}, \" \", \"sweet\""
  end

  it "should parse a url with single quotes" do
    @tshoe.link_parse( "Go here 'http://www.google.com' sweet" ).should == "\"Go \", \"here \", \"'\", #{@tshoe.generate_link('http://www.google.com')}, \"' \", \"sweet\""
  end

  it "should parse double quotes"

  it "should parse multiple urls"
end

describe TwitterShoes::Tshoe, "html_escape_parse" do
  include TshoeSpecHelper

  before(:each) do
    setup_tshoe
  end

  it "should parse <" do
    @tshoe.html_escape_parse( "5 &lt; 10" ).should == "5 < 10"
  end

  it "should parse >" do
    @tshoe.html_escape_parse( "10 &gt; 5" ).should == "10 > 5"
  end
end

describe TwitterShoes::Tshoe, "name_parse" do
  include TshoeSpecHelper

  before(:each) do
    setup_tshoe
  end

  it "should parse name at beginning of message" do
    @tshoe.name_parse( "\"@xxx what's up man?\"" ).should == "\"@\", #{generate_username_link( "xxx" )}, \" what's up man?\""
  end

  it "should parse name in the middle of a message" do
    @tshoe.name_parse( "\"hey @xxx what's up?\"" ).should == "\"hey @\", #{generate_username_link( "xxx" )}, \" what's up?\""
  end

  it "should parse name at the end of a message" do
    @tshoe.name_parse( "\"hey @xxx\"" ).should == "\"hey @\", #{generate_username_link( "xxx" )}"
  end

  it "should parse multiple names" do
    @tshoe.name_parse( "\"hey @xxx and @yyy and @zzz\"" ).should == "\"hey @\", #{generate_username_link( "xxx" )}, \" and @\", #{generate_username_link( "yyy" )}, \" and @\", #{generate_username_link( "zzz" )}"
  end

  it "should parse names separated by commas"

  it "should only parse name if preceded with @ symbol"
end
