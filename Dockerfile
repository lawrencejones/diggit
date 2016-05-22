FROM phusion/passenger-full:0.9.18
MAINTAINER Lawrence Jones "lawrjone@gmail.com"

# Install packages
RUN apt-get update
RUN apt-get install -y cmake

# Set environment variables
ENV HOME /root

# Use baseimage-docker's init process
CMD ["/sbin/my_init"]

# Create diggit dir
ADD . /home/app/diggit
WORKDIR /home/app/diggit
RUN bundle install --jobs 20 --retry 5

# Expose ports to container
EXPOSE 80
EXPOSE 443

# Configure nginx/passenger config
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD docker/diggit.conf /etc/nginx/sites-enabled/diggit.conf

# Enable redis
RUN rm -f /etc/service/redis/down

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
