require 'spec_helper'
require 'h8'
require 'weakref'

describe 'js_gate' do

  it 'should return number as string' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_s.should == '122.3'
    # res.should_not be_integer
    # res.should_not be_string
  end

  it 'should return integers' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_i.should == 122
    res.should_not be_integer
    res = cxt.eval("11+22;")
    res.to_i.should == 33
    res.should be_kind_of(Fixnum)
  end

  it 'should return floats' do
    cxt = H8::Context.new
    res = cxt.eval("0.2 + 122.1;")
    res.to_s.should == '122.3'
    res.should be_kind_of(Float)
  end

  it 'should return strings' do
    res = H8::Context.eval("'hel' + 'lo';")
    res.to_s.should == 'hello'
    res.should be_kind_of(String)
  end

  it 'should retreive JS fieds as indexes' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    res['foo'].to_s.should == 'bar'
    res['bar'].to_i.should == 122
  end

  it 'should retreive JS fieds as properties' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    res.bar.to_i.should == 122
    res.foo.to_s.should == 'bar'
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122
    # cached method check
    res.foo.to_s.should == 'bar'
    res.bar.to_i.should == 122
  end

  it 'should access arrays' do
    res = H8::Context.eval("[-10, 'foo', 'bar'];")
    res.should_not be_undefined
    res.array?.should be_true
    res.length.should == 3
    3.times {
      res[0].to_i.should == -10
      res[1].to_s.should == 'foo'
      res[2].to_s.should == 'bar'
    }
  end

  it 'should eval and keep context alive' do
    cxt = H8::Context.new
    wr = WeakRef.new cxt
    obj = cxt.eval("({ 'foo': 'bar', 'bar': 122 });")
    cxt = nil
    GC.start # cxt is now kept only by H8::Value obj
    wr.weakref_alive?.should be_true
    obj.foo.should == 'bar'
  end

  it 'should convert simple types to ruby' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122, pi: 3.1415 });")
    r   = res.foo.to_ruby
    r.should be_kind_of(String)
    r.should == 'bar'

    r = res.bar.to_ruby
    r.should be_kind_of(Fixnum)
    r.should == 122

    r = res.pi.to_ruby
    r.should be_kind_of(Float)
    (r == 3.1415).should be_true
  end

  it 'should convert arrays to ruby' do
    res = H8::Context.eval("[-10, 'foo', 'bar'];")
    res.to_ruby.should == [-10, 'foo', 'bar']
    res.to_ary.should == [-10, 'foo', 'bar']
  end

  it 'should provide hash methods' do
    obj = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    obj.keys.should == Set.new(['foo', 'bar'])

    hash = {}
    obj.each { |k,v| hash[k] = v.to_ruby }
    hash.should == { "foo" => "bar", "bar" => 122 }
    obj.to_h.should == { "foo" => "bar", "bar" => 122 }
    obj.to_ruby.should == { "foo" => "bar", "bar" => 122 }

    Set.new(obj.each_key).should == Set.new(['foo', 'bar'])
    Set.new(obj.values.map(&:to_ruby)).should == Set.new(['bar', 122])
    Set.new(obj.each_value.map(&:to_ruby)).should == Set.new(['bar', 122])
  end

  it 'should convert compare to ruby objects' do
    res = H8::Context.eval("({ 'foo': 'bar', 'bar': 122 });")
    (res.foo != 'bar').should be_false
    (res.foo == 'bar').should be_true
    (res.foo != 'ba1').should be_true
    (res.foo == 'ba1').should be_false

    (res.bar != 'bar').should be_true
    (res.bar == 'bar').should be_false
    (res.bar != 122).should be_false
    (res.bar == 122).should be_true
    (res.bar <= 122).should be_true
    (res.bar <= 123).should be_true
    (res.bar >= 122).should be_true
    (res.bar >= 121).should be_true

    (res.bar > 120).should be_true
    (res.bar < 130).should be_true
    (res.bar > 129).should be_false
    (res.bar < 19).should be_false
  end

  it 'should call functions with no args' do
    res = H8::Context.eval "(function() { return 'sono callable'; });"
    res.call('a', '1', '2').should == 'sono callable'
  end

  it 'should call functions with args' do
    res = H8::Context.eval "(function(a, b) { return a + b; });"
    res.call('10', '1').should == '101'
    res.call(10, 1).should == 11
  end

  it 'should raise error on syntax' do
    expect( -> {
      H8::Context.eval 'this is not a valid js'
    }).to raise_error(H8::Error)
  end

  it 'should call member functions only' do
    res = H8::Context.eval <<-End
      function cls(base) {
        this.base = base;
        this.someVal = 'hello!';
        this.noArgs = function() { return 'world!'};
        this.doAdd = function(a, b) {
          return a + b + base;
        }
      }
      new cls(100);
    End
    res.someVal.should == 'hello!'
    res.noArgs.should == 'world!'
    res.doAdd(10, 1).should == 111
  end

end
