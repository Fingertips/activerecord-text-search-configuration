# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveRecord
  module TextSearchConfiguration
    class CommandRecorderTest < ActiveSupport::TestCase
      setup do
        @recorder = ActiveRecord::Migration::CommandRecorder.new(ApplicationRecord.connection)
      end

      test 'inverts creating a configuration' do
        @recorder.revert { @recorder.create_text_search_configuration(:misc, copy: :simple) }

        assert_equal(
          [[:drop_text_search_configuration, [:misc]]], @recorder.commands
        )
      end

      test 'inverts dropping a configuration when it knows how to create it' do
        @recorder.revert do
          @recorder.drop_text_search_configuration(:misc, copy: :simple, if_exists: true)
        end

        assert_equal(
          [[:create_text_search_configuration, [:misc, { copy: :simple }]]],
          @recorder.commands
        )
      end

      test 'refuses to invert dropping a configuration it can not create' do
        assert_raises(ActiveRecord::IrreversibleMigration) do
          @recorder.revert { @recorder.drop_text_search_configuration(:misc) }
        end
      end
    end
  end
end
