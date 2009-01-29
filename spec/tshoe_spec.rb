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
end

describe "Tshoe linkparse" do
  include TshoeSpecHelper

  before(:each) do
    setup_tshoe
  end

  it "should parse normal text" do
    text = "normal twit text."

    @tshoe.linkparse( text ).should == "\"#{text}\""
  end

  it "should parse an isolated hyperlink" do
    @tshoe.linkparse( "Go here: http://www.google.com" ).should == "\"Go \", \"here: \", #{generate_link('http://www.google.com')}"
  end
end
