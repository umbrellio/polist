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
        build_klass(*args, **options).new(*args, **options)
      end
    end
  end
end

module Uber
  module Builder
    def self.included(base)
      base.extend DSL
      base.extend Build
    end

    class Builders < Array
      def call(context, *args, **options)
        each do |block|
          klass = block.(context, *args, **options) and return klass # Uber::Value#call()
        end

        context
      end

      def <<(proc)
        super Uber::Option[proc, instance_exec: true]
      end
    end

    module DSL
      def builders
        @builders ||= Builders.new
      end

      def builds(proc=nil, &block)
        builders << (proc || block)
      end
    end

    module Build
      # Call this from your class to compute the concrete target class.
      def build!(context, *args, **options)
        builders.(context, *args, **options)
      end
    end
  end

  class Option
    def self.[](value, options={})
      case value
      when Proc
        if options[:instance_exec]
          ->(context, *args, **options) { context.instance_exec(*args, **options, &value) }
        else
          value
        end
      when Uber::Callable
        value
      when Symbol
        ->(context, *args, **options){ context.send(value, *args, **options) }
      else
        ->(*) { value }
      end
    end
  end
end
