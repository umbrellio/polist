# frozen_string_literal: true

require "active_model"
require "plissken"
require "tainbox"

module Polist
  class Service
    class Failure < StandardError
      attr_accessor :response

      def initialize(response)
        self.response = response
        super
      end
    end

    class Form
      include Tainbox
      include ActiveModel::Validations
    end

    module MiddlewareCaller
      def call
        unless @__polist_middlewares__called__
          call_middlewares
          @__polist_middlewares__called__ = true
        end

        super
      end
    end

    MiddlewareError = Class.new(StandardError)

    attr_accessor :params

    def self.inherited(klass)
      klass.const_set(:Failure, Class.new(klass::Failure))
      klass.prepend(MiddlewareCaller)
      klass.instance_variable_set(:@__polist_middlewares__, __polist_middlewares__.dup)
    end

    def self.build(*args)
      new(*args)
    end

    def self.call(*args)
      build(*args).tap(&:call)
    end

    def self.run(*args)
      build(*args).tap(&:run)
    end

    def self.param(*names)
      names.each do |name|
        define_method(name) { params.fetch(name) }
      end
    end

    def self.__polist_middlewares__
      @__polist_middlewares__ ||= []
    end

    def self.register_middleware(klass)
      unless klass < Polist::Service::Middleware
        raise MiddlewareError,
              "Middleware #{klass} should be a subclass of Polist::Service::Middleware"
      end

      __polist_middlewares__ << klass
    end

    def self.__clear_middlewares__
      @__polist_middlewares__ = []
    end

    def initialize(params = {})
      self.params = params
    end

    # Should be implemented in subclasses
    def call; end

    def run
      call
    rescue self.class::Failure => error
      @response = error.response
      @failure = true
    end

    def response
      @response
    end

    def failure?
      !!@failure
    end

    def success?
      !failure?
    end

    def validate!
      error!(form.errors.to_h.values.first) unless form.valid?
    end

    private

    def call_middlewares
      self.class.__polist_middlewares__.each do |middleware|
        middleware.new(self).call
      end
    end

    def form
      @form ||= self.class::Form.new(form_attributes.to_snake_keys)
    end

    def form_attributes
      params
    end

    def fail!(response = nil)
      raise self.class::Failure.new(response)
    end

    def error!(message = "")
      fail!(error: message)
    end

    def success!(response = nil)
      @response = response
    end
  end
end
