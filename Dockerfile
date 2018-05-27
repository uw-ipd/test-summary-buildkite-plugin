FROM ruby:2.5.1-alpine

### Install Buildkite Agent
# Installs the buildkite agent binary into /usr/local/bin
# This allows use of buildkite-agent in docker steps if the source agent
# is running within a docker container, as the agent binary is *not* present in the host.
# 
# Requires subsequent environment vars in job steps
#   --env BUILDKITE_JOB_ID
#   --env BUILDKITE_BUILD_ID
#   --env BUILDKITE_AGENT_ACCESS_TOKEN
#
# Add to /usr/local/bin so the above env vars can be set via the docker buildkite plugin
# without masking the binary via the /usr/bin/buildkite-agent bindmount
RUN apk add --no-cache curl
RUN curl -s https://api.github.com/repos/buildkite/agent/releases/latest | \
    grep browser_download_url | grep buildkite-agent-linux-amd64 | sed 's/"browser_download_url"://' | \
    xargs curl -L | tar -xz -C /usr/local/bin ./buildkite-agent

# Fetch/install gems
RUN mkdir -p /opt/gems
COPY Gemfile Gemfile.lock /opt/gems/
WORKDIR /opt/gems
RUN bundle install --deployment --without development

ENV APP_DIR=/usr/src/app

COPY . $APP_DIR
RUN mkdir -p $APP_DIR/vendor && ln -s /opt/gems/vendor/bundle $APP_DIR/vendor/bundle

WORKDIR $APP_DIR
CMD ["./bin/run"]
