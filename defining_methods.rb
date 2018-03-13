module C
  def foo
    puts "foo in self.class.superclass.included_modules.first=#{self.class.superclass.included_modules.first}"
  end
end

class A
  include C
  def foo
    puts "foo in self.class.superclass=#{self.class.superclass}"
    super
  end
end

class B < A
  def foo
    puts "foo in self.class=#{self.class}"
    super
  end
end

o = B.new

def o.foo
  puts "foo in self.singleton_class=#{self.singleton_class}, with def o.foo syntax"
  super
end

class << o
  def foo
    puts "foo in self.singleton_class=#{self.singleton_class}, with class << o syntax"
    super
  end
end

module M
  def foo
    puts "foo in self.singleton_class=#{self.singleton_class}, with o.instance_eval do, extend syntax"
    super
  end
end

o.instance_eval do
  extend M          # wow this is, not what I was expecting have to happen!
end                 # why does super call the the other instance_eval method?

o.foo
p o.class.included_modules
p o.singleton_class.included_modules

# foo in self.singleton_class=#<Class:#<B:0x00007f952400f788>>, with class << o syntax
# foo in self.singleton_class=#<Class:#<B:0x00007f952400f788>>, with o.instance_eval do, extend syntax
# foo in self.class=B
# foo in self.class.superclass=A
# foo in self.class.superclass.included_modules.first=C
# [C, Kernel]
# [M, C, Kernel]
# [Finished in 0.2s]