# frozen_string_literal: true

module ActiveRecord
  # Implements tools to manage and use text search configurations in Postgres.
  module TextSearchConfiguration
  end
end

require 'active_record/text_search_configuration/command_recorder'
require 'active_record/text_search_configuration/schema_dumper'
require 'active_record/text_search_configuration/schema_statements'
require 'active_record/text_search_configuration/version'
