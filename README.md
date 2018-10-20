# Polist   [![Gem Version](https://badge.fury.io/rb/polist.svg)](https://badge.fury.io/rb/polist) [![Build Status](https://travis-ci.org/umbrellio/polist.svg?branch=master)](https://travis-ci.org/umbrellio/polist) [![Coverage Status](https://coveralls.io/repos/github/umbrellio/polist/badge.svg?branch=master)](https://coveralls.io/github/umbrellio/polist?branch=master)

`Polist::Service` is a simple class designed for creating service classes.

### Installation
Juts add `gem "polist"` to your Gemfile.

### Basic usage example
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

## License
Released under MIT License.

## Authors
Created by Yuri Smirnov.

<a href="https://github.com/umbrellio/">
<img style="float: left;" src="https://umbrellio.github.io/Umbrellio/supported_by_umbrellio.svg" alt="Supported by Umbrellio" width="439" height="72">
</a>
