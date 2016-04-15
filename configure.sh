# Dependencies
sudo apt-get update
sudo apt-get install git postgresql postgresql-contrib build-essential libssl-dev

# Install ruby
git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
rbenv --version || \
  (echo "export PATH=\"\$PATH:\$HOME/.rbenv/bin\"" >> ~/.bashrc && \
   rbenv init - >> ~/.bashrc && \
   source ~/.bashrc)
rbenv install 2.2.3
sudo gem install bundler

# Install node
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
source ~/.bashrc
nvm install 5.1.1

sudo chown deploy:deploy /var/www/

bundle exec rake db:create
