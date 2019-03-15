# Polist   [![Gem Version](https://badge.fury.io/rb/polist.svg)](https://badge.fury.io/rb/polist) [![Build Status](https://travis-ci.org/umbrellio/polist.svg?branch=master)](https://travis-ci.org/umbrellio/polist) [![Coverage Status](https://coveralls.io/repos/github/umbrellio/polist/badge.svg?branch=master)](https://coveralls.io/github/umbrellio/polist?branch=master)

Polist is a set of simple tools for creating business logic layer of your applications:

- `Polist::Service` is a simple class designed for creating service classes.
- `Polist::Builder` is a builder system based on `Uber::Builder`.
- `Polist::Struct` is a small utility that helps generating simple `Struct`-like object initializers.

## Installation

Simply add `gem "polist"` to your Gemfile.

## Using Polist::Service

```ruby
class MyService < Polist::Service
  def call
    if params[:ok]
      success!(code: :cool)
    else
      fail!(code: :not_cool)
    end
  end
end

service = MyService.run(ok: true)
service.success? #=> true
service.response #=> { code: :cool }

service = MyService.run(ok: false)
service.success? #=> false
service.response #=> { code: :not_cool }
```

The only parameter that is passed to the service is called `params` by default. If you want more params, feel free to define your own initializer and call the service accordingly:

```ruby
class MyService < Polist::Service
  def initialize(a, b, c)
    # ...
  end
end

MyService.call(1, 2, 3)
```

Unlike `.run`, `.call` will raise `Polist::Service::Failure` exception on failure:

```ruby
begin
  MyService.call(ok: false)
rescue Polist::Service::Failure => error
  error.response #=> { code: :not_cool }
end
```

Note that `.run` and `.call` are just shortcuts for `MyService.new(...).run` and `MyService.new(...).call` with the only difference that they always return the service instance instead of the result of `#run` or `#call`. Unlike `#call` though, `#run` is not intended to be overwritten in subclasses.

### Using blocks in #call and #run methods.

You can use yield in `#call`. And then call `::run` or `::call` class methods with block. For example, we have the class:
```ruby
class BlockFun < Polist::Service
  def call
    success!(yield(1, 2))
  end
end
```

Then we can use it like this:
```ruby
service = BlockFun.call { |a, b| a + b }

p service.response # => 3
```

Behind the scenes it just catches passed block in class methods `::run` and `::call`, converts it to proc and then passes proc to instance method `#call` and `#run` by converting it back to block. So, for example, if you want to pass this block to private methods, you can write code like this:
```ruby
class AnotherBlockFun < Polist::Service
  def call(&block)
    success!(block_caller(&block))
  end

  private

  def block_caller
    yield 1, 2
  end
end

service = AnotherBlockFun.call { |a, b| a + b }

p service.response # => 3
```

### Using Form objects

Sometimes you want to use some kind of params parsing and/or validation, and you can do that with the help of `Polist::Service::Form` class. It uses [tainbox](https://github.com/enthrops/tainbox) gem under the hood.

```ruby
class MyService < Polist::Service
  class Form < Polist::Service::Form
    attribute :param1, :String
    attribute :param2, :Integer
    attribute :param3, :String, default: "smth"
    attribute :param4, :String

    validates :param4, presence: true
  end

  def call
    p form.valid?
    p [form.param1, form.param2, form.param3]
  end

  # The commented code is just the default implementation and can be simply overwritten
  # private

  # def form
  #   @form ||= self.class::Form.new(form_attributes.to_snake_keys)
  # end

  # def form_attributes
  #   params
  # end
end

MyService.call(param1: "1", param2: "2") # prints false and then ["1", 2, "smth"]
```

The `#form` method is there just for convinience and by default it uses what `#form_attributes` returns as the attributes for the default form class which is the services' `Form` class. You are free to use as many different form classes as you want in your service.

## Using Polist::Builder

The build logic is based on [Uber::Builder](https://github.com/apotonick/uber#builder) but it allows recursive builders. See the example:

Can be used with `Polist::Service` or any other Ruby class.

```ruby
class User
  include Polist::Builder

  builds do |role|
    case role
    when /admin/
      Admin
    end
  end

  attr_accessor :role

  def initialize(role)
    self.role = role
  end
end

class Admin < User
  builds do |role|
    SuperAdmin if role == "super_admin"
  end

  class SuperAdmin < Admin
    def super?
      true
    end
  end

  def super?
    false
  end
end

User.build("user") # => #<User:... @role="user">

User.build("admin") # => #<Admin:... @role="admin">
User.build("admin").super? # => false

User.build("super_admin") # => #<Admin::SuperAdmin:... @role="super_admin">
User.build("super_admin").super? # => true

Admin.build("smth") # => #<Admin:... @role="admin">
SuperAdmin.build("smth") # => #<Admin::SuperAdmin:... @role="admin">
```

## Using Polist::Struct

Works pretty much the same like Ruby `Struct` class, but you don't have to subclass it.

Can be used with `Polist::Service` or any other class that don't have initializer specified.

```ruby
class Point
  include Polist::Struct

  struct :x, :y
end

a = Point.new(15, 25)
a.x # => 15
a.y # => 25

b = Point.new(15, 25, 35) # raises ArgumentError: struct size differs

c = Point.new(15)
c.x # => 15
c.y # => nil
```

### Using Middlewares

If you have some common things to be done in more than one service, you can define a middleware and register it inside the said services.
Every middleware takes the service into it's constructor and executes `#call`. Thus every middleware has to implement `#call` method and has a `#service` attribute reader.
Middlewares delegate `#success!`, `#fail!`, `#error!`, `#form`, `#form_attributes` to the service class they are registered in.
Every middleware should be a subclass of `Polist::Service::Middleware`. Middlewares are run before the service itself is run.

To register a middleware one should use `.register_middleware` class method on a service. More than one middleware can be registered for one service.

For example:
```ruby
class MyMiddleware < Polist::Service::Middleware
  def call
    fail!(code: :not_cool) if service.fail_on_middleware?
  end
end

class MyService < Polist::Service
  register_middleware MyMiddleware

  def call
    success!(code: :cool)
  end

  def fail_on_middleware?
    true
  end
end

service = MyService.run
service.success? #=> false
service.response #=> { code: :not_cool }
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbrellio/polist.

## License

Released under MIT License.

## Authors

Created by Yuri Smirnov.

<a href="https://github.com/umbrellio/">
<img style="float: left;" src="https://umbrellio.github.io/Umbrellio/supported_by_umbrellio.svg" alt="Supported by Umbrellio" width="439" height="72">
</a>
