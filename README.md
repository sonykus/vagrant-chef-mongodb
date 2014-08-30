vagrant-chef-mongodb
====================

A Vagrant script framework example that provisions a Chef Server, a ChefDK box, generates a cookbook, then builds 3x mongodb replica set servers, and configures replication between them.  

BACKGROUND: 

I've written this sample script framework while attending the Mongo University M102 "MongoDB for DBAs" course. 

My TARGETS to achieve with this small weekend project have been to: 
- play around with Vagrant using Chef as a provisioner. 
- learn how to set up Chef, provision a Chef Server and a ChefDK box, and how to configure everything programatically. 
- create an small cookbook for spawning up MongoDB servers. 
- build 3x MongoDB boxes with Chef using my own cookbook and recipes created above. 
- set up replication between the 3x Mongo boxes, using a simple Chef recipe to configure the replica set. 
- automate all of the above down to a single "vagrant up" command. 
- sit back and watch The Blinkenlights as everything comes together, with no interaction required. 
 
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

Each machine will check in to the Chef Server automagically during the build process. 
In the end, you can connect to any of the 5 machines above using the "vagrant ssh machine_name" command. 

The Chef server's web interface will be also available. Point your browser to https://10.11.12.100/ , accept the makeshift SSL certificate (you might need to add a security exception) then use the admin credentials found on the first page. 

SYSTEM REQUIREMENTS: 

I wrote this on a Macbook Pro running OS X 10.8.5 with 16GB of RAM, and I haven't tested it anywhere else yet. 
Please do test it, and send me some feedback on how it works. In theory, it *should work* on any machine with the Prerequisites (see below) met. 
Please note that the 5x virtual machines will use 3GB of RAM in total when up and running, plus some overhead for VirtualBox and Vagrant. It should run on a notebook, just make sure that you have 3GB+ free RAM available. 

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

WHAT WILL IT DO? : 

If all goes well, you will see Vagrant downloading the 'chef/centos-6.5' virtualbox image from: https://vagrantcloud.com/chef/centos-6.5/version/1/provider/virtualbox.box

Once the image download is complete, Vagrant will start to build out the 5x virtual machines in the following steps:

- bootstrap, install, and configure 'chefsrv', your Chef Server. 
- bootstrap and install 'chefdev', your ChefDK and Chef client machine.  
- on 'chefdev' it will also download chef-repo, and will configure knife.rb for you. 
- it will create a 'vagrant' Chef user, you can find his initial password sourced inside 'bootstrap_chefdev.sh'. Do not forget to change it at some point later! (ahem.)
- it will generate a cookbook called 'mymongodb', then add some recipes and some templates to it. Find them all sourced inline inside the bootstrap_chefdev.sh file, if you would like to change anything. 
- it will upload the cookbook to the Chef server, and it will also export the 'cookbooks' dir into your working directory for your viewing pleasure. 
- it will register all nodes, including itself, onto the chef server. It will export the JSON file node definitions in your working directory under the 'nodes' directory, if you want to review them. 
- it will set up a 'MONGODEV' environment to place the mongo machines into. 
- it will create a new 'mongoserver' role for the mongodb machines and will update all run lists accordingly. It will export the definition into the 'roles' directory, for later review. 
- after the cooking is done, and the bootstrapping phase is over, 'chefdev' will check itself in with the Chef server and run its own run_list. 
- bootstrap and install the x3 mongodb servers. 
- bootstrapping will be minimal, it will only install Chef Client, after which it hands them over to Chef for provisioning. 
- using the cookbook we've created above, Chef will set up the mongodb repo, and then deploy and configure mongod on the 3x mongo servers. 
- once the 3rd mongodb server is up, Chef will configure mongodb replication across the 3x mongo servers, using a separate recipe called 'mymongodb::mongod_primary'. The recipe will inject a JavaScript configuration file via the mongo console, in order to complete the installation. 

ONCE YOU'RE ALL DONE: 

- You can verify your installation by connecting to the machines, using "vagrant ssh machine_name" 
- You can check out the state of the mongodb replication by logging on to any of the mongod machines, and typing 'mongo'
- From the mongo console, you can issue your favourite commands like: 

rs.conf() , db.isMaster() , or rs.status() , in order to check out the state of the replica set. 

You'll notice that 'mongodb3' box has become PRIMARY. This is due to the fact that in mongo you cannot configure replication before all your boxes are up and running. So we've run that recipe on the 3rd box, as the last step. If this *annoys you* in any way (although it won't matter too much in real life situations), you could change the Vagrantfile to bring up the mongo boxes in reverse order. Then update 'bootstrap_chefdev.sh' and have it apply the 'mongod_primary" recipe to the first server. That's it, no big deal, yo. 

The name of the replica set has been preconfigured to "shard01". You can change this in /etc/mongod.conf alongside with all the other config options, or even better, find it in 'bootstrap_chefdev.sh' where the cookbook is sourced from. Yes, these could all be exported into nice global variables, but that is a bit beyond the scope of this quick weekend project. Okay, maybe I'll do it. Next weekend. Maybe. 

WHAT ELSE COULD YOU DO? 

- Extend your Vagrant with plugins linking it to your favourite cloud service provider's PaaS API. Set up your keys and authentication tokens accordingly, then fire up the boxes in the cloud, instead of running them on your local machine. 
- Fire up a dozen or more machines, create some recipes for 'mongos' and 'mongo config servers' and build a sharded cluster! Hmm, I might even do that, but on another weekend. 

FINALLY: 

Thanks a lot if you have read this far! Now go hack through those scripts see how they have been done, and play with that thing for a while. Send me some feedback, if you feel like. 

ENJOY! ;-) 
