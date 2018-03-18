# Ruby Exploring
>A collection of examples exploring the Ruby programming language

## Examples

[Defining methods](./defining_methods.rb)
[Method arguments](./method_arguments.rb)

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