require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Artist
  include DataMapper::Resource

  storage_names[:default] = '/music/artist'

  property :id, String, :key => true
  property :guid, String
  property :name, String
  property :genre, String

  has n, :albums, :child_key => [:artist]
end

class Album
  include DataMapper::Resource

  storage_names[:default] = '/music/album'

  property :id, String, :key => true
  property :name, String
  property :track, String

  belongs_to :artist, :child_key => [:artist]
end

describe "FreebaseAdapter" do

  it "should fetch the given properties" do
    artist = Artist.get('/en/paul_kalkbrenner')
    artist.name.should == "Paul Kalkbrenner"
    artist.genre.should_not be_empty
  end

  it "should fetch associations on demand" do
    artist = Artist.get('/en/apparat')
    artist.albums.size.should > 0
    titles = artist.albums.collect(&:name)
    ["Silizium EP", "Walls"].each do |title|
      titles.should include(title)
    end
  end

  it "should work with inclusion (in) queries" do
    results = Album.all(:name => ["Berlin Calling", "Balance 005: James Holden"])
    results.size.should == 2
    results[0].name.should == "Balance 005: James Holden"
    results[1].name.should == "Berlin Calling"
  end

  it "should work with like (regexp match) queries" do
    results = Album.all(:name.like => "Balance 00*")
    results.size.should > 0
    titles = results.collect(&:name)
    titles.each {|title| title.should =~ /^Balance 00.*$/}
  end

end
