#! /usr/bin/env bash

set -e
set -u

# Check if there is a network
network_state=$(ping -q -w1 -c1 google.com &>/dev/null && echo online || echo offline)

if [[ online =~ $network_state ]]
then

	# Check if nginx is already installed
	echo "Checking to see if nginx is installed..."
	is_nginx_insalled=$(sudo nginx -t &> /dev/null && printf "Valid\n" || printf "Error\n")

	if [[ dead =~ $is_nginx_installed ]]
	then

		echo ""
		echo "Nginx not installed moving forward!"
		# Setup the signing keys for the nginx server
		echo 'Getting the nginx signing key...'
		sudo wget http://nginx.org/keys/nginx_signing.key

		echo 'Adding the key to apt accepted keys...'
		sudo apt-key add nginx_signing.key

		# Update the entries in the source.list file
		# so we can update our application list with apt and
		# install using apt package installer

		cd /etc/apt

		# Create a copy of the source.list file
		echo 'Creating backup copy of the source.list file'
		sudo cp source.list source.list.bak

		# update the source.list
		echo 'Adding entry to source.list file...'
		echo "
			# Nginx entry
			deb http://nginx.org/packages/ubuntu bionic nginx
			deb-src http://nginx.org/packages/ubuntu bionic nginx" | sudo tee -a /etc/apt/source.list &> /dev/null && echo 'source.list file updated!' || echo 'Error updating the source.list file!'; exit

		# Update and install the server
		echo 'Updating apt package list...'
		sudo apt update 

		echo 'Installing nginx server...'
		sudo apt install nginx

		# Confirm that nginx installed
		echo 'Is nginx running?'
		state=$(sudo service nginx status | grep -o "running")

		if [[ running =~ $state ]]
		then
			# Setup the files to serve
			echo 'Changing into the nginx configuration folder...'
			cd /etc/nginx/conf.d
			# Rename the default config file
			echo ""
			echo 'Rename the default config file'
			sudo mv default.conf default.conf.bak
			# Create a new config file
			echo 'Creating a new config file'
			echo "server {
				 root /home/ubuntu/public_html;
				 location /application1 { }

				 location /images  {
				     root /home/ubuntu/data;

				 }

			      }" | server1.conf &> /dev/null && echo 'New file server1.conf created!' || echo 'Error creating the new config file!'; exit;
			echo ""
			echo 'creating the /home/ubuntu/public_html folder to serve content'
			if [[ ! -d /home/ubuntu/public_html ]]
			then 
				mkdir -p /home/ubuntu/public_html
			else 
				echo ""
				echo 'File already exists so moving forward!'
			fi
			echo 'Creating a sample index.html file with content in it!'
			echo ""
			echo "<!DOCTYPE html>

				<html>
				<head>
				  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
				  <title>Spoon-Knife</title>
				  <LINK href="styles.css" rel="stylesheet" type="text/css">
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
				</html>" | /home/ubuntu/public_html/index.html &> /dev/null && echo 'Index.html created!' || echo 'Error while creating the index.html file'; exit;
			# Now we reload the nginx server with the new configuration
			echo ""
			echo 'Reloading the nginx server with the new config...'
			echo ""
			# Test the configuratin file for errors
			echo 'Testing new nginx configuration...'
			nginx_state=$(sudo nginx -t &> /dev/null && printf "Valid\n" || printf "Error\n")
			if [[ Valid =~ $nginx_state ]]
			then
				sudo nginx -s reload
				echo ""
				echo "Nginx is now installed!"
				echo ""
				echo "Open a browser and and type your aws instance external ip address"
				echo "And you should see your default index.html page"
			else
				echo 'Error in the nginx configuration. Please manually check for syntax errors!'
				echo 'Correct them and reload the server!'
				echo 'Kindly send a mail to udoyen@gmail.com'
				# Remove the server1.conf and use the old default
				if [[ -f /etc/nginx/conf.d/server1.conf ]]
				then
					echo ""
					echo 'Removing the new config file...'
					sudo rm -rf /etc/nginx/conf.d/server1.conf
				fi
				sudo mv /etc/nginx/conf.d/default.conf.bak /etc/nginx/conf.d/default.conf
				echo ""
				echo 'Reloading the server...'
				sudo nginx -s reload		
				exit
			fi
		else
			if [[ dead =~ $state ]]
			then
				echo ""
				echo "The server isn't running, please check the nginx logs!"
				exit 
			fi
		fi

	else
		if [[ running =~ $is_nginx_installed ]]
		then
			echo ""
			echo "Nginx is already installed!"
			echo "Please kindly remove it with the following commands: 'sudo apt purge nginx'!"
			echo "Run this script again!"
			exit
		fi
		exit
	fi
else
	echo ""
	echo "Please an internet connectin is needed to install nginx"
	exit
fi




	
