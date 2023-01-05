#!/bin/bash

# This is the alpha version of this project.

# This version will implement the rest of the tools installation (excluding git).
# Note to self: not all machines have curl installed on them. So when the time comes to check if our External IP has been masked, we might have to consider using curl and not just blindly trust the address we got from Nipe/Torify.
# TL;DR - I might have to add curl to our tool list.
# I dont think I'll use torify in this project. Only nipe.

# For the installation: use "sudo apt-get install [tool] -y".
# The "-y" flag will automatically answer/skip any y/n-input section that may accure.

# Table of color for print: 
# Format : [background;forground
# Sources :
# 	Color codes : https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
# 	SO Post : https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
GRE='\033[0;92m' # Green | on success 32
RED='\033[0;31m' # Red | on errors
RoW='\033[37;41m' # Red on White | on text in error
YEL='\033[0;33m' # Yellow | on status messages
BoY='\033[1;40;93m' # Black on Yello | on input requests
BoG='\033[102;30m' # Black on Green | for highlighting commands 32;40
#biG='\033[1;101;92m' # bold and intense Green | for highlighting commands
GoW='\033[37;42m' # Green on White | for debugging messages 37;42
NEU='\033[0m' # Neutral / No Color

# Common Marks collection:
RS="${RED}[*]${NEU}" # Red Star
RM="${RED}[-]${NEU}" # Red Minus
GS="${GRE}[*]${NEU}" # Green Star
GP="${GRE}[+]${NEU}" # Green Plus
YS="${YEL}[*]${NEU}" # Yellow Star
RWE="${RoW}Error${NEU}" # Red on White Error text
BYI="${YEL}[*]${NEU} ${BoY}INPUT${NEU}" # Black on Yellow Input text
DBG="${GoW}[*]${NEU} ${GoW}DEBUG${NEU}"

# base64 of the script's title in ASCII art:
you="X19fX19fX19fIF9fX19fX18gIF9fX19fX18gX19fX19fX19fClxfXyAgIF9fLyggIF9fX18gXCgg
IF9fX18gXF9fICAgX18vCiAgICkgKCAgIHwgKCAgICBcL3wgKCAgICBcLyAgICkgKCAgIAogICB8
IHwgICB8IChfXyAgICB8IChfX19fXyAgICB8IHwgICAKICAgfCB8ICAgfCAgX18pICAgKF9fX19f
ICApICAgfCB8ICAgCiAgIHwgfCAgIHwgKCAgICAgICAgICAgICkgfCAgIHwgfCAgIAogICB8IHwg
ICB8IChfX19fL1wvXF9fX18pIHwgICB8IHwgICAKICAgKV8oICAgKF9fX19fX18vXF9fX19fX18p
ICAgKV8oICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIA=="

bitch="$(base64 -d <<< "$you")" # Contains visual bug due to double slashes (\\), ignore for now...

root_check () {
	if [ "$(id -u)" -ne 0 ] # Check if the user id is 0 (root id is 0)
	then
		#echo -e "\n[*] Error: Script requires sudo permission to run! Aborting."
		return 3
		exit
	fi
	return 0
}

nipe_location=Null 
starting_path=$(pwd)
ip_addr=$(curl -s https://ifconfig.me)
ip_mask=Null

# /////////////////////////////////////
# 	Start of function zone
# /////////////////////////////////////

introduction () {
	if root_check # Runs root_check func and checks if the exit status (the return value)
	then # If root_check exited successfully (exit status == 0), run the following:
		clear # 1. Clear screen (for clarity)
		echo $poop
		echo -e "$bitch" # 2. Display the ASCII art
	else # If root check exited with a status that isn't 0 (in this case 3), run the following:
		echo -e "$bitch" # 1. Display the ASCII art
		echo -e "\n${RED}[*]${NEU} ${REDWHITE}Error${NEU}: Script requires sudo permission to run. Aborting." # 2. Display Err msg
		exit # 3. Close the program
	fi
}

nipe_check() {
	if locate nipe.pl | sed 's/\(.*\)\//\1 /' | awk {'print $1'}
	then
		nipe_location=$(locate nipe.pl | sed 's/\(.*\)\//\1 /' | awk {'print $1'})
		#echo -e "In locate check"
		return 0
	elif find /opt/ -name "nipe" -type d
	then
		nipe_location=$(find /opt/ -name "nipe" -type d)
		#echo -e "In find check"
		return 0
	else
		#echo -e "I fucked up"
		return 1
	fi
}	

check_tools () {
	is_missing=false # Will change to true if an app is missing.
	declare -a not_installed=() # Empty list, if something is missing it will be added here.
	declare -a tool=(nmap whois sshpass geoiplookup nipe) # List of apps required installed via apt-get
	declare -a git_tool=(nipe) # List of tools required installed via git
	echo -e "\n${YS} Initiating tool check..."
	for val in ${tool[@]}; do # Loop for every item in tool list.
		if [ $val == nipe ] # if the val is nipe, we want to do a different check:
		then
			if nipe_check &> /dev/null
			then
				echo -e "	${GP} $val is installed..."
			else
				echo -e "testing $decuck"
				is_missing=true
				not_installed+=($val)
			fi
		elif ! command -v $val &> /dev/null # If the tool does not exist:
		then
			is_missing=true # 1. change the value of is_missing to true
			not_installed+=($val) # 2. add the tool name variable to not_installed
		else
			echo -e "	${GP} $val is installed..." # Print a message to varify it's existance
		fi
	done
	echo -e "\n${YS} Check completed!\n"
	if $is_missing
	then
		post_check
	else # If the value of is_missing is false:
		echo -e "${GS} All the tools are installed! Let's get to the fun part!" # print a message to varify everything's fine.
		#echo -e "\n[*] This is the good ending of our demo. Now fuck off."
	fi
	exploitation_hub
}

post_check () {
	echo -e "${RS} ${RWE} : The following tools are missing:" # 1. print out the missing tools.
	for val in ${not_installed[@]}; do
		echo -e "	${RM} $val"
	done
	echo -e "\n${YS} Starting installation process...\n"
	installation_hub
	echo -e "\n${GS} All missing tools have been installed! Let's get to the fun part!"
	exploitation_hub
}

installation_hub() { # A "hub" for installing missing tools. The only point of this func is to make the script more friendlly for reading / debugging.
	declare -a apt_tools=(sshpass geoiplookup) # Tools that are installed via apt / apt-get ; unified installation process.
	declare -a to_be_implemented=(nmap whois torify nipe)
	for val in ${not_installed[@]}
	do
		#if [[ ${apt_tools[@]} =~ (^|[[:space:]])"$val"($|[[:space:]]) ]] # credit: https://stackoverflow.com/a/20473191
		if [ $val == sshpass ]
		then # ^ Checks if $val is in $apt_tools list. If it is then:
			apt_inst sshpass
		elif [ $val == geoiplookup ]
		then
			apt_inst geoip-bin
		elif [ $val == whois ]
		then
			echo -e "placeholder $val"
			apt_inst whois
		elif [ $val == nmap ]
		then
			echo -e "placeholder $val"
			apt_inst nmap
		elif [ $val == nipe ]
		then
			nipe_ask
		elif [[ ${to_be_implemented[@]} =~ (^|[[:space:]])"$val"($|[[:space:]]) ]]
		then # PLACEHOLDER: If $val is in $to_be_implemented, then:
			echo -e "${DBG}: Installation for the following tool has not been implemented yet: $val" # PLACEHOLDER: will create more funcs for the rest of the tools
		else # If $val is not in any list / an unexpected result, then:
			echo -e "${RS} ${RWE}: Given tool does not fit any installation function. Aborting." # 1. Echo an error message.
			exit # 2. Abort from the script.
		fi
	done
}

inst_err_apt() {
	echo -e "${RS} ${RWE}: Could not find ${BoG}$1${NEU} in your apt packages."
	echo -e "[*] Pro Hacker Tips:"
	echo -e "	1. Try updating your apt packages by running ${BoG}sudo apt-get update${NEU}, followed by ${BoG}sudo apt-get upgrade${NEU}.\n	2. If the above did not work, try running ${BoG}this_script.sh bi${NEU} to allow this script to install the tool's binary.\n	3. If both options did not work, then git gud ¯\\_(ツ)_/¯"
	echo -e "${RS} Aborting."
	exit
}

apt_inst() {
	echo -e "${YS} Attempting to install ${BoG}$1${NEU} via apt-get. This might take up to a few minutes..."
	if apt-cache search $1 | grep $1 &> /dev/null
	then
		echo -e "${YS} ${BoG}$1${NEU} exists in apt packages. Proceeding to install..."
		apt-get install $1 -y &> /dev/null
		echo -e "${GS} ${BoG}$1${NEU} was installed successfully!\n"
	else
		inst_err_apt $1
	fi
}

nipe_ask() {
	local decision=1
	while [ $desicion == 1 ] # So long as desicion is 1, the while loop will continue.
	do
		echo -e "${BYI} We could not find nipe on your device.\nIf you're certain you already have nipe installed, please input [u] to update ${BoG}locate${NEU} database.\nOtherwise, please input [y] to install ${BoG}nipe${NEU}."
		read -p "    > " selection
		if [ selection == u ] # If the user decides to update his locate database, it will do the following:
		then
			echo -e "${YS} Updating local database. This might take a few minutes..."
			updatedb &> /dev/null # 1. Run updatedb to update his locate database.
			echo -e "${GS} Update completed!\n\n${YS} Attempting to locate nipe..."
			if ! $nipe_check # 2. It will check if nipe exists on the machine. 
			then
				echo -e "${RS} Could not locate ${BoG}nipe${NEU}.\n${YS} Proceeding to install ${BoG}nipe${NEU}."
				nipe_inst # If nipe was still not found on the machine, it will install it.
			fi
			desicion=0 # desicion is set to 0 to cancel the while loop.
		elif [ selection == y ] # If the user decides to install nipe, the script will install nipe.
		then
			nipe_inst
			desicion=0 # desicion is set to 0 to cancel the while loop.
		fi
	done
}

nipe_inst() { # This func is currently for testing perposes. It will run "which nipe" ins order to find if the tool exists on the end user's machine (since nipe (and by extention torify) can only be installed via git). If not found, the script will let the player know that it did not find the tool with "which"
	echo -e "${YS} Attempting to install ${BoG}nipe${NEU} via git. This might take up to a few minutes..."
	#git clone https://github.com/htrgouvea/nipe.git /opt/ $$ cd /opt/nipe/
	echo -e "${GP} Cloned nipe's github repository into /opt/nipe/"
	#cpan install Try::Tiny Config::Simple JSON
	#cd $starting_path
	echo -e "${GP} Installed perl dipendencies..."
	#perl /opt/nipe/nipe.pl install
	echo -e "${GS} ${BoG}nipe${NEU} installation was successful!\n"
	echo -e "${BYI} Would you like to update your db?"
	read -p "    > " update_db
}

demo_input () { # Demo function to check read's functionality and design.
	echo -e "${BYI} This is a test, please give an input back."
	read -p "    > " poop
	echo $poop
	if [ $poop == de ]
	then
		inst_err_apt DEBUG
		exit
	fi
}

exploitation_hub() { # This is the starting func from which all other commends will be issued.
	ex_nipe start # Use nipe to mask IP address.
}

ex_nipe() { # The function to communicate with nipe.pl. Will take args for different functions.
	# 1. start nipe.
	if [ $1 == start ]
	then
		echo -e "${YS} Masking IP with ${BoG}nipe${NEU}..."
		cd $nipe_location && perl nipe.pl start && cd $starting_path
		nipe_ip_addr=$(cd $nipe_location && perl nipe.pl status | grep "Ip:" | awk {'print $3'} && cd $starting_path)
		echo -e "	${GP} Your IP address mask from nipe is $nipe_ip_addr."
		wan_check=$(curl -s https://ifconfig.me)
		echo -e "	${GP} From https://ifconfig.me, your global IP address is $wan_check."
		if [ $nipe_ip_addr == $wan_check ] && [ $wan_check != $ip_addr ]; then
			echo -e "\n${GS} Your IP address has been successfully masked!\n"
			ip_mask=$wan_check
			echo $ip_mask
		else
			echo -e "\n${RS} Your IP address hasn't been masked successfully...\n"
		fi
		#echo $nipe_status
		#while ! [ $nipe_status ]
		#do
		#	cd $nipe_location && perl nipe.pl restart && cd $starting_path
		#done
		#perl ${nipe_location}/nipe.pl start
		#perl ${nipe_location}/nipe.pl status
	# 2. stop nipe.
	elif [ $1 == stop ]
	then
		cd $nipe_location && perl nipe.pl stop && cd $starting_path
		#perl ${nipe_location}/nipe
	# 3. check nipe.
	fi
	# Debuggin the status.
	if ! cd $nipe_location && perl nipe.pl status | grep "[+] Ip:" && cd $starting_path &> /dev/null
	then
		echo -e "${YS} Error accured while attempting to mask IP address, restarting nipe..."
		cd $nipe_location && perl nipe.pl restart | grep "[+] Ip:" && cd $starting_path
	fi
}

# /////////////////////////////////////
# 	End of function zone
# /////////////////////////////////////



main () { # Main function, pretty self explanitory tbh...From this func we call all the other funcions.
	introduction
	check_tools
	ex_nipe stop # Make sure to stop the IP masking at the end of the script!
}

main
