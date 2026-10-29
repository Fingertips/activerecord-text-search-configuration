# frozen_string_literal: true

class CreateSimpleUnaccent < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'unaccent'
    create_text_search_configuration(
      :simple_unaccent,
      copy: :simple,
      mappings: { %w[hword hword_part word] => %w[unaccent simple] }
    )
  end
end
