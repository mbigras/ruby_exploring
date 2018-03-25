class C
  class << self
    def foo
      puts "hello!"
      yield self
    end

    def bar(s)
      puts "hello again!"
      send(s)
    end

    def flapjacks
      puts "hello only sometimes!"
    end

    def method_missing(name, *args, &block)
      puts "hello most all the time!"
    end
  end
end

C.foo do |c|
  c.bar :flapjacks
  c.bar :catdog
end