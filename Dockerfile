FROM ruby:2.3
RUN apt-get update \
    && apt-get install -y --no-install-recommends firebird-dev smbclient \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .
RUN bundle install

CMD ["ruby", "test/smb/client_helper_test.rb"]
