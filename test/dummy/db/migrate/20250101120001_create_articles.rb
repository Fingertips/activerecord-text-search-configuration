# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :articles do |t|
      t.text :title, null: false
      t.virtual :title_tsvector, type: :tsvector, stored: true,
                                 as: "to_tsvector('simple_unaccent', title)"
    end
  end
end
