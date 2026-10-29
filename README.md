# Active Record – Text Search Configuration

Allows basic management of text search configurations in Postgres.

```ruby
# Assumes you already have the unaccent extension created for the database.
class CreateSimpleUnaccentSearchConfiguration < ActiveRecord::Migration[8.1]
  def change
    create_text_search_configuration(
      :simple_unaccent,
      # Start from the simple search configuration.
      copy: :simple,
      # The tsearch parser assigns a type to each token. We configure how
      # values for each type are mapped to an internal value before
      # creating a search vector.
      mappings: {
      	%w[hword hword_part word] => %w[unaccent simple],
        %w[asciiword] => %w[simple]
      }
    )
  end
end
```

After this we can use the search configuration every time we create a vector:

```ruby
create_table :documents do |t|
  t.text :title
  t.virtual(
  	:title_tsvector,
    type: :tsvector,
    stored: true,
    as: "to_tsvector('simple_unaccent', coalesce(title, ''))"
  )
end
```

We store a vector for query performance reasons and the original text for presentation. Having a predefined search configuration means we can re-use the same settings when using a function like `ts_headline` on the text:

    ts_headline('simple_unaccent', "documents"."title", …)

## Setup

Add `activerecord-text-search-configuration` to your dependencies.

## Defining a search configuration and mapping

You probably want to start by reading the [PostgreSQL documentation](https://www.postgresql.org/docs/current/textsearch-controls.html) about controlling text search.

A configuration starts from either a parser, without any mappings:

    create_text_search_configuration(parser: :default)
    
Or it starts as a copy of an existing configuration:

    create_text_search_configuration(copy: :simple)

You can get a full list of token types from the server by running `psql`:

    \dFp+ default

In schema changes you can use `change_text_search_configuration_mapping(name, token_types, dictionaries)` and `drop_text_search_configuration(name)` to remove a configuration. Pass `force: :cascade` to also drop generated columns and indexes that depend on it. 

Note that `create_text_search_configuration` is reversible; `drop_text_search_configuration` is reversible when you pass `parser:` or `copy:` with `mappings:`.

If you're still lost, you probably want something like this:

```ruby
create_text_search_configuration(
  'simple_unaccent',
  parser: 'default',
  mappings: {
    %w[
      asciihword
      asciiword
      email
      file
      float
      host
      hword_asciipart
      hword_numpart
      int
      numhword
      numword
      protocol
      sfloat
      uint
      url
      url_path
      version
    ] => ['simple'],
    %w[word hword_part hword] => %w[unaccent simple]
  }
)
```

This leaves out `blank`, `entity`, and `tag`. We probably don't care about whitespace and entities (eg. `&gt;`) and tags (eg. `<xml>`) need to pre-processing to handle in a useful way if you want to make them searchable so the parser should never find them.

You will need to do a lot of work to massage documents and queries so you get the type of query features you want, but it's outside of the scope of this README to discuss all these details.

## Development

Run tests in this repository with `rake`. Migrations are exercised by running them in the dummy application.

```
bundle install
cd test/dummy
rm -f db/schema.rb && RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
cd ../../
bundle exec rake
```

If you also want to verify running tests on Rails Edge, you can set `BUNDLE_GEMFILE` and run everything again.

```
export BUNDLE_GEMFILE=$(pwd)/Gemfile.edge
bundle install
cd test/dummy
rm -f db/schema.rb && RAILS_ENV=test bundle exec rake db:drop db:create db:migrate
cd ../../
bundle exec rake
```
