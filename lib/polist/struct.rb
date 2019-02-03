# frozen_string_literal: true

module Polist
  module Struct
    module ClassMethods
      def struct(*attrs)
        attr_accessor(*attrs)

        define_method(:initialize) do |*args|
          raise ArgumentError, "struct size differs" if args.length > attrs.length
          attrs.zip(args).each { |attr, val| public_send(:"#{attr}=", val) }
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
