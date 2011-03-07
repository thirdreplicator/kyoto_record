# USAGE
# rake bump:ver
# rake push
# rake ver

def ver(column)
  # column can be :major, :minor, or :maint
  f = File.read('kyoto_record.gemspec')
  cid = {:major => 1, :minor => 2, :maint=> 3}
  value = 0
  f.each_line do |line|
    if line.match(/s\.version/)
      match = line.match(/"(\d+)\.(\d+)\.(\d+)"/)
      value = match[cid[column]].to_i 
    end
  end
  value
end

def whole_version
  "#{ver(:major)}.#{ver(:minor)}.#{ver(:maint)}"
end

def new_version(column)
  val = {}
  new_version = ""
  [:major, :minor, :maint].each do |k|
    val[k] = ver(k)
    val[k] += 1 if k==column 
    new_version += "#{val[k]}."
  end
  new_version.chop
end

def bump_ver(col)
  old = whole_version
  new = new_version(col)
  puts "New version of gem:#{new}"
  body = File.read('kyoto_record.gemspec')
  new_body = body.gsub(/#{old}/, new)
  File.open('kyoto_record.gemspec', 'w') {|f| f.write(new_body) }
end

task :ver do
  puts "Current gem version: #{whole_version}"
end


namespace :bump do
  task :maint do
    bump_ver(:maint)
  end

  task :minor do
    bump_ver(:minor)
  end

  task :major do
    bump_ver(:major)
  end
 
  task :ver => :maint
end

task :clean do
  puts "Removing old gems."
  `rm *.gem`
end

task :build_gem => :clean do
  puts "Building latest gem."
  `gem build *.gemspec`
end

task :push => :build_gem do
  puts "Pushing latest gem."
  `gem push *.gem`
end

