# frozen_string_literal: true

module ActiveRecord
  module TextSearchConfiguration
    class Railtie < Rails::Railtie # :nodoc:
      initializer 'active_record.text_search_configuration' do
        ActiveSupport.on_load(:active_record_postgresqladapter) do
          ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.include(
            ActiveRecord::TextSearchConfiguration::SchemaDumper
          )
          ActiveSupport.on_load(:active_record) do
            ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements.include(
              ActiveRecord::TextSearchConfiguration::SchemaStatements
            )
            ActiveRecord::Migration::CommandRecorder.include(
              ActiveRecord::TextSearchConfiguration::CommandRecorder
            )
          end
        end
      end
    end
  end
end
