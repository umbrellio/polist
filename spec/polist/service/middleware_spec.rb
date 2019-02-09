# frozen_string_literal: true

CALLS = [] # rubocop:disable Style/MutableConstant

class FirstMiddleware < Polist::Service::Middleware
  def call
    CALLS << :FirstMiddleware
  end
end

class SecondMiddleware < Polist::Service::Middleware
  def call
    CALLS << :SecondMiddleware
  end
end

class ServiceWithMiddlewares < Polist::Service
  def call
    success!(success: true)
  end
end

RSpec.describe Polist::Service::Middleware do
  before do
    CALLS.clear
    ServiceWithMiddlewares.__clear_middlewares__
  end

  context "middlewares do nothing" do
    before do
      ServiceWithMiddlewares.register_middleware FirstMiddleware
      ServiceWithMiddlewares.register_middleware SecondMiddleware
    end

    let!(:inherited_service) { Class.new(ServiceWithMiddlewares) }

    shared_examples "middlewares are called" do |service_call|
      specify do
        service = instance_exec(&service_call)

        expect(service.success?).to eq(true)
        expect(service.failure?).to eq(false)
        expect(service.response).to eq(success: true)

        expect(CALLS).to eq([:FirstMiddleware, :SecondMiddleware])
      end
    end

    it_behaves_like "middlewares are called", -> { ServiceWithMiddlewares.run }
    it_behaves_like "middlewares are called", -> { ServiceWithMiddlewares.call }

    context "running on inherited class" do
      it_behaves_like "middlewares are called", -> { inherited_service.run }
      it_behaves_like "middlewares are called", -> { inherited_service.call }
    end
  end

  describe "middlewares affect the response of the service" do
    describe "#run" do
      specify "#response is mutated and error is rescued" do
        middleware = Class.new(Polist::Service::Middleware) do
          def call
            fail!(failed: true)
          end
        end

        ServiceWithMiddlewares.register_middleware middleware

        expect { ServiceWithMiddlewares.run }.not_to raise_error

        service = ServiceWithMiddlewares.run
        expect(service.success?).to eq(false)
        expect(service.failure?).to eq(true)
        expect(service.response).to eq(failed: true)
      end
    end

    describe "#call" do
      specify "error is raised" do
        middleware = Class.new(Polist::Service::Middleware) do
          def call
            fail!(failed: true)
          end
        end

        ServiceWithMiddlewares.register_middleware middleware

        expect { ServiceWithMiddlewares.call }
          .to raise_error(ServiceWithMiddlewares::Failure, "{:failed=>true}")
      end
    end
  end

  describe "middlewares delegate methods to service" do
    shared_examples "no errors are raised" do |service_call|
      specify do
        middleware = Class.new(Polist::Service::Middleware) do
          def call
            form
            form_attributes
            success!
          end
        end

        ServiceWithMiddlewares.register_middleware middleware

        expect { service_call.() }.not_to raise_error
      end
    end

    it_behaves_like "no errors are raised", -> { ServiceWithMiddlewares.run }
    it_behaves_like "no errors are raised", -> { ServiceWithMiddlewares.call }
  end
end
