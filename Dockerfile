FROM ruby:1.9.3

RUN apt-get update -y
RUN apt-get install -y qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x
RUN gem install bundler
RUN \
    export PHANTOMJS_VERSION='2.1.1'                                             && \
    export PHANTOMJS_URL='https://github.com/Medium/phantomjs/releases/download/v2.1.1/phantomjs-2.1.1-linux-x86_64.tar.bz2' && \
    wget -q ${PHANTOMJS_URL}                                                     && \
    tar xfv phantomjs-${PHANTOMJS_VERSION}-linux-x86_64.tar.bz2                  \
      -C /usr/bin --wildcards */bin/phantomjs --strip-components=2
RUN mkdir -p /app
COPY . /app
RUN cd /app && bundle install
