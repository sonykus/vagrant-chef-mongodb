#!/usr/bin/env bash

# NOTE: You can comment out yum updates to speed up things while testing.
#echo "Updating packages: "
#yum update -y

echo "Installing Chef client: "
curl -L https://www.opscode.com/chef/install.sh | bash

echo "...DONE!" 

