#!/usr/bin/env bash

# NOTE: You can comment out yum updates to speed up things while testing. 
#echo "Updating packages: "
#yum update -y

echo "Installing git, plus a few more packages: "
yum install git nano -y

echo "Downloading ChefDK: "
cd /vagrant
wget -nv -nc https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chefdk-0.2.0-2.el6.x86_64.rpm

echo "Installing ChefDK: "
rpm -Uvh chefdk-0.2.0-2.el6.x86_64.rpm
echo "Verifying installation: "
chef verify

echo "Setting ChefDK Ruby as the system Ruby in .bash_profile: "
echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile

echo "Cloning Chef-repo: "
cd ~
git clone git://github.com/opscode/chef-repo.git
echo "Setting up .chef directory, copying keys: "
mkdir .chef
cp /vagrant/chef-validator.pem ~/.chef
echo

echo "Initialising Knife, setting up an initial user: "
echo "A quick-and-dirty workaround as knife does not seem to accept the '--password' command line option anymore..." 
echo 'y0urpassword@here' | knife configure -i -y -s "https://10.11.12.100:443" --admin-client-key /vagrant/admin.pem -r ~/chef-repo --validation-key ~/.chef/chef-validator.pem --defaults
echo "knife[:editor] = '/bin/nano'" >> ~/.chef/knife.rb
echo "^^^ The 3x stdin erros above are expected (due to my ugly hack), and they are safe to disregard. "
echo

echo "Creating a new environment for the mongo boxes: "
knife environment create MONGODEV -d "MongoDB Sandbox Environment"

echo "Creating the 'mymongodb' cookbook: "
echo "This will be simple and brutal, folks, it's for demonstration purposes only! (but hey, it works!)"
echo "If you need a good and elaborate mongodb cookbook, you can download https://supermarket.getchef.com/cookbooks/mongodb" 
echo "But this time I wanted to create a cookbook myself... I know it's a little rough around the edges." 

cd chef-repo
knife cookbook create mymongodb
cd cookbooks
chef generate recipe mymongodb common

cat > mymongodb/recipes/common.rb <<-MYEOF
execute "update_hosts" do
  command 'echo "10.11.12.99 chefdev.yourdomain.org chefdev" >>/etc/hosts; echo "10.11.12.100 chefsrv.yourdomain.org chefsrv" >>/etc/hosts; for i in {1..3}; do echo "10.11.12.10\$i mongodb\$i.yourdomain.org mongodb\$i" >>/etc/hosts; done; touch /var/lock/hosts_updated'
  not_if do ::File.exists?('/var/lock/hosts_updated') end
end

template "/etc/chef/client.rb" do
  source "client.rb.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end
MYEOF

echo "Setting up a (very) basic /etc/client.rb file: "
chef generate template mymongodb client.rb

cat > mymongodb/templates/default/client.rb.erb <<-MYEOF
log_level        :info
log_location     STDOUT
chef_server_url  'https://chefsrv.yourdomain.org/'
validation_client_name 'chef-validator'
MYEOF

echo "Adding mongodb repositories to yum: "
chef generate template mymongodb mongodb.repo

cat > mymongodb/templates/default/mongodb.repo.erb <<-MYEOF
[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
MYEOF

cat > mymongodb/recipes/default.rb <<-MYEOF
include_recipe "mymongodb::common"

template "/etc/yum.repos.d/mongodb.repo" do
  source "mongodb.repo.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end

package "mongodb-org"

template "/etc/mongod.conf" do
  source "mongod.conf.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end

service "mongod" do
  action [:start, :enable]
end
MYEOF

chef generate template mymongodb mongod.conf
echo "Inserting butchered mongod.conf file: "
cat > mymongodb/templates/default/mongod.conf.erb <<-MYEOF
# mongod.conf
# where to log
logpath=/var/log/mongodb/mongod.log
logappend=true
# fork and run in background
fork=true
#port=27017
dbpath=/var/lib/mongo
# location of pidfile
pidfilepath=/var/run/mongodb/mongod.pid
# Listen to local interface only. Comment out to listen on all interfaces. 
#bind_ip=127.0.0.1
# Disables write-ahead journaling
nojournal=false
# Enables periodic logging of CPU utilization and I/O wait
#cpu=true
# Turn on/off security.  Off is currently the default
#noauth=true
#auth=true
# Verbose logging output.
#verbose=true
# Inspect all client data for validity on receipt (useful for developing drivers)
#objcheck=true
# Enable db quota management
#quota=true
# Set oplogging level where n is
#   0=off (default), 1=W, 2=R, 3=both, 7=W+some reads
#diaglog=0
# Ignore query hints
nohints=false
# Enable the HTTP interface (Defaults to port 28017).
httpinterface=false
# Turns off server-side scripting.  This will result in greatly limited functionality
noscripting=false
# Turns off table scans.  Any query that would do a table scan fails.
notablescan=false
# Disable data file preallocation.
noprealloc=false
# Specify .ns file size for new databases.
# nssize=<size>
# Replication Options
# in replicated mongo databases, specify the replica set name here
replSet=shard01
# maximum size in megabytes for replication operation log
oplogSize=1024
# path to a key file storing authentication info for connections between replica set members
#keyFile=/path/to/keyfile
MYEOF

echo "Generating a mongo config script for replication:" 
chef generate template mymongodb mongoconfig.js
echo 'rs.initiate({"_id":"shard01","members":[{"_id":0,"host":"mongodb1.yourdomain.org:27017"},{"_id":1,"host":"mongodb2.yourdomain.org:27017"},{"_id":2,"host":"mongodb3.yourdomain.org:27017"}]})' > mymongodb/templates/default/mongoconfig.js.erb

echo "Generating a special recipe for the primary mongod server:" 
chef generate recipe mymongodb mongod_primary

cat > mymongodb/recipes/mongod_primary.rb <<-MYEOF
include_recipe "mymongodb"

template "/tmp/mongoconfig.js" do
  source "mongoconfig.js.erb"
  mode 0644
  owner "root"
  group "root"
  action :create
end

execute "configure_primary" do
  command "/usr/bin/mongo < /tmp/mongoconfig.js"
end
MYEOF

echo "Uploading cookbook: "
knife cookbook upload mymongodb

echo "Exporting cookbooks directory to /vagrant, just for fun: " 
cd ../
cp -R cookbooks /vagrant

echo "Creating a basic role file: "
mkdir -p /vagrant/roles
echo '{"name":"mongoserver","description":"","json_class":"Chef::Role","default_attributes":{},"override_attributes":{},"chef_type":"role","run_list":["recipe[mymongodb]"],"env_run_lists":{}}' > /vagrant/roles/mongoserver_role.json

echo "Setting up a role: "
knife role from file /vagrant/roles/mongoserver_role.json

echo "Creating basic server node JSON files: "
mkdir -p /vagrant/nodes
for i in {1..3}
do
  echo '{"name":"mongodb'$i'.yourdomain.org","chef_environment":"MONGODEV","run_list":[],"normal":{}}' > /vagrant/nodes/mongodb$i.yourdomain.org.json
done

echo "Reading in mongodb nodes from JSON from the 'nodes' directory: "
c=0
for i in $( ls /vagrant/nodes/mongodb* )
do
  knife node from file $i
  let c++
done

echo "Added $c nodes. "

echo "Associating role with nodes: "
for (( i=1; i<=$c; i++ ))
do
  knife node run_list add mongodb$i.yourdomain.org 'role[mongoserver]'
done

echo "All mongod-s must be up and running in order to initiate a replica set! "
echo "Adding the special recipe to the third mongo server in the cluster: "
knife node run_list add mongodb3.yourdomain.org 'recipe[mymongodb::mongod_primary]'

echo "Creating a node definition and a run_list for ourselves as well: "
echo '{"name":"chefdev.yourdomain.org","chef_environment":"_default","run_list":[],"normal":{}}' > /vagrant/nodes/chefdev.yourdomain.org.json
knife node from file /vagrant/nodes/chefdev.yourdomain.org.json
knife node run_list add chefdev.yourdomain.org 'recipe[mymongodb::common]'

# ...and the inevitable Doge reference:
echo "So Automation! Many WOW!!! Such DONE! "

