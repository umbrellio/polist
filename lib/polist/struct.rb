# frozen_string_literal: true

module Polist
  module Struct
    def self.struct(receiver, *attrs)
      instance_method(:struct).bind(receiver).call(*attrs)
    end

    def struct(*attrs)
      attr_accessor(*attrs)

      define_method(:initialize) do |*args|
        raise ArgumentError, "struct size differs" if args.length > attrs.length
        attrs.zip(args).each { |attr, val| public_send(:"#{attr}=", val) }
      end
    end
  end
end
