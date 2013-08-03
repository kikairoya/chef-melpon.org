#
# Cookbook Name:: sprout
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'git'

git '/usr/local/sprout' do
  repository 'https://github.com/bolero-MURAKAMI/Sprout.git'
  action :sync
  user 'root'
  group 'root'
end

cron 'update_sprout' do
  action :create
  minute '30'
  command 'cd /usr/local/sprout; git checkout master; git pull'
end
