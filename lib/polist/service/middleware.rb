# frozen_string_literal: true

class Polist::Service::Middleware
  def initialize(service)
    @service = service
  end

  # Should be implemented in subclasses
  def call; end

  private

  attr_reader :service

  %i[fail! error! success! form form_attributes].each do |service_method|
    define_method(service_method) do |*args|
      service.send(service_method, *args)
    end
  end
end
