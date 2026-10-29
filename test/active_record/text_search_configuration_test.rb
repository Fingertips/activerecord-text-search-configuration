# frozen_string_literal: true

require_relative '../test_helper'

module ActiveRecord
  class TextSearchConfigurationTest < ActiveSupport::TestCase
    setup do
      Article.connection.execute('TRUNCATE articles')
      Article.create!(title: 'Einführung in Blender')
      Article.create!(title: 'Straßenkarte')
    end

    test 'generates columns using the configuration created by the schema' do
      assert_equal ['Einführung in Blender'], Article.matching('einfuhrung').pluck(:title)
      assert_equal ['Einführung in Blender'], Article.matching('einführung').pluck(:title)
      assert_equal ['Straßenkarte'], Article.matching('strassenkarte').pluck(:title)
    end

    test 'keeps the mappings copied from the source configuration' do
      assert_equal ['Einführung in Blender'], Article.matching('blender').pluck(:title)
    end
  end
end
