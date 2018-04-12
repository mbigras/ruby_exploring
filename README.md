# Ruby Exploring
>A collection of examples exploring the Ruby programming language

## Examples

* [Defining methods](#defining-methods)
* [Method arguments](#method-arguments)
* [Tap tap tap](#tap-tap-tap)
* [Strategy pattern](#strategy-pattern)
* [Exploring the Rake DSL](#exploring-the-rake-dsl)
* [Extending self](#extending-self)
* [The inherited hook](#the-inherited-hook)
* [Lazy autoload](#lazy-autoload)
* [The extended hook](#the-extended-hook)
* [What is class_eval](#what-is-class_eval)
* [A mess of hooks](#a-mess-of-hooks)
* [The class << object syntax](#the-class-<<-object-syntax)

## Defining methods

Insight: Calling `super` from a method defined in an object's singleton class will call a method in a module extended onto the same object's singleton class.

Example:

```
ruby <<EOF | tee /dev/tty | pbcopy
o = Object.new

def o.foo
	puts "foo in self.singleton_class #{self.singleton_class}"
	super
end

module M
	def foo
		puts "foo in self.singleton_class.included_modules #{self.singleton_class.included_modules}"
	end
end

o.instance_eval do
	extend M
end

o.foo
EOF
foo in self.singleton_class #<Class:#<Object:0x00007ffe9703ce40>>
foo in self.singleton_class.included_modules [M, Kernel]
```

Weird.

## Method arguments

Insight: Methods arguments can be gathered up in arrays and hashes

```
ruby <<EOF
def foo(*args, **opts, &blk)
	yield(args, opts) if block_given?
	42
end

foo('cats', 'and', 'dogs', whaa: 'in a tree', flaps: 'in a hat') do |args, opts|
	puts "#{args.first} #{opts[:whaa]}"
end

foo('cats', 'and', 'dogs', whaa: 'in a tree', flaps: 'in a hat') do |args, opts|
	puts "#{args.last} #{opts[:flaps]}"
end
EOF
cats in a tree
dogs in a hat
```

Outrageous.

## Tap tap tap

```
ri Object#tap
= Object#tap

(from ruby core)
------------------------------------------------------------------------------
  obj.tap {|x| block }    -> obj

------------------------------------------------------------------------------

Yields self to the block, and then returns self. The primary purpose of this
method is to "tap into" a method chain, in order to perform operations on
intermediate results within the chain.

  (1..10)                  .tap {|x| puts "original: #{x}" }
    .to_a                  .tap {|x| puts "array:    #{x}" }
    .select {|x| x.even? } .tap {|x| puts "evens:    #{x}" }
    .map {|x| x*x }        .tap {|x| puts "squares:  #{x}" }
```

The `"tap into"` quotes is what helped this concept click!

```
ruby <<EOF | tee /dev/tty | pbcopy
puts %w(foo bar baz)
.first
.upcase
.split("")      .tap { |e| puts "hello #{e}!"}
.map(&:to_sym)  .tap { |e| puts "hello #{e}!"}
.clear
EOF
hello ["F", "O", "O"]!
hello [:F, :O, :O]!
```

## Strategy pattern

Implement each strategy as a singleton method on a class, then inject all the required strategies

```
ruby <<EOF
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
EOF
s1: cats...1
s2: cats...2
s3: cats...3
```

## Exploring the Rake DSL

```
ruby <<EOF
def task(h)
  puts "I'm one argument: #{h.inspect}"
end

task({ "default" => ["cats", "dogs"]})
task "default" => ["cats", "dogs"]
task "default": ["cats", "dogs"]
task default: ["cats", "dogs"]
task default: [:cats, :dogs]
task :default => [:test, :features]
EOF
I'm one argument: {"default"=>["cats", "dogs"]}
I'm one argument: {"default"=>["cats", "dogs"]}
I'm one argument: {:default=>["cats", "dogs"]}
I'm one argument: {:default=>["cats", "dogs"]}
I'm one argument: {:default=>[:cats, :dogs]}
I'm one argument: {:default=>[:test, :features]}
```

## Extending self

```
ruby <<EOF
module M
  extend self
  def foo
    puts "hello!"
  end
end
M::foo
M.foo

o = Object.new
o.extend(M)
o.foo
EOF
hello!
hello!
hello!
```

## The inherited hook

```
ri Class#inherited | awk '/^[A-Z]/ { print; exit }'
Callback invoked whenever a subclass of the current class is created.
```

```
ruby <<'EOF'
class C
end

def C.inherited(sub)
  puts "Hello #{sub} from #{self}!"
end

class B < C
end
EOF
Hello B from C!
```

## Lazy autoload

```
ruby <<'EOF'
$LOAD_PATH.unshift('.')
require 'bar'
puts 'hello world!'
Bar.cats
EOF
inside bar.rb
Starting some stuff...
Finished some stuff...
hello world!
running Bar::cats!
```

```
ruby <<'EOF'
$LOAD_PATH.unshift('.')
autoload :Bar, 'bar'
puts 'hello world!'
Bar.cats
EOF
hello world!
inside bar.rb
Starting some stuff...
Finished some stuff...
running Bar::cats!
```

## The extended hook

```
ruby <<'EOF'
module M
  def self.extended(base)
    puts "Hello #{base} from #{self}!"
  end

  def foo
    puts "hello from #{self}!"
  end
end

module N
  extend M
end

class C
  extend M
end

o = Object.new.tap {|o| o.extend M }

N.foo
C.foo
o.foo
EOF
Hello N from M!
Hello C from M!
Hello #<Object:0x00007fe72a94f020> from M!
hello from N!
hello from C!
hello from #<Object:0x00007fe72a94f020>!
```

## What is class_eval

Seems like yet another way to define methods.

```
ruby <<'EOF'
class C
end

C.class_eval do
  def foo
   puts 'hello!'
  end
end

one = C.new
two = C.new

one.instance_eval do
  def bar
    puts 'flapjacks!'
  end
end

one.foo
one.bar
two.foo
two.bar
EOF
hello!
flapjacks!
hello!
-:22:in `<main>': undefined method `bar' for #<C:0x00007fa27e01fa40> (NoMethodError)
```

## A mess of hooks

```
ruby <<'EOF'
module M
  def self.included(base)
    puts "hello base #{base} from self #{self}"
    base.extend ClassMethods
    base.class_eval do
      def flap
        puts 'flap!'
      end
    end
  end

  module ClassMethods
    def foo
      puts 'foo!'
    end

    class << self
      def extended(other)
        puts "hello other #{other} from self #{self}"
      end
    end
  end

  def bar
    puts 'bar!'
  end
end

class C
  include M
end

C.foo

o = C.new
o.flap
o.bar
EOF
hello base C from self M
hello other C from self M::ClassMethods
foo!
flap!
bar!
```

## The class << object syntax

Notice how the instance variables live in the instance and the reader methods live in the instance's class.

Not sure how to reach the @baz instance variable though.

```
ruby <<'EOF'
class C
  @foo = 'cats'
  puts "#{self} instance variables: #{self.instance_variables}"
end

class << C
  @bar = 'dogs'
  puts "#{self} instance variables: #{self.instance_variables}"
  attr_reader :foo
end

class << C.singleton_class
  @baz = 'ants' # how can I reach this?
  puts "#{self} instance variables: #{self.instance_variables}"
  attr_reader :bar
end

puts C.foo
puts C.singleton_class.bar
puts C.singleton_class.instance_variable_get(:@baz)
EOF
C instance variables: [:@foo]
#<Class:C> instance variables: [:@bar]
#<Class:#<Class:C>> instance variables: [:@baz]
cats
dogs

```