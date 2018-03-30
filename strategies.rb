class S1
  def self.foo(bar)
    "#{bar}...1"
  end
end

class S2
  def self.foo(bar)
    "#{bar}...2"
  end
end

class S3
  def self.foo(bar)
    "#{bar}...3"
  end
end

class Thing
  def initialize
    @strategies = {
      "s1" => S1,
      "s2" => S2,
      "s3" => S3,
    }
  end

  def go(s, bar)
    @strategies[s].foo(bar)
  end
end

t = Thing.new
%w(s1 s2 s3).each do |s|
  puts "#{s}: #{t.go(s, "cats")}"
end