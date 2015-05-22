FROM ubuntu:14.04
MAINTAINER Jay Stramel <jaystramel@dolphinmicro.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get upgrade -y

# Standard tools
RUN apt-get install -y wget curl git-core mercurial

# Build environment
RUN apt-get install -y build-essential libssl-dev libreadline-dev \
  zlib1g-dev libcurl4-openssl-dev libyaml-dev libgdbm-dev libffi-dev \
  libpcre3 libpcre3-dev libpcrecpp0 imagemagick nodejs \
  mysql-client-5.6 libmysqlclient-dev sqlite3 libsqlite3-dev

# Install Ruby
RUN mkdir '/sources'
ADD ruby-2.1.5.tar.gz /sources/
ADD install_ruby.sh /sources/
RUN /sources/install_ruby.sh ruby-2.1.5 /usr/local/ruby215
