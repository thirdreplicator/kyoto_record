$: << File.dirname(__FILE__)

require 'rspec'
require 'kyoto_record'

describe 'KyotoRecord module' do
  before(:each) do
    class A
      include KyotoRecord
      attr_kyoto :x
    end
  end

  after(:each) do
    `rm -rf ./data`
  end

  it "should have a database even if no instances were saved" do
    File.exist?('./data/A.kch').should be_true
  end

  it "should retrieve 3 if 3 was saved into a kyoto attribute" do
    @a = A.new
    @a.x = 3
    @a.save
    A.find(1).should be_an_instance_of(A)
  end

  it "should retrieve 3 if 3 was saved into a kyoto attribute" do
    @a = A.new
    @a.x = 3
    @a.save
    A.find(1).x.should == 3
  end

  it "should retrieve a symbol :abc if the symbol :abc was saved" do
    @a = A.new
    @a.x = :abc
    @a.save
    A.find(1).x.should == :abc
  end

  it "should be able to save arbitrary objects" do
    @a = A.new
    @a.x = Time.now
    @a.save
    A.find(1).x.should be_an_instance_of( Time )
  end

  it "should have a last_id of nil if nothing has been saved yet." do
    A.last_id.should == 0
  end

  it "should have a last_id of 1 if something has been saved." do
    @a = A.new
    @a.x = 1
    @a.save
    A.last_id.should == 1
  end

  it "should be able to set a particular value" do
    A.set_raw(:xyz, 999)
    A.get_raw(:xyz).should == "999" # Kyoto Cabinet only returns String or binary literals
  end

  it "should be able to find an instance by id" do
    # Create two instances, set x, then save them.
    
    @a = A.new
    @a.x = 100
    @a.save  

    @b = A.new
    @b.x = 200
    @b.save

    A.find(1).x.should == 100
    A.find(2).x.should == 200 
  end

  it "should be able to set multiple KC attributes at once." do
    class B
      include KyotoRecord
      attr_kyoto :x, :y, :z
    end
    b= B.new
    b.should respond_to(:x)
    b.should respond_to(:y)
    b.should respond_to(:z)
  end

  it "should be able to set those variables just like normal" do
    class B
      include KyotoRecord
      attr_kyoto :x, :y, :z
    end
    b= B.new
    b = B.new
    b.x = 5
    b.y = :abc
    b.z = "duck"
    b.save

    B.find(1).x.should == 5
    B.find(1).y.should == :abc 
    B.find(1).z.should == "duck" 
  end

  describe "Iterating over the records." do
    before(:each) do
      # Insert 100 records
      10.times do |i|
        a = A.new
        a.x = i+1
        a.save 
      end 
    end

    it "should be able to return a list of serialized objects" do
      word = ""
      A.scan do |z|
        word += z.x.to_s
      end
      word.should == "12345678910"
    end

    it "should be able to start from the 2nd record" do
      word = ""
      A.scan(5) do |z|
        word += z.x.to_s
      end
      word.should == "5678910"
    end

    it "should be able to stop after a given limit" do
      word = ""
      A.scan(2, 3) do |z|
        word += z.x.to_s
      end
      word.should == "234"
    end

    it "should be able to scan by page" do
      word = ""
      A.scan_page(3, 2) do |z|
        word += z.x.to_s
      end
      word.should == "56"
    end
  end
  describe "Indexing of attributes." do
    before(:each) do
      class A
        attr_kyoto :username
        index_kyoto :username
      end
    end

    it "should create a new database called './data/A_name.kch'" do
      File.exist?('./data/A_username.kch').should be_true
    end
 
    it "should be able to look up a record by attribute value" do
      a = A.new
      a.username = "David"
      a.save
      A.indices[:username].should be_a_kind_of(::KyotoRecord::Index)
      A.find_by_username("David").should be_a_kind_of( ::KyotoRecord )
      A.find_by_username("David").id.should == 1
      A.find_by_username("David").username.should == "David"
    end
  end

  describe "Auxilliary functions" do
    it "should be able to know it's own name as a string" do
      A.class_name
    end
  end
end
