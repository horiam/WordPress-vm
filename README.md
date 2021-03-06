#WordPress Vagrant VM

Build a Ubuntu 16.04 Vagrant box running WordPress with Apache and MySQL.

##Prerequisites
Vagrant installation : https://www.vagrantup.com/downloads.html
Bash
##Build it
```bash
vagrant up
```
The installation may take a long time depending on your internet connection.
##Access it
Go to http://192.168.33.10/
The page may take some time to load the first time after you build the vagrant box.
##Command line
This WordPress installation uses the REST API plugin so you can access it with any rest client. 
The complete description of the API is here : http://v2.wp-api.org/reference/posts/
For convenience bash functions are provided to access the api. To use them go into the project directory after the vagrant box is built and run:
```bash
. functions
```
To list all the posts:
```bash
wpls
```
To add a new post from a json file:
```bash
wpadd test.json
```
To remove a post by number:
```bash
wprm 1
```

### Or with curl
For example list all the posts with curl:
```bash
curl http://192.168.33.10/wp-json/wp/v2/posts
```
Add a new post:
```bahs
curl -u bob:bob -X POST  -H "Content-Type: application/json" http://192.168.33.10/wp-json/wp/v2/posts -d '{"title":"My new post", "status":"publish"}' 
```
Or by passing a file instead:
```bash
curl -u bob:bob -X POST  -H "Content-Type: application/json" http://192.168.33.10/wp-json/wp/v2/posts -d @file.json
```
Remove post number number 3:
```bash
curl -u bob:bob -X DELETE http://192.168.33.10/wp-json/wp/v2/posts/3
```

##Customisation
You can customise the WordPress user for the install **before** running *vagrant up* by changing the **user**, **password** or **blog name** in *wpinstall* file provided. 
