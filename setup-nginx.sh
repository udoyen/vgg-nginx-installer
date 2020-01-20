
#! /usr/bin/env bash

################################################################
# Use and modify but please kindly acknowledge the writer of   #
# of this script. George Udosen                                #
# NOTE: that it should not be used in production settings as it#
# was created for testing nginx installation in development    #
# environment                                                  #
################################################################

set -u

# Check if there is a network
network_state=$(ping -q -w1 -c1 google.com &>/dev/null && echo online || echo offline)

#if [[ online =~ $network_state ]]
#then
#	echo "No internet suitable  connection"
#	exit
#fi
# Set the Ubuntu user or the name of the user
# you are using to create this. I used ubuntu
# as this is the default user on the ubuntu aws
# instance

UBUNTU=ubuntu

# Check if nginx is already installed
echo "Checking to see if nginx is installed..."
is_nginx_installed=$(dpkg -l 2> /dev/null | grep -io nginx)
is_nginx_installed_2=$(service nginx status 2> /dev/null | grep -io nginx)

if [[ -z  "$is_nginx_installed" || -z "$is_nginx_installed_2" ]]
then

	echo "#################################################"
	echo "Nginx not installed moving forward!"
	# Setup the signing keys for the nginx server
	echo 'Getting the nginx signing key...'
	cd /tmp && sudo wget http://nginx.org/keys/nginx_signing.key

	echo 'Adding the key to apt accepted keys...'
	sudo apt-key add nginx_signing.key

	# Update the entries in the sources.list file
	# so we can update our application list with apt and
	# install using apt package installer

	cd /etc/apt

	# Create a copy of the sources.list file
	echo 'Creating backup copy of the sources.list file'
	sudo cp sources.list sources.list.backup

	# update the sources.list
	echo 'Adding entry to sources.list file...'
	if [[ ! $(grep -io nginx /etc/apt/sources.list) ]]
	then
		echo -e "# Nginx entry \ndeb http://nginx.org/packages/ubuntu bionic nginx\ndeb-src http://nginx.org/packages/ubuntu bionic nginx" | sudo tee -a /etc/apt/sources.list &> /dev/null && echo 'sources.list file updated!' || echo 'Error updating the sources.list file!' || exit
	fi

	# Update and install the server
	echo 'Updating apt package list...'
	sudo apt update 

	echo 'Installing nginx server...'
	sudo apt install nginx -y

	# Confirm that nginx installed
	echo 'Is nginx running?'
	state=$(sudo service nginx status | grep -o "running")

	if [[ running =~ $state ]]
	then
		# Setup the files to serve
		echo 'Changing into the nginx configuration folder...'
		cd /etc/nginx/conf.d
		# Rename the default config file
		echo "#################################################"
		echo 'Rename the default config file'
		sudo mv default.conf default.conf.backup
		# Create a new config file
		echo 'Creating a new config file'
		echo "server {
			 root /home/$UBUNTU/public_html;
			 location /application1 { }

			 location /images  {
			     root /home/$UBUNTU/data;

			 }

		      }" | sudo tee server1.conf &> /dev/null && echo 'New file server1.conf created!' || echo 'Error creating the new config file!' || sed -i.bak '/^\#\s*Nginx\s*entry/,$d' /etc/apt/sources.list || exit
		echo "#################################################"
		echo "creating the /home/$UBUNTU/public_html folder to serve content"
		if [[ ! -d /home/$UBUNTU/public_html ]]
		then 
			echo 'Creating a sample index.html file with content in it!'
			mkdir -p /home/$UBUNTU/public_html
		else 
			echo "#############################################"
			echo 'Index.html file already exists so moving forward!'
		fi
		echo "#################################################"
		echo "<!DOCTYPE html>

			<html>
			<head>
			  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"/>
			  <title>Virtual Internship Program</title>
			  
			</head>

			<body>

			<!-- Feel free to change this text here -->
			<p>
			  VENTURE GARDEN GROUP
			</p>
			<p>
			  Made with love...
			</p>

			</body>
			</html>" | tee /home/$UBUNTU/public_html/index.html &> /dev/null && echo 'Index.html created!' || echo 'Error while creating the index.html file' || exit
		# Now we reload the nginx server with the new configuration
		echo "#################################################"
		echo "Change ownership of the public_html folder and contents"
		sudo chown -R "$UBUNTU":"$UBUNTU" /home/"$UBUNTU"/public_html/index.html
		echo "#################################################"
		echo 'Reloading the nginx server with the new config...'
		echo "#################################################"
		# Test the configuratin file for errors
		echo 'Testing new nginx configuration...'
		nginx_state=$(sudo nginx -t &> /dev/null && printf "Valid\n" || printf "Error\n")
		if [[ Valid =~ $nginx_state ]]
		then
			sudo nginx -s reload
			echo "#################################################"
			echo "Starting Nginx server..."
			sudo service nginx start
			echo "#################################################"
			echo "Nginx is now installed!"
			echo "#################################################"
			echo "Open a browser and and type your aws instance external ip address"
			echo "And you should see your default index.html page"
		else
			echo 'Error in the nginx configuration. Please manually check for syntax errors!'
			echo 'Correct them and reload the server!'
			echo 'Kindly send a mail to udoyen@gmail.com'
			# Remove the server1.conf and use the old default
			if [[ -f /etc/nginx/conf.d/server1.conf ]]
			then
				echo "################################################"
				echo 'Removing the new config file...'
				sudo rm -rf /etc/nginx/conf.d/server1.conf
			fi
			sudo mv /etc/nginx/conf.d/default.conf.backup /etc/nginx/conf.d/default.conf
			echo "#################################################"
			echo 'Reloading the server...'
			sudo nginx -s reload	
			echo "#################################################"
			echo "Restarting the server..."
			sudo service nginx start
			exit
		fi
	else
		if [[ dead =~ $state ]]
		then
			echo "#################################################"
			echo "The server isn't running, please check the nginx logs!"
			exit 
		fi
	fi

else
		echo "#################################################################"
		echo "Nginx is already installed!"
		echo "Please kindly remove it with the following commands: 'sudo apt purge nginx'!"
		echo "Run this script again!"
		exit
fi

