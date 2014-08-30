#!/usr/bin/env bash

# NOTE: You can comment out yum updates to speed up things while testing.
#echo "Updating packages: "
#yum update -y

cd /vagrant
echo "Downloading Chef server: "
wget -nv -nc https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.1.4-1.el6.x86_64.rpm
echo "Installing Chef server: "
rpm -Uvh chef-server-11.1.4-1.el6.x86_64.rpm
echo "Setting up Chef server: "
chef-server-ctl reconfigure

# NOTE: You can comment out chef tests in order to speed up things, but it's recommended to run them once at least.
#echo "Running some basic tests: "
#chef-server-ctl test

echo "Exporting keys: "
cp /etc/chef-server/admin.pem /vagrant
cp /etc/chef-server/chef-validator.pem /vagrant
echo "...DONE!" 


