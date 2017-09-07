#!/usr/bin/env bash

#Install needed gems

gem install octokit
gem install colorize

#Donwload cath-report script
echo "Downloading catch-reports.rb"

curl -O https://liferay-labs.github.io/reports-catcher/catch-reports.rb

chmod +x catch-reports.rb

#Run cath-report script

RUBY_VERSION=$(ruby --version | awk '{print $2}')

echo "Ruby version $RUBY_VERSION"

if [[ $RUBY_VERSION == "1"* ]]; then
  echo "Updating Ruby version to 2.x"
 rvm use 2.0 --install --binary --fuzzy
fi

echo "Runing scripts"

ruby ./catch-reports.rb
