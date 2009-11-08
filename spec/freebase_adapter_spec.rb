
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Artist
  include DataMapper::Resource

  storage_names[:default] = '/music/artist'

  property :id, String, :key => true
  property :guid, String
  property :name, String
  property :genre, String
  property :label, String

  has n, :albums, :child_key => [:artist]
end

class Album
  include DataMapper::Resource

  storage_names[:default] = '/music/album'

  property :id, String, :key => true
  property :name, String
  property :track, String
  property :release_date, Date

  belongs_to :artist, :child_key => [:artist]
end

describe "FreebaseAdapter" do

  it "should fetch the given properties" do
    artist = Artist.get('/en/paul_kalkbrenner')
    artist.name.should == "Paul Kalkbrenner"
    artist.genre.should_not be_empty
  end

  it "should fetch one-to-many associations on demand" do
    artist = Artist.get('/en/apparat')
    artist.albums.size.should > 0
    titles = artist.albums.collect(&:name)
    ["Silizium EP", "Walls"].each do |title|
      titles.should include(title)
    end
  end

  it "should fetch belongs_to associations" do
    album = Album.get('/guid/9202a8c04000641f800000000345ef66')
    pending("belongs_to associations are not working right now")
  end

  it "should sort the result ascending" do
    albums = Album.all(:name => "Balance", :order => [:release_date.asc])
    dates = albums.collect(&:release_date).compact
    dates.should == dates.sort
  end

  it "should sort the result descending" do
    albums = Album.all(:name => "Balance", :order => [:release_date.desc])
    dates = albums.collect(&:release_date).compact
    dates.should == dates.sort.reverse
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
