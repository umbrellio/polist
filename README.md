# Polist   [![Build Status](https://travis-ci.org/umbrellio/polist.svg?branch=master)](https://travis-ci.org/umbrellio/polist)

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

Note that `.run` and `.call` are just shortcuts for `MyService.new(...).run` and `MyService.new(...).call` with the only difference that they always return the service instance instead of the result of `#run` or `#call`. Unlike `#call` though, `#run` is not intended to be owerwritten in subclasses.

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
