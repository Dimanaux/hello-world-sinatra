# frozen_string_literal: true

require 'sinatra'

get '/' do
  "Hello, world! Running #{RUBY_DESCRIPTION}"
end
