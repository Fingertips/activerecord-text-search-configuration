# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveRecord
  module TextSearchConfiguration
    class SchemaDumperTest < ActiveSupport::TestCase
      setup do
        stream = StringIO.new
        ActiveRecord::SchemaDumper.dump(ApplicationRecord.connection_pool, stream)
        @schema = stream.string
      end

      test 'dumps configurations between extensions and tables' do
        assert_operator(
          @schema.index('enable_extension "unaccent"'),
          :<,
          @schema.index('create_text_search_configuration(')
        )
        assert_operator(
          @schema.index('create_text_search_configuration('),
          :<,
          @schema.index('create_table "articles"')
        )
      end

      test 'dumps the parser and all mappings' do
        assert_includes(
          @schema.squish,
          'create_text_search_configuration( "simple_unaccent", ' \
          'parser: "default", force: :cascade, mappings: {'
        )
        assert_includes(
          @schema.squish,
          '["asciiword", "numword", "email", "url", "host", "sfloat", "version", ' \
          '"hword_numpart", "hword_asciipart", "numhword", "asciihword", "url_path", ' \
          '"file", "float", "int", "uint"] => ["simple"]'
        )
        assert_includes(@schema, '["word", "hword_part", "hword"] => ["unaccent", "simple"]')
      end

      test 'loads the dumped configuration into the same configuration' do
        connection = ApplicationRecord.connection
        before = connection.text_search_configurations
        statement = @schema[/create_text_search_configuration\([^)]+\)/m]

        connection.transaction do
          # rubocop:disable-next Security/Eval
          capture_io { ActiveRecord::Schema.define { eval(statement) } }
          assert_equal before, connection.text_search_configurations
          raise ActiveRecord::Rollback
        end
      end
    end
  end
end
