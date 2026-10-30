# frozen_string_literal: true

module ActiveRecord
  module TextSearchConfiguration
    # Records text search configuration statements in migrations so they can be reverted.
    module CommandRecorder
      def create_text_search_configuration(*args, **kwargs, &)
        command = text_search_configuration_command(__method__, args, kwargs)
        record(*command, &)
      end

      def drop_text_search_configuration(*args, **kwargs, &)
        command = text_search_configuration_command(__method__, args, kwargs)
        record(*command, &)
      end

      private

      def invert_create_text_search_configuration(args, _kwargs = nil)
        text_search_configuration_command(:drop_text_search_configuration, [args.first], {})
      end

      # Dropping can only be reverted when the migration passes everything needed to create the
      # configuration again.
      def invert_drop_text_search_configuration(args, kwargs = args.extract_options!)
        if kwargs[:parser].nil? && kwargs[:copy].nil?
          raise(
            ActiveRecord::IrreversibleMigration,
            'To make drop_text_search_configuration reversible, pass parser: or copy: and ' \
            'mappings:.'
          )
        end

        text_search_configuration_command(
          :create_text_search_configuration, [args.first], kwargs.except(:if_exists, :force)
        )
      end

      # Rails 8.2 takes three instead of two arguments to the methods, this is an adapter so the
      # code works on older and newer versions of Rails.
      def text_search_configuration_command(command, args, kwargs)
        return [command, args, kwargs] if method(:record).arity == 3
        return [command, args] if kwargs.empty?

        [command, [*args, Hash.ruby2_keywords_hash(kwargs)]]
      end
    end
  end
end
