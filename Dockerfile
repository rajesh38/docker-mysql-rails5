FROM ubuntu:14.04

# Setup environment
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Update 
RUN apt-get update
# RUN apt-get upgrade -y
RUN apt-get install -y curl wget git nodejs unzip

ENV RUBY_VERSION 2.2.4

# Install RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN \curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c 'source /usr/local/rvm/scripts/rvm'

# Install Ruby
RUN /bin/bash -l -c 'rvm requirements'
RUN /bin/bash -l -c 'rvm install $RUBY_VERSION'
RUN /bin/bash -l -c 'rvm use $RUBY_VERSION --default'
RUN /bin/bash -l -c 'rvm rubygems current'

RUN /bin/bash -l -c 'source /usr/local/rvm/scripts/rvm'

# installing mysql
RUN echo "installing mysql-server..."
RUN echo "mysql-server-5.7 mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server-5.7 mysql-server/root_password_again password root" | debconf-set-selections
RUN apt-get update && apt-get install -y mysql-server libmysqlclient-dev rubygems-integration
#enable access
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
RUN echo $(mysql --version)
RUN echo "creating database 'actioncable_test' for the app..."
RUN /bin/bash -l -c "service mysql start && mysql -uroot -proot -e 'create database actioncable_test'"

RUN /bin/bash -l -c "gem install rubygems-update"
RUN /bin/bash -l -c "gem install bundler"
RUN echo "creating new direcory 'testapp' for cloning the git repo, cloing from 'https://github.com/rajesh38/ActionCable_chat_app.git'...."
RUN cd /srv && mkdir testapp && cd testapp && git clone https://github.com/rajesh38/ActionCable_chat_app.git .
RUN /bin/bash -l -c "cd /srv/testapp && bundle"
RUN echo "checking Rails version"
RUN /bin/bash -l -c "cd /srv/testapp && echo $(rails -v)"
RUN echo "setting up database by db migrate"
RUN /bin/bash -l -c "echo $(service mysql status) && service mysql start && cd /srv/testapp && rails db:migrate"
RUN echo "starting rails server in background"
ENTRYPOINT /bin/bash -l -c "cd /srv/testapp && service mysql start && rails c"
# ENTRYPOINT /bin/bash -l -c "cd /srv/testapp && rails s -b 0.0.0.0 &"

# RUN echo "downloading ngrok in /opt for setting up localtunnel..."
# RUN cd /opt && wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && unzip ngrok-stable-linux-amd64.zip
# RUN echo "starting localtunnel for http at 3000 port"
# ENTRYPOINT /bin/bash -l -c "cd /opt && ./ngrok http 3000"
