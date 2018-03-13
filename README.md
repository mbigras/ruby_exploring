# Ruby Exploring
>A collection of examples exploring the Ruby programming language

## Examples

[Defining methods](./defining_methods.rb)

Insight: It seems like calling `super` from a method defined in an objects singleton class will call a method in a module extended onto the same object's singleton class.

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