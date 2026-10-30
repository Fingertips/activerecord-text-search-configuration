# frozen_string_literal: true

module ActiveRecord
  module TextSearchConfiguration
    # Overrides the PostgresAdapter schema dumper to include text search configurations.
    module SchemaDumper
      extend ActiveSupport::Concern

      def text_search_configurations(stream)
        configurations = @connection.text_search_configurations
        return unless configurations.any?

        configurations.each do |configuration|
          text_search_configuration(stream, configuration)
        end
        stream.puts
      end

      def tables(stream)
        text_search_configurations(stream)
        super
      end

      private

      # rubocop:disable-next Metrics/AbcSize
      def text_search_configuration(stream, configuration)
        stream.puts("  create_text_search_configuration(\n")
        stream.puts("    #{configuration[:name].inspect},")
        stream.puts("    parser: #{configuration[:parser].inspect},")
        stream.puts('    force: :cascade,')
        stream.puts('    mappings: {')
        stream.puts(
          configuration[:mappings].map do |token_types, dictionaries|
            "      #{token_types.inspect} => #{dictionaries.inspect}"
          end.join(",\n")
        )
        stream.puts('    }')
        stream.puts('  )')
      end
    end
  end
end
