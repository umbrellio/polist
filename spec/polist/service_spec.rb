# frozen_string_literal: true

require "spec_helper"

class BasicService < Polist::Service
  def call
    success!(a: 1)
  end
end

class ServiceWithForm < BasicService
  class Form < Polist::Service::Form
    attribute :a, :String
    attribute :b, :Integer
    attribute :c, :String
  end

  def call
    form.b == 2 ? success!(form.attributes) : fail!(code: :bad_input)
  end
end

class ServiceWithValidations < ServiceWithForm
  class Form < ServiceWithForm::Form
    validates :c, presence: { message: "bad c" }
  end

  Failure = Class.new(Polist::Service::Failure)

  def call
    validate!
    super
  end
end

class ServiceWithParams < BasicService
  param :p1, :p2

  def call
    success!(params: [p1, p2])
  end
end

RSpec.describe Polist::Service do
  specify "basic usage" do
    service = BasicService.run
    expect(service.success?).to eq(true)
    expect(service.failure?).to eq(false)
    expect(service.response).to eq(a: 1)
  end

  describe "service with form" do
    specify "good input" do
      service = ServiceWithForm.run(a: "1", b: "2")
      expect(service.success?).to eq(true)
      expect(service.response).to eq(a: "1", b: 2, c: nil)
    end

    specify "bad input" do
      service = ServiceWithForm.run(a: "1", b: "3")
      expect(service.success?).to eq(false)
      expect(service.response).to eq(code: :bad_input)
    end
  end

  describe "service with form with validations" do
    specify ".run method" do
      service = ServiceWithValidations.run(a: "1", b: "2")
      expect(service.success?).to eq(false)
      expect(service.response).to eq(error: "bad c")
    end

    specify ".call method" do
      expect { ServiceWithValidations.call(a: "1", b: "2") }.to raise_error do |error|
        expect(error.class).to eq(ServiceWithValidations::Failure)
        expect(error.response).to eq(error: "bad c")
      end
    end
  end

  describe "service with params" do
    specify "basic params usage" do
      service = ServiceWithParams.run(p1: "1", p2: "2")
      expect(service.success?).to eq(true)
      expect(service.response).to eq(params: ["1", "2"])
    end
  end
end
