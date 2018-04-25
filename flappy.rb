module M
  def foo
    bar
  end

  def bar
    baz
  end

  def baz
    M.cats
  end

  def self.cats
    raise 'broken in a confusing way'
  end
end