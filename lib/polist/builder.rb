# frozen_string_literal: true

require "uber/builder"

module Polist
  module Builder
    def self.included(base)
      base.include(Uber::Builder)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Recursively runs class builders on class until no builders on that class found
      # or some builder returns the class itself
      def build_klass(*args, **options)
        klass = self

        loop do
          new_klass = klass.build!(klass, *args, **options)
          break if new_klass == klass
          klass = new_klass
        end

        klass
      end

      def build(*args, **options)
        build_klass(*args, **options).new(*args)
      end
    end
  end
end
