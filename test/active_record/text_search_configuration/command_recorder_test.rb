# frozen_string_literal: true

require_relative '../../test_helper'

module ActiveRecord
  module TextSearchConfiguration
    class CommandRecorderTest < ActiveSupport::TestCase
      # Receives replayed commands the same way a migration does.
      class ReplayedMigration
        attr_reader :commands

        def initialize
          @commands = []
        end

        def create_text_search_configuration(*args, **kwargs)
          @commands << [:create_text_search_configuration, args, kwargs]
        end

        def drop_text_search_configuration(*args, **kwargs)
          @commands << [:drop_text_search_configuration, args, kwargs]
        end
      end

      setup do
        @recorder = ActiveRecord::Migration::CommandRecorder.new(ApplicationRecord.connection)
      end

      test 'records creating a configuration' do
        @recorder.create_text_search_configuration(:misc, copy: :simple)

        assert_equal(
          [[:create_text_search_configuration, [:misc], { copy: :simple }]],
          replayed_commands
        )
      end

      test 'inverts creating a configuration' do
        @recorder.revert { @recorder.create_text_search_configuration(:misc, copy: :simple) }

        assert_equal(
          [[:drop_text_search_configuration, [:misc], {}]], replayed_commands
        )
      end

      test 'inverts dropping a configuration when it knows how to create it' do
        @recorder.revert do
          @recorder.drop_text_search_configuration(:misc, copy: :simple, if_exists: true)
        end

        assert_equal(
          [[:create_text_search_configuration, [:misc], { copy: :simple }]],
          replayed_commands
        )
      end

      test 'refuses to invert dropping a configuration it can not create' do
        assert_raises(ActiveRecord::IrreversibleMigration) do
          @recorder.revert { @recorder.drop_text_search_configuration(:misc) }
        end
      end

      private

      def replayed_commands
        migration = ReplayedMigration.new
        @recorder.replay(migration)
        migration.commands
      end
    end
  end
end
