vagrant-chef-mongodb
====================

A Vagrant script framework example that provisions a Chef Server, a ChefDK box, generates a cookbook, then builds 3x mongodb replica set servers, and configures replication between them.  

BACKGROUND: 

I've written this sample script framework while attending the Mongo University M102 "MongoDB for DBAs" course. 

My TARGETS to achieve with this small weekend project have been: 
- to play around with Vagrant bottstrapping in conjunction using Chef as a provisioner. 
- to learn how to set up Chef, provision a Chef Server and a ChefDK box, and configure everything programatically. 
- to create an small cookbook for spawning up MongoDB servers. 
- to build 3x MongoDB boxes with Chef using my own cookbook and recipes created above. 
- to set up replication between the 3x Mongo boxes, using a simple Chef recipe to configure the replica set. 
- to automate all of the above down to a single "vagrant up" command. 
- to sit back and watch the Blinkenlights, as everything comes together, with no interaction required. 
 
NOTES: 

Before you tell me, I DO KNOW that: 
- I've used some quick-and-dirty scripting here and there, some parts could be done in far more elegant ways. I might come back with improvements over time. Right now, the whole thing just works as it is. There is room for improvement, and further extensions. Feel free to contribute! 
- there is a (much-much better!) "mongodb" cookbook available on the Supermarket, and I could have used that one, readily made. Yes, you can download it and use it. Here in this project, I wanted to create a small sample cookbook myself. (See "Targets" above.) 

WHAT'S IN THE BOX: 

After a successful Vagrant run, you will have: 
- 1x Chef Server with 1GB RAM named 'chefsrv' on '10.11.12.100'
- 1x ChefDK Server with knife ready for action with 512MB RAM named 'chefdev' on '10.11.12.99' 
- 3x MongoDB servers with 512MB RAM, named 'mongodb1', 'mongodb2', 'mongodb3' on '10.11.12.101..103"
- the 3x mongodb servers will form a replica set named 'shard01' having 'mongodb3' set as PRIMARY. 

All the subsequent servers will check in to the Chef Server automagically during the build process. 
In the end, you can connect to any of the 5 machines above using the "vagrant ssh machine_name" command. 

The Chef server's web interface is also available. Point your browser to https://10.11.12.100/ , accept the makeshift SSL certificate (you might need to add a security exception) and use the admin credentials found on the first page. 

SYSTEM REQUIREMENTS: 

I wrote this on a Macbook Pro running OS X 10.8.5 with 16GB of RAM, and haven't tested it anywhere else yet. 
Please do, and send me some feedback on how it works. In theory, it *should work* on any machine with the Prerequisites (see below) met. 
Please note that the 5x virtual machines will use 3GB of RAM in total when up and running, plus some overhead from VirtualBox and Vagrant. It should run on a notebook, just make sure that you have 3GB+ free RAM available. 

PREREQUISITES: 

1. VirtualBox needs to be installed on your local machine. No configuration steps needed, just click through the installer. 
I've got the latest stable from: https://www.virtualbox.org/wiki/Downloads
The version I've used was: http://download.virtualbox.org/virtualbox/4.3.14/VirtualBox-4.3.14-95030-OSX.dmg

2. Vagrant needs to be installed on your local machine. Again, no configuation steps, just click through the installer. 
I've got mine from: https://www.vagrantup.com/downloads.html
The version I've used was: https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.3.dmg

3. Chef Client needs to be installed and in a working state on your local machine. Vagrant will use your local Knife in order to add/remove your nodes to/from the Chef server. 
I've got mine from: http://www.getchef.com/chef/install/
Just click on "Chef Client", select your OS, Version, and Architecture, and follow the steps on the page. The Omnibus installer will take care of the rest. 

4. Git needs to be installed and in a working state on your local machine. But otherwise you could not clone this repo anyhow. ;-) 

Once you've got all that in place, you should be ready to go. Yay!!!  

INSTALLATION: 

- Check out this git repo, just place it anywhere on your system, e.g. in your home directory: 

cd ~

git clone git@github.com:sonykus/vagrant-chef-mongodb.git

- Cd into the new directory created: 

cd vagrant-chef-mongodb
- NOTE: If you're not yet familiar with Vagrant, this could be a good moment to take a quick look at the Vagrant documentation: 
https://docs.vagrantup.com/v2/

- Take a quick look at the Vagrantfile and the bootstrap files, to see what you have there. Then type: 

vagrant up

If all goes well, you will see Vagrant downloading the 'chef/centos-6.5' virtualbox image from: https://vagrantcloud.com/chef/centos-6.5/version/1/provider/virtualbox.box
Once the image download is complete, Vagrant will start to build the 5x virtual machines in the following steps:
1. Bootstrap, install, and configure 'chefsrv', your Chef Server. 
2. Bootstrap and install 'chefdev', your ChefDK and Chef client machine.  
- on 'chefdev' it will also download chef-repo, and will configure knife.rb for you. 
- it will create a 'vagrant' Chef user, you can find his initial password sourced inside 'bootstrap_chefdev.sh'. Do not forget to change it at some point later! (ahem.)
- it will generate a cookbook called 'mymongodb', add some recipes, and some templates to it. Find them all sourced inline inside the bootstrap_chefdev.sh file, if you want to change anything. 
- it will upload the cookbook to the Chef server, and it will also export the 'cookbooks' dir into your working directory for your viewing pleasure. 
- it will register all nodes, including itself, onto the chef server. 
- it will create a 'MONGODEV' environment to place the mongo machines into. 
- it will create a new 'mongoserver' role for the mongodb machines and will update all run_lists. 
- after the cooking is done, and the bootstrapping phase is over, 'chefdev' will check itself in with the Chef server. 
3. Bootstrap and install the x3 mongodb servers. 
- bootstrapping is minimal, it will only install Chef Client, and then it hands the machines over to Chef for provisioning. 
4. Using the cookbook we've fabricated above, Chef will deploy and configure mongodb on the 3x mongod servers. 
5. Once the 3rd mongodb server is up, Chef will configure mongodb replication across the 3x mongo servers, using a separate recipe called 'mongod_primary', which will inject a JavaScript configuration file into mongo, in order to complete the installation. 

