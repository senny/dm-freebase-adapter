require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Artist
  include DataMapper::Resource

  property :id, String, :key => true
  property :album, String
  property :genre, String
  property :label, String

  storage_names[:default] = '/music/artist'
end

describe "FreebaseAdapter" do

  it "should" do
    puts Artist.get('/en/paul_kalkbrenner').inspect
  end

end
