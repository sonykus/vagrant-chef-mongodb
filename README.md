vagrant-chef-mongodb
====================

A Vagrant script framework example that provisions a Chef Server, a ChefDK box, generates a cookbook, then builds 3x mongodb replica set servers, and configures replication between them.  

BACKGROUND: 
I've written this sample script framework while attending the Mongo University M102 "MongoDB for DBAs" course. 

My TARGETS to achieve with this small weekend project have been: 
- to play around with Vagrant bottstrapping in conjunction with Chef as a provisioner. 
- to learn how to set up Chef, provision a Chef Server and a ChefDK box, then create an small cookbook for MongoDB servers. 
- to build 3x MongoDB boxes with Chef using my own cookbook and recipes created above. 
- to set up replication between the 3x Mongo boxes, using a simple Chef recipe to configure the replica set. 
- to automate all of the above down to a single "vagrant up" command. 
- to sit back and watch the Blinkenlights, as everything comes together, with no interaction required. 
 
NOTES: 
Before you tell me, I DO KNOW that: 
- I've used some quick-and-dirty scripting here and there, some parts can be done in a far more elegant ways. I might come back with improvements over time. Right now, the whole thing just works, as it is. I know there is room for imporvement, and further extensions. 
- there is a (much-much better!) "mongodb" cookbook up on the Supermarket, and I could have used that one, ready-made. Yes, you can download and use it. Here in this project, I wanted to create a small sample cookbook myself. (See "Targets" above.)

