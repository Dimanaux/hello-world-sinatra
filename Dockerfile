FROM ruby:2.7.2-alpine

WORKDIR /app
COPY . /app
RUN bundle install

EXPOSE 80 8000 2222

CMD ["bundle", "exec", "rackup", "--host", "0.0.0.0", "-p", "8000"]
