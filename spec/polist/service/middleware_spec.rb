# frozen_string_literal: true

class FirstMiddleware < Polist::Service::Middleware
  def call; end
end

class SecondMiddleware < Polist::Service::Middleware
  def call; end
end

class ServiceWithMiddlewares < Polist::Service
  def call
    success!(success: true)
  end
end

RSpec.describe Polist::Service::Middleware do
  before { ServiceWithMiddlewares.__clear_middlewares__ }

  context "middlewares do nothing" do
    before do
      ServiceWithMiddlewares.register_middleware FirstMiddleware
      ServiceWithMiddlewares.register_middleware SecondMiddleware
    end

    specify "middlewares are called when service is ran" do
      expect_any_instance_of(FirstMiddleware).to receive(:call)
      expect_any_instance_of(SecondMiddleware).to receive(:call)

      service = ServiceWithMiddlewares.run
      expect(service.success?).to eq(true)
      expect(service.failure?).to eq(false)
      expect(service.response).to eq(success: true)
    end
  end

  specify "middlewares can affect the response of the service" do
    middleware = Class.new(Polist::Service::Middleware) do
      def call
        fail!(failed: true)
      end
    end

    ServiceWithMiddlewares.register_middleware middleware

    service = ServiceWithMiddlewares.run
    expect(service.success?).to eq(false)
    expect(service.failure?).to eq(true)
    expect(service.response).to eq(failed: true)
  end

  specify "middlewares delegate methods to service" do
    middleware = Class.new(Polist::Service::Middleware) do
      def call
        form
        form_attributes
        success!
      end
    end

    ServiceWithMiddlewares.register_middleware middleware

    expect { ServiceWithMiddlewares.run }.not_to raise_error
  end
end
