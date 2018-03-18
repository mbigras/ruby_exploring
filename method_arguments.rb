def foo(bar, baz)
  p bar
  p baz
  42
end

def foo(bar, *baz)
  p bar
  p baz
  42
end

def foo(bar:, baz:, **args)
  p bar
  p baz
  p args
  42
end

def foo(*args, **opts)
  p args
  p opts
  42
end

def foo(*args, **opts, &blk)
  p args
  p opts
  yield(args, opts) if block_given?
  42
end

foo('foo', 'bar', 'baz', baz: 'jack', bar: 'flap', this: 'that')
foo('foo', 'bar', 'baz', baz: 'jack', bar: 'flap', this: 'that') { |args, opts| p "#{args.first}, #{opts[:bar]}" }
foo('foo', 'bar', 'baz', baz: 'jack', bar: 'flap', this: 'that') { |args, opts| p "#{args.last}, #{opts[:bar]}" }

# ["foo", "bar", "baz"]
# {:baz=>"jack", :bar=>"flap", :this=>"that"}
# ["foo", "bar", "baz"]
# {:baz=>"jack", :bar=>"flap", :this=>"that"}
# "foo, flap"
# ["foo", "bar", "baz"]
# {:baz=>"jack", :bar=>"flap", :this=>"that"}
# "baz, flap"
# outrageous.