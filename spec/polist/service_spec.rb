# frozen_string_literal: true

class NoResponseService < Polist::Service
  def call; end
end

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

  def call
    validate!
  end
end

class ServiceWithParams < BasicService
  param :p1, :p2

  def call
    success!(params: [p1, p2])
  end
end

class FailingInnerService < BasicService
  def call
    params[:fail] ? error!("message") : success!
  end
end

class OuterService < BasicService
  def call
    FailingInnerService.call(fail: true)
  end
end

class FailingOuterService < BasicService
  def call
    FailingInnerService.call(fail: params[:inner_fail])
    fail!
  rescue FailingInnerService::Failure
    error!("inner service failure")
  rescue Failure
    error!("failure")
  end
end

class ServiceWithBlock < BasicService
  def call
    success!(yield(1, 2))
  end
end

class ServiceWichRescueBlock < BasicService
  def call
    yield
  rescue StandardError => e
    success!(e)
  end
end

RSpec.describe Polist::Service do
  specify "basic usage" do
    service = BasicService.run
    expect(service.success?).to eq(true)
    expect(service.failure?).to eq(false)
    expect(service.response).to eq(a: 1)
  end

  specify "no response service" do
    service = NoResponseService.run
    expect(service.success?).to eq(true)
    expect(service.response).to eq(nil)
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
      expect(service.response).to eq(params: %w[1 2])
    end
  end

  describe "service with inner service call" do
    specify do
      expect { OuterService.run }.to raise_error(FailingInnerService::Failure)
    end
  end

  describe "failing service with inner service call" do
    specify "inner service fails" do
      service = FailingOuterService.run(inner_fail: true)
      expect(service.success?).to eq(false)
      expect(service.response).to eq(error: "inner service failure")
    end

    specify "inner service doesn't fail" do
      service = FailingOuterService.run(inner_fail: false)
      expect(service.success?).to eq(false)
      expect(service.response).to eq(error: "failure")
    end
  end

  describe ".register_middleware" do
    let(:first_middleware) { Class.new(Polist::Service::Middleware) }
    let(:second_middleware) { Class.new(Polist::Service::Middleware) }

    before do
      BasicService.register_middleware(first_middleware)
      BasicService.register_middleware(second_middleware)
    end

    it "stores middlewares in the service class" do
      expect(BasicService.__polist_middlewares__)
        .to contain_exactly(first_middleware, second_middleware)
    end

    it "raises error if middleware is not a subclass of Polist::Service::Middleware" do
      expect { BasicService.register_middleware(String) }
        .to raise_error(Polist::Service::MiddlewareError,
                        "Middleware String should be a subclass of Polist::Service::Middleware")
    end
  end

  describe "service with yielding" do
    it "sums args in proc" do
      service = ServiceWithBlock.call { |a, b| a + b }
      expect(service.success?).to eq(true)
      expect(service.response).to eq(3)
    end

    it "runs, rescues, and returns success" do
      service = ServiceWichRescueBlock.run { raise StandardError, "Awesome Message" }
      expect(service.success?).to eq(true)
      expect(service.response.message).to eq("Awesome Message")
    end
  end
end
