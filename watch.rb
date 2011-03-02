$: << File.dirname(__FILE__)

require 'directory_watcher'

command = 'rspec -c *_spec.rb'

dw = DirectoryWatcher.new '.', :pre_load => true, :scanner => :rev
dw.glob = '**/*.rb'
dw.reset true
dw.interval = 1.0
dw.stable = 1.0
dw.add_observer do |*args|
  args.each do |event|
    system(command) if event.to_s =~ /stable/
  end
end
dw.start
gets      # when the user hits "enter" the script will terminate
dw.stop

