# frozen_string_literal: true

module ActiveRecord
  module TextSearchConfiguration
    # Records text search configuration statements in migrations so they can be reverted.
    module CommandRecorder
      def create_text_search_configuration(*args, &)
        record(:create_text_search_configuration, args, &)
      end

      def drop_text_search_configuration(*args, &)
        record(:drop_text_search_configuration, args, &)
      end

      private

      def invert_create_text_search_configuration(args)
        [:drop_text_search_configuration, [args.first]]
      end

      # Dropping can only be reverted when the migration passes everything needed to create the
      # configuration again.
      def invert_drop_text_search_configuration(args)
        options = args.extract_options!
        if options[:parser].nil? && options[:copy].nil?
          raise(
            ActiveRecord::IrreversibleMigration,
            'To make drop_text_search_configuration reversible, pass parser: or copy: and ' \
            'mappings:.'
          )
        end

        [:create_text_search_configuration, [args.first, options.except(:if_exists, :force)]]
      end
    end
  end
end
