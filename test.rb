# teting
module Foo
  def bar
    whee = lambda { "hello" }.call

    whee.upcase!

    if(whee)
      woo = 3
      wooo = 4
    end

    {
      a: whee,
      b: woo,
      c: wooo,
      d: 1,
      e: 1,
      f: 1,
      g: 1,
      h: 1,
      i: 1,
      j: 1,
      k: 1,
      l: 1,
      m: 1,
      n: 1,
      o: 1,
      p: 1,
    }
  end
end
