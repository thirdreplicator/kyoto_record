require 'kyotocabinet'

module KyotoRecord

  # Refactored out this module so that it can be reused in the class 'Index'
  #  as well as the module ClassMethds, which is directly enhancing the
  #  user-defined data model class.

  module Cabinet
    include KyotoCabinet

    def find(id)
      value = @db.get(id)
      if value
        obj = Marshal.load( @db.get(id) ) 
        obj.id = id
        obj
      end
    end

    def scan(start_key=nil, limit=1/0.0, &block)
      cur = @db.cursor
      i = 0 
      cur.jump(start_key)

      while (rec = cur.get(true)) && i < limit
        key = rec[0]
        if key != 'last_id'
          i += 1
          value = Marshal.load(rec[1])
          block.call(value)
        end
      end
      cur.disable
    end

    def scan_page(page, per_page=100, &block)
      @recs_per_page ||= per_page
      start_key = (page-1)*per_page + 1
      limit = per_page
      scan(start_key, limit, &block)
    end

    def get_attr(attr)
      value = Marshal.load( @db.get( attr ) ) if kc.get(attr)
      if value
        return value
      else
        STDERR.printf("get error: %s\n", kc.error)
        raise "Couldn't find value for attribute: #{attr}"
      end
    end

    # Utilities
    def open_db(base_name)
      Dir.mkdir('data') if !Dir.exists?('data')
      db = DB::new
      unless db.open("./data/#{base_name}.kch", DB::OWRITER | DB::OCREATE)
        STDERR.printf("open error: %s\n", db.error)
      end
      db
    end

    def close_db(base_name)
      unless @db.close
        STDERR.printf("close error: %s\n", db.error)
      end
    end
    
    # Utilities

    def set(k,v)
      @db.set(k, Marshal.dump(v))
    end

    def get(k)
      val = @db.get(k)
      Marshal.load(val) if val
    end

    def set_raw(k,v)
      @db.set(k,v)
    end

    def get_raw(k)
      @db.get(k)
    end

    def last_id
      get_raw(:last_id).to_i
    end

    def last_id=(i)
      set_raw(:last_id, i)
    end
 
    def class_name
      @class_name ||= self.to_s
    end
  end # Cabinet

  # Reuse the Cabinet module to make indexes of attributes.
  #  Each index is a Kyoto Cabinet index.  value -> id
  #  E.g. "David" -> 1
  # For a "username" attribute on the class User, the index would be in
  #  ./data/User_username.kch
  class Index
    include Cabinet
    attr_reader :klass, :attr, :base_name, :db

    def initialize(klass, attribute)
      @klass = klass
      @attr = attribute
      @base_name = klass.to_s + "_" + attribute.to_s
      @db = open_db(@base_name) 
    end
  end # class Index

  module ClassMethods
    # This is where attr_kyoto and index_kyoto go.
    include Cabinet

    def attr_kyoto( *attrs )
      @db = open_db(class_name)

      @attrs ||= {}
      @indices ||= {} 

      # Don't redefine it if it was already defined.
      if !self.respond_to?(:id)
        # a general setter
        define_method :set_attr do |k, v|
          @values[k] = v
        end
  
        # a general getter
        define_method :get_attr do |k|
          @values[k]
        end 
       
        def define_getter_and_setter(attr)
          define_method :"#{attr}".to_s do
            @values[attr]
          end
    
          define_method :"#{attr}=".to_s do |val|
            set_attr(attr, val)
          end
        end 

        define_getter_and_setter(:id)
      end # if

      # In case multiple attributes were passed in, let's loop over each one.
      attrs.each do |attr|
        define_getter_and_setter(attr)
      end
    end # attr_kyoto

    def index_kyoto( *attrs )
      attrs.each do |attr|
        @indices[attr] = Index.new(self, attr)
        singleton = class << self; self; end
        singleton.class_eval <<-EOM

          def find_by_#{attr}(val)
            self.find( @indices[\"#{attr}\".to_sym].get(val) )
          end
EOM
      end
    end

    def indices
      @indices
    end
  end # ClassMethods

  ###  Instance Methods  ###

  def self.included(base)
    base.extend(ClassMethods)
  end  
 
  def initialize
    @values ||= {}
    super
  end

  def save
    if !id
      # TODO: use KyotoCabinet::DB#increment
      id = self.class.last_id + 1
      self.class.last_id = id
    end

    write_indices(id)
    write_to_kyoto(id, self)
  end

  def write_indices(id)
    self.class.indices.each do |attr, index|
      index.set(@values[attr], id)
    end
  end

  def write_to_kyoto(k, v)
    set_error(k,v) unless self.class.set(k, v)
  end

  private

  def set_error(k,v)
    STDERR.printf("set error for (k,v)=(%s, %s): %s\n", k, v, kc.error)
  end

end


