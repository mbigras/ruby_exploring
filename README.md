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
* [Yielding self like a gemspec](#yielding-self-like-a-gemspec)
* [View the constants in a module](#view-the-constants-in-a-module)
* [Mysterious Proc.new](#mysterious-proc.new)
* [Creating classes on the fly](#creating-classes-on-the-fly)
* [Instance variables for a Class Object](#instance-variables-for-a-class-object)
* [Source location of methods](#source-location-of-methods)

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

## Yielding self like a gemspec

```
ruby <<'EOF'
class C
  attr_accessor :foo, :bar, :baz
  def initialize
    yield self
  end

  def to_s
    "foo=#{foo} bar=#{bar} baz=#{baz}"
  end
end

o = C.new do |c|
  c.foo = 'flea'
  c.bar = 'bat'
  c.baz = 'bee'
end

puts o
EOF
foo=flea bar=bat baz=bee
```

## View the constants in a module

Links

* https://stackoverflow.com/questions/833125/find-classes-available-in-a-module
* https://stackoverflow.com/questions/49867219/how-does-object-know-about-the-const-get-method

Get a quick sense of the constants in a module (class names are constants)

```
ruby -r methadone -e 'puts Methadone.constants' | sort
ARGVParser
CLILogger
CLILogging
Error
ExecutionStrategy
ExitNow
FailedCommandError
Main
OptionParserProxy
ProcessStatus
SH
VERSION
```

To make sure they're classes, select only the classes

```
ruby -r methadone -e 'puts Methadone.constants.select { |c| Methadone.const_get(c).is_a? Class }' | sort
CLILogger
Error
FailedCommandError
OptionParserProxy
ProcessStatus
```

Same for modules

```
ruby -r methadone -e 'puts Methadone.constants.select { |c| Methadone.const_get(c).is_a? Module }' | sort
ARGVParser
CLILogger
CLILogging
Error
ExecutionStrategy
ExitNow
FailedCommandError
Main
OptionParserProxy
ProcessStatus
SH
```

## Mysterious Proc.new

https://github.com/rails/rails/blob/375a4143cf5caeb6159b338be824903edfd62836/railties/lib/rails/engine.rb#L532-L538

```
# Defines the routes for this engine. If a block is given to
# routes, it is appended to the engine.
def routes
  @routes ||= ActionDispatch::Routing::RouteSet.new_with_config(config)
  @routes.append(&Proc.new) if block_given?
  @routes
end
```

If Proc.new is called from inside a method without any arguments of its own, it will return a new Proc containing the block given to its surrounding method.

```
def foo
  Proc.new.call
end

foo { puts "hello world" }
# hello world
```

This means that it is now possible to pass a block between methods without using the &block parameter:

```
class C
  def bar
    puts "called bar..."
    baz &Proc.new
  end

  def baz
    puts "called baz..."
    yield
  end
end

C.new.bar { puts "called block..." }
# called bar...
# called baz...
# called block...
```

More details at

* https://stackoverflow.com/questions/21481620/please-explain-me-what-mean-the-expression-proc-new-in-a-ruby-method/49870776#49870776
* https://mudge.name/2011/01/26/passing-blocks-in-ruby-without-block.html
* http://confreaks.tv/videos/rubyconf2010-zomg-why-is-this-code-so-slow

## Creating classes on the fly

Rails makes the ActiveRecord::Migration class versioned, how could that work?

```
ruby <<'EOF'
class C
  def self.[] version
    const_get "V#{version.to_s.tr '.', '_'}"
  end

  class V1_0
    def dog
      puts "dog v1.0..."
    end
  end

  class V1_1
    def dog
      puts "dog v1.1..."
    end
  end

  class V1_2
    def dog
      puts "dog v1.2..."
    end
  end
end

%w(1.0 1.1 1.2).each do |v|
  C[v].new.dog
end
EOF
dog v1.0...
dog v1.1...
dog v1.2...
```

```
ruby <<'EOF'
module M
  def universal_cat
    puts 'meow!'
  end

  class V1_0
    include M

    def dog
      puts 'dog v1.0...'
      self
    end
  end

  class V1_1 < V1_0
    def dog
      puts 'dog v1.1...'
      self
    end
  end

  class V1_2 < V1_1
    def dog
      puts 'dog v1.2...'
      self
    end
  end
end

%w(V1_0 V1_1 V1_2).each do |v|
  Object.const_get("M::#{v}").new.dog.universal_cat
end
EOF
dog v1.0...
meow!
dog v1.1...
meow!
dog v1.2...
meow!
```

## Instance variables for a Class Object

Read through an example in net-http-digest_auth and was confused about where the the instance variable was located.

Links

* https://github.com/drbrain/net-http-digest_auth/blob/3b86a3acc17e8a691b1f94e3b9a448287d300c6c/sample/auth_server.rb#L6-L10

```
ruby <<'EOF'
class C
  def self.foo
    @cats = 42
  end
  def self.bar
    @cats
  end

  def foo
    @cats = 'lala'
  end
  def bar
    @cats
  end
end

p C.bar
p C.foo
p C.bar

o = C.new

p o.bar
p o.foo
p o.bar
EOF
nil
42
42
nil
"lala"
"lala"
```

## Source location of methods

Links

* https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html

```
ruby <<'EOF'
$LOAD_PATH.unshift '.'
require 'flappy'

class C
  include M
  def cats
    foo
  end
end

C.new.cats
EOF
/Projects/github.com/mbigras/ruby_exploring/flappy.rb:15:in `cats': broken in a confusing way (RuntimeError)
  from /Projects/github.com/mbigras/ruby_exploring/flappy.rb:11:in `baz'
  from /Projects/github.com/mbigras/ruby_exploring/flappy.rb:7:in `bar'
  from /Projects/github.com/mbigras/ruby_exploring/flappy.rb:3:in `foo'
  from -:7:in `cats'
  from -:11:in `<main>'

ruby <<'EOF'
$LOAD_PATH.unshift '.'
require 'flappy'

class C
  include M
  def cats
    p method(:foo).source_location
    foo
  end
end

C.new.cats
EOF
["/Projects/github.com/mbigras/ruby_exploring/flappy.rb", 2]
/Projects/github.com/mbigras/ruby_exploring/flappy.rb:15:in `cats': broken in a confusing way (RuntimeError)
  from /Projects/github.com/mbigras/ruby_exploring/flappy.rb:11:in `baz'
  from /Projects/github.com/mbigras/ruby_exploring/flappy.rb:7:in `bar'
  from /Projects/github.com/mbigras/ruby_exploring/flappy.rb:3:in `foo'
  from -:8:in `cats'
  from -:12:in `<main>'
```
