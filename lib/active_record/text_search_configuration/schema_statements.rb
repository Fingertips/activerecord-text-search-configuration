# frozen_string_literal: true

module ActiveRecord
  module TextSearchConfiguration
    # Defines methods to create, drop, and inspect text search configurations on a schema in
    # Postgres.
    module SchemaStatements
      # Creates a text search configuration.
      def create_text_search_configuration(
        name, parser: nil, copy: nil, mappings: {}, force: false
      )
        drop_text_search_configuration(name, if_exists: true, force: force) if force
        execute(
          "CREATE TEXT SEARCH CONFIGURATION #{quote_column_name(name)} " \
          "(#{text_search_configuration_source(parser, copy)})"
        )
        mappings.each do |token_types, dictionaries|
          change_text_search_configuration_mapping(name, token_types, dictionaries)
        end
      end

      # Replaces the dictionaries for one or more token types. An empty list of dictionaries
      # removes the mapping.
      def change_text_search_configuration_mapping(name, token_types, dictionaries)
        token_types = quote_column_names(token_types)
        execute(
          "ALTER TEXT SEARCH CONFIGURATION #{quote_column_name(name)} " \
          "DROP MAPPING IF EXISTS FOR #{token_types}"
        )
        return if dictionaries.blank?

        execute(
          "ALTER TEXT SEARCH CONFIGURATION #{quote_column_name(name)} " \
          "ADD MAPPING FOR #{token_types} " \
          "WITH #{quote_column_names(dictionaries)}"
        )
      end

      # Drops a text search configuration.
      def drop_text_search_configuration(name, if_exists: false, force: false, **)
        execute(
          "DROP TEXT SEARCH CONFIGURATION #{'IF EXISTS ' if if_exists}" \
          "#{quote_column_name(name)}#{' CASCADE' if force == :cascade}"
        )
      end

      # Returns the text search configurations in the public schema.
      def text_search_configurations
        rows = select_all(text_search_configurations_sql, 'SCHEMA')
        rows.group_by { |row| row['name'] }.map do |name, configuration_rows|
          {
            name: name,
            parser: configuration_rows.first['parser'],
            mappings: text_search_configuration_mappings(configuration_rows)
          }
        end
      end

      private

      def text_search_configuration_source(parser, copy)
        if parser && copy
          raise ArgumentError, 'Pass either parser: or copy:, a configuration needs one source.'
        end

        return "COPY = #{quote_column_name(copy)}" if copy

        "PARSER = #{quote_column_name(parser || 'default')}"
      end

      def quote_column_names(names)
        Array(names).map { |name| quote_column_name(name) }.join(', ')
      end

      def text_search_configuration_mappings(rows)
        rows
          .select { |row| row['token_type'] }
          .group_by { |row| row['dictionaries'] }
          .to_h do |dictionaries, grouped|
            [grouped.pluck('token_type'), dictionaries.split(',')]
          end
      end

      def text_search_configurations_sql
        <<~SQL
          SELECT
            config.cfgname AS name,
            parser.prsname AS parser,
            token.alias AS token_type,
            string_agg(dictionary.dictname, ',' ORDER BY map.mapseqno) AS dictionaries
          FROM pg_ts_config config
          JOIN pg_namespace namespace
          ON config.cfgnamespace = namespace.oid AND namespace.nspname = 'public'
          JOIN pg_ts_parser parser ON config.cfgparser = parser.oid
          LEFT JOIN pg_ts_config_map map ON map.mapcfg = config.oid
          LEFT JOIN ts_token_type(config.cfgparser) token ON token.tokid = map.maptokentype
          LEFT JOIN pg_ts_dict dictionary ON dictionary.oid = map.mapdict
          GROUP BY config.cfgname, parser.prsname, token.tokid, token.alias
          ORDER BY config.cfgname, token.tokid
        SQL
      end
    end
  end
end
