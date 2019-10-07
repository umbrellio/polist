# frozen_string_literal: true

require "active_model"
require "plissken"
require "tainbox"

module Polist
  class Service
    class Failure < StandardError
      attr_accessor :code, :data

      def initialize(code, data = nil)
        self.code = code
        self.data = data
      end

      def inspect
        "#{self.class.name}: #{message}"
      end

      def message
        data ? "#{code.inspect} => #{data.inspect}" : code.inspect
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
    attr_reader :failure_code

    def self.inherited(klass)
      klass.const_set(:Failure, Class.new(klass::Failure))
      klass.prepend(MiddlewareCaller)
      klass.instance_variable_set(:@__polist_middlewares__, __polist_middlewares__.dup)
    end

    def self.build(*args)
      new(*args)
    end

    def self.call(*args, &block)
      build(*args).tap { |service| service.call(&block) }
    end

    def self.run(*args, &block)
      build(*args).tap { |service| service.run(&block) }
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

    def run(&block)
      call(&block)
    rescue self.class::Failure => error
      @response = error.data
      @failure_code = error.code
    end

    def response
      @response
    end

    def failure?
      !!@failure_code
    end

    def success?
      !failure?
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

    def fail!(code, data = nil)
      raise self.class::Failure.new(code, data)
    end

    def success!(response = nil)
      @response = response
    end
  end
end
