# frozen_string_literal: true

require "active_model/validations"
require "plissken"
require "tainbox"

class Polist::Service
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

  attr_accessor :params

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

  def initialize(params)
    self.params = params
  end

  def call; end # Should be implemented in subclasses

  def run
    call
  rescue Failure => error
    @response = error.response
    @failure = true
  end

  def response
    @response ||= {}
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

  def form
    @form ||= self.class::Form.new(form_attributes.to_snake_keys)
  end

  def form_attributes
    params
  end

  def fail!(response = {})
    raise self.class::Failure.new(response)
  end

  def error!(message = "")
    fail!(error: message)
  end

  def success!(response = {})
    @response = response
  end
end
