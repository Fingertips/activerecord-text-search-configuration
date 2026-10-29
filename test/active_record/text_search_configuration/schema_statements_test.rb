# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveRecord
  module TextSearchConfiguration
    class SchemaStatementsTest < ActiveSupport::TestCase
      def connection
        ApplicationRecord.connection
      end

      def configuration_names
        connection.text_search_configurations.pluck(:name)
      end

      def configuration(name)
        connection.text_search_configurations.find { |configuration| configuration[:name] == name }
      end

      def lexemes(configuration, text)
        connection.select_value(
          ApplicationRecord.sanitize_sql_array(
            ['SELECT to_tsvector(?::regconfig, ?)::text', configuration, text]
          )
        )
      end

      teardown do
        connection.drop_text_search_configuration(:misc, if_exists: true)
      end

      test 'creates and drops configurations' do
        assert_equal_set(%w[simple_unaccent], configuration_names)
        connection.create_text_search_configuration(:misc, copy: :simple)
        assert_equal_set(%w[simple_unaccent misc], configuration_names)
        connection.drop_text_search_configuration(:misc)
        assert_equal_set(%w[simple_unaccent], configuration_names)
      end

      test 'creates a configuration from a parser with only the given mappings' do
        connection.create_text_search_configuration(
          :misc, parser: :default, mappings: { 'asciiword' => 'simple' }
        )

        assert_equal({ name: 'misc', parser: 'default', mappings: { ['asciiword'] => ['simple'] } },
                     configuration('misc'))
        # Only ASCII words are indexed, so Einführung and 2.0 are skipped.
        assert_equal "'blender':2 'in':1", lexemes('misc', 'Einführung in Blender 2.0')
      end

      test 'replaces and removes mappings of a copied configuration' do
        connection.create_text_search_configuration(
          :misc,
          copy: :simple,
          mappings: { %w[word asciiword] => %w[unaccent simple], 'email' => [] }
        )

        mappings = configuration('misc')[:mappings]
        assert_equal %w[unaccent simple],
                     mappings.find { |token_types, _| token_types.include?('word') }.last
        assert_not mappings.keys.flatten.include?('email')
        assert_equal "'einfuhrung':1", lexemes('misc', 'Einführung me@example.com')
      end

      test 'refuses both a parser and a copy' do
        assert_raises(ArgumentError) do
          connection.create_text_search_configuration(:misc, parser: :default, copy: :simple)
        end
      end

      test 'forces creation over an existing configuration' do
        connection.create_text_search_configuration(:misc, copy: :simple)
        connection.create_text_search_configuration(:misc, copy: :english, force: :cascade)

        assert_equal "'run':1", lexemes('misc', 'running')
      end

      test 'only lists configurations in the public schema' do
        assert_not configuration_names.include?('english')
      end

      test 'notifies internals about the executed queries' do
        queries = []
        callback = ->(event) { queries << event.payload[:sql] }

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          configuration_names
        end

        assert_includes queries.last, "namespace.nspname = 'public'"
      end
    end
  end
end
