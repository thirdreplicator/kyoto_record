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

  it "should have a globally configurable data directory" do
    KyotoRecord::DATA_DIR = '/tmp/kr'  
    class B
      include KyotoRecord
      attr_kyoto :x
    end
    File.exist?('/tmp/kr/B.kch').should be_true
    `rm -rf /tmp/kr`                   # Clean up.
    KyotoRecord::DATA_DIR = './data'   # Revert global config back to normal.
  end
  
  it "find should return an instance of the enhanced user-defined class" do
    @a = A.new
    @a.x = 3
    @a.save
    A.find(1).should be_an_instance_of(A)
  end

  it "should have an id after being saved." do
    @a = A.new
    @a.x = 3
    @a.save
    @a.id.should == 1
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

  it "should be able to save 2 different objects using the same variable" do
    a = A.new
    a.x = "David"
    a.save

    a = A.new
    a.x = "Bob"
    a.save

    A.find(1).x.should == "David"      
    A.find(1).id.should == 1
    A.find(2).x.should == "Bob"      
    A.find(2).id.should == 2
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
      # Insert some records
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
  describe "DELETE functionality" do
    it "should be able to delete records by key (class utility function)" do
      a = A.new
      a.username = "David"
      a.save
      A.find(1).should_not be_nil
      A.delete(1)
      A.find(1).should be_nil
    end

    it "should be able to delete records by key (instance method)" do
      a = A.new
      a.username = "David"
      a.save
      A.find(1).should_not be_nil
      a.delete
      A.find(1).should be_nil
    end
  end

  describe "UPDATE functionality" do
    it "should be able to update just by saving over the existing one." do
      a = A.new
      a.username = "David"
      a.save

      # Loop him up.
      a1 = A.find(1)
      a1.username.should == "David"

      # Modify him.
      a1.username = "Bob"
      a1.save

      # Make sure he changed.
      A.find(1).username.should == "Bob"
    end

    it "should be able to update with a instance method." do
      a = A.new
      a.username = "David"
      a.save

      A.find(1).update(:username, "Bob")
      A.find(1).username.should == "Bob"  
    end

    it "should be able to batch update by scanning over a range of ids." do
      10.times do |i|
        a = A.new
        a.username = i+1
        a.save
      end

      A.scan(1,5) do |a|
        a.update(:username, "Anonymous")
      end

      A.find(1).username.should  == "Anonymous"
      A.find(3).username.should  == "Anonymous"
      A.find(5).username.should  == "Anonymous"
      A.find(6).username.should  == 6
      A.find(7).username.should  == 7
      A.find(10).username.should == 10
    end
  end

  describe "DROP the whole database" do
    it "should be able to drop the whole database." do
      a = A.new
      a.username = "David"
      a.save

      a = A.new
      a.username = "Bob"
      a.save

      A.find(1).username.should == "David"
      A.find(2).username.should == "Bob"

      A.delete_all

      A.find(1).should be_nil
      A.find(2).should be_nil
    end  

    it "should be able to add more items after the database was dropped." do
      a = A.new
      a.username = "David"
      a.save

      A.find(1).username.should == "David"

      A.delete_all

      b = A.new
      b.username = "Duck"
      b.id.should be_nil
      b.save

      b.id.should == 2
      A.find(2).should_not be_nil
    end
  end

  describe "Auxilliary functions" do
    it "should be able to know it's own name as a string" do
      A.class_name
    end
  end
end
