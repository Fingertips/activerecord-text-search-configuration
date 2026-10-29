# frozen_string_literal: true

class Article < ApplicationRecord
  scope :matching, lambda { |query|
    where("title_tsvector @@ to_tsquery('simple_unaccent', ?)", query)
  }
end
