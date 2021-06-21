# frozen_string_literal: true

module Polist
  # Most of the code here is borrowed from Uber::Builder code
  # See https://github.com/apotonick/uber/blob/master/lib/uber/builder.rb
  module Builder
    def self.included(base)
      base.extend(ClassMethods)
    end

    class Builders < Array
      def call(context, *args, **kwargs)
        each do |block|
          klass = block.call(context, *args, **kwargs) and return klass
        end

        context
      end

      def <<(proc)
        wrapped_proc = -> (ctx, *args, **kwargs) { ctx.instance_exec(*args, **kwargs, &proc) }
        super(wrapped_proc)
      end
    end

    module ClassMethods
      def builders
        @builders ||= Builders.new
      end

      def builds(proc = nil, &block)
        builders << (proc || block)
      end

      def build(*args, **kwargs)
        build_klass(*args, **kwargs).new(*args, **kwargs)
      end

      # Recursively runs class builders on class until no builders on that class found
      # or some builder returns the class itself
      def build_klass(*args, **kwargs)
        klass = self

        loop do
          new_klass = klass.builders.call(klass, *args, **kwargs)
          break if new_klass == klass
          klass = new_klass
        end

        klass
      end
    end
  end
end
