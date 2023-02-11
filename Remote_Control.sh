#!/bin/bash

# Note that this script was tested on Kali Linux, I can't guarantee it will work on other Distros.

# Colors `\(O^O)/` : Source 1
GRE='\033[0;92m' # Green | on success 32
RED='\033[0;31m' # Red | on errors
RoW='\033[37;41m' # Red on White | on text in error
YEL='\033[0;33m' # Yellow | on status messages
YBU='\033[1;4;93m' # Yellow Bold Underline
BoY='\033[1;40;93m' # Black on Yello | on input requests
BoG='\033[102;30m' # Black on Green | for highlighting commands 32;40
GoW='\033[37;42m' # Green on White | for debugging messages 37;42
PUR='\033[1;4;95m' # Purple
NEU='\033[0m' # Neutral / No Color

# Common Marks collection:
RS="${RED}[*]${NEU}" # Red Star
RM="${RED}[-]${NEU}" # Red Minus
GS="${GRE}[*]${NEU}" # Green Star
GP="${GRE}[+]${NEU}" # Green Plus
YS="${YEL}[*]${NEU}" # Yellow Star
YE="${YEL}[!]${NEU}" # Yellow Exclamation mark
RWE="${RoW}Error${NEU}" # Red on White Error text
BYI="${YEL}[*]${NEU} ${BoY}INPUT${NEU}" # Black on Yellow Input text
DBG="${GoW}[*]${NEU} ${GoW}DEBUG${NEU}" # TBH, I forgot I even added this... Oh well :P
RYR="\033[1;4;31;43mREQUIRED\033[0m" # bold+underline Red on Yellow Required

trap ctrl_c INT # Added in order to detect forced abortion of script (ctrl+c)

nipe_location=Null 
starting_path=$(pwd)
if [ -z "$(find $starting_path -name "RC_Results" -type d)" ]; then
	mkdir RC_Results
fi
ip_addr=$(curl -s https://ifconfig.me)
ip_mask=Null

# /////////////////////////////////////
# 	Start of function zone
# /////////////////////////////////////

# Check if the user running the script is root/using sudo + displaying ascii art of the script's name
introduction() {
	if [ "$(id -u)" -ne 0 ]; then # So long as the user id is NOT 0, do NOT run the script!
		figlet -f big $(echo $0 | cut -d / -f2- | cut -d . -f1)
		echo -e "\n${RWE}: Script requires sudo permission to run. Aborting!"
		exit
	else # Else condition can only be when user id == 0.
		#clear
		figlet -f big $(echo $0 | cut -d / -f2- | cut -d . -f1)
		echo -e "\nWritten by [INSERT NAME / LINKEDIN HERE]\n"
	fi
}

# Closing open ends in an event where the user Ctrl+C
function ctrl_c() { # 2*
	echo -e "\n\n${RS} Ctrl+c detected. Aborting!"
	local live_conn=$(find $starting_path/RC_Results/ -type s -name "ssh-*@*:*" | awk -F '/' '{print $NF}' 2> /dev/null)
	if ! [ -z "$live_conn" ]; then # In case the user Ctrl+C'd while in the ex_shh func, we want to sever the connection we had we the remote server and close the session without a shadow of a doubt, lest we'll be compromised.
		echo -e "${RS} Active SSH connection detected, closing now!"
		live_conn=$(echo "$live_conn" | sed 's/@/\ /' | sed 's/:/\ /')
		local name=$(echo "$live_conn" | awk '{print $1}' | cut -d '-' -f2-)
		local addr=$(echo "$live_conn" | awk '{print $2}')
		local port=$(echo "$live_conn" | awk '{print $3}')
		end_ssh $name $addr $port
		echo -e "$(date) - [#] Connection forcfully aborted (Ctrl+C)" >> $starting_path/RC_Results/${name}@${addr}/nr.log
	fi
	ex_nipe stop # Needed here to counter-act the false-positives created when attempting to run the script again after force-exiting the script (nipe wouldn't stop, so the script will detect the masked IP as non-masked IP).
	exit
}

# Since nipe is installed using git clone, it most likely not going to be located under one of the dirs in $PATH, so we need to search for it in a different manner: 1. hoping the user ran updatedb after installing nipe, or 2. running find under the /opt/ directory, since this is where this program is going to install it (because personal preference)
nipe_check() {
	if ! [ -z "$(locate nipe.pl | sed 's/\(.*\)\//\1 /' | awk {'print $1'})" ] # Try to get nipe's path via locate on nipe.pl.
	then
		nipe_location=$(locate nipe.pl | sed 's/\(.*\)\//\1 /' | awk {'print $1'})
		return 0
	elif ! [ -z "$(find /opt/ -name "nipe" -type d)" ] # Try to find a dir called 'nipe' under /opt/.
	then
		nipe_location=$(find /opt/ -name "nipe" -type d)
		return 0
	else
		return 1 # If none of the above worked, return an exit code of 1 (failed)
	fi
}	

# This function checks whether the tools we need are installed on our end, and if they're not, the missing tools are then forwarded to be installed.
check_tools () {
	is_missing=false # Will change to true if an app is missing.
	declare -a not_installed=() # Empty list, if something is missing it will be added here.
	declare -a tool=(sshpass geoiplookup nipe) # List of apps required installed via apt-get
	#declare -a git_tool=(nipe) # List of tools required installed via git
	echo -e "\n${YS} Initiating tool check..."
	for val in ${tool[@]}; do # Loop for every item in tool list.
		if [ $val == nipe ] # if the val is nipe, we want to do a different check:
		then
			if nipe_check &> /dev/null
			then
				echo -e "	${GP} $val is installed..."
			else
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
	#exit
	if $is_missing
	then
		post_check
	else # If the value of is_missing is false:
		echo -e "${GS} All the tools are installed! Let's get to the fun part!\n" # print a message to varify everything's fine.
	fi
	exploitation_hub
}

# Display the missing tools before installing them. 
post_check () {
	echo -e "${RS} ${RWE} : The following tools are missing:" # 1. print out the missing tools.
	for val in ${not_installed[@]}; do
		echo -e "	${RM} $val"
	done
	echo -e "\n${YS} Starting installation process...\n"
	installation_hub
	echo -e "\n${GS} All missing tools have been installed! Let's get to the fun part!\n"
	exploitation_hub
}

# A hub for installing the missing tools. Created in order to make the code more readible (and thus easier to debug)
installation_hub() {
	declare -a apt_tools=(sshpass geoiplookup) # Tools that are installed via apt / apt-get ; unified installation process.
	declare -a to_be_implemented=(nmap whois torify nipe)
	for val in ${not_installed[@]}
	do
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
		#elif [[ ${to_be_implemented[@]} =~ (^|[[:space:]])"$val"($|[[:space:]]) ]]
		#then # PLACEHOLDER: If $val is in $to_be_implemented, then:
		#	echo -e "${DBG}: Installation for the following tool has not been implemented yet: $val" # PLACEHOLDER: will create more funcs for the rest of the tools
		else # If $val is not in any list / an unexpected result, then:
			echo -e "${RS} ${RWE}: Given tool does not fit any installation function. Aborting." # 1. Echo an error message.
			exit # 2. Abort from the script.
		fi
	done
}

# A "cute" error message upon failing to install a tool. Even though this script needs to be fully automated, I believe that it's best to let the end user update their apt on their own.
inst_err_apt() {
	echo -e "${RS} ${RWE}: Could not find ${BoG}$1${NEU} in your apt packages."
	echo -e "[*] Pro Hacker Tips:"
	echo -e "	1. Try updating your apt packages by running ${BoG}sudo apt-get update${NEU}, followed by ${BoG}sudo apt-get upgrade${NEU}.\n	2. Git gud ¯\\_(ツ)_/¯"
	echo -e "${RS} Aborting."
	exit
}

# Install tools from apt.
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

# In case nipe was not found on the device, we give the end user the benefit of the doubt and allow him a chance to run update db and try running nipe_check func once again in order to update the var $nipe_path. If we still couldn't find nipe, we will proceed to install nipe under /opt/nipe/.
nipe_ask() {
	local decision=1
	while [ $decision == 1 ] # So long as decision is 1, the while loop will continue.
	do
		echo -e "${BYI} We could not find nipe on your device.\nIf you're certain you already have nipe installed, please input [y] to update ${BoG}locate${NEU} database.\nOtherwise, please input [n] to install ${BoG}nipe${NEU}."
		read -p $'\033[1;40;93mINPUT\033[0m [y/n] ' selection
		if [ "$selection" == y ] || [ "$selection" == Y ] # If the user decides to update his locate database, it will do the following:
		then
			echo -e "${YS} Updating local database. This might take a few minutes..."
			updatedb &> /dev/null # 1. Run updatedb to update his locate database.
			echo -e "${GS} Update completed!\n\n${YS} Attempting to locate nipe..."
			if ! $nipe_check # 2. It will check if nipe exists on the machine. 
			then
				echo -e "${RS} Could not locate ${BoG}nipe${NEU}.\n${YS} Proceeding to install ${BoG}nipe${NEU} under /opt/ directory."
				nipe_inst # If nipe was still not found on the machine, it will install it.
			fi
			decision=0 # desicion is set to 0 to cancel the while loop.
		elif [ "$selection" == n ] || [ "$selection" == N ] # If the user decides to install nipe, the script will install nipe.
		then
			nipe_inst
			decision=0 # desicion is set to 0 to cancel the while loop.
		else
			continue
		fi
	done
}

# This func clones nipe from github into /opt/ (because this is my script and I decide where to install the tools!)
nipe_inst() {
	echo -e "${YS} Attempting to install ${BoG}nipe${NEU} via git. This might take up to a few minutes..."
	mkdir /opt/nipe
	git clone https://github.com/htrgouvea/nipe.git /opt/nipe/ && cd /opt/nipe/ &> /dev/null # Clone nipe from github under /opt/ and move to the newly created directory.
	echo -e "${GP} Cloned nipe's github repository into /opt/nipe/"
	echo yes | cpan install Try::Tiny Config::Simple JSON &> /dev/null# NEED TO AUTOMATE RESPONSE / EXPECT!!! We need to respond with a 'yes' in this command.
	#cd $starting_path # Go back to the starting path | We need to stay there to run nipe.pl install
	echo -e "${GP} Installed perl dipendencies..."
	perl /opt/nipe/nipe.pl install && cd $starting_path
	echo -e "${GS} ${BoG}nipe${NEU} installation was successful!\n"
	while true; do
		read -p $'\e[1;40;93mINPUT\e[0m Would you like to update your locate DB? [Y/n] ' update_db
		if [[ $update_db == "" ]] || [ $update_db == y ] || [ $update_db == Y ]; then
			echo -e "${YS} Executing updatedb; This might take a few minutes...\n${YS} Do not shut down your PC or force out of the script."
			updatedb
			echo -e "${GS} updatedb completed!"
			break
		elif [ $update_db == n ] || [ $update_db == N ]; then
			echo -e "${YS} updatedb was not executed."
			break
		else
			continue
		fi
	done
	nipe_check
	# Need to add a line/s for running updatedb...
}

# Like in installation hub, this is an all encompassing function from which the commands are executed.
exploitation_hub() {
	ex_nipe start # Use nipe to mask IP address.
	pre_ssh
}

# Same to installation error, a "cute" error message if the end has issues with nipe (from personal experience).
ex_nipe_err() {
	echo -e "\n${RWE} Could not connect to the server."
	echo -e "[*] Pro hacker tip:"
	echo -e "	1. Check your internet connection: Are you connected to the internet?\n	2. Check your firewall (if you have any) or router settings: Maybe your MAC address has been marked and put on a blacklist?\n	3. For VM users: Try to look on what Virtual Network your device is and play around with them.\n	4. I donno, it works on my machine ¯\\_(ツ)_/¯."
	ex_nipe stop # We execute ex_nipe stop to avoid causing the end user any networking issues after the scripts ends + avoiding situations where re-running the script after it was aborted caused the script to recognise the masked IP from nipe as your real IP (and thus getting aborted every time ex_nipe start runs).
	echo -e "\n${RS} Aborting!"
	exit
}

# A func in charge of executing nipe with 2 possible args:
# start - Masking your IP, checking if it's actually hidden (comparing IP from ifconfig.me), retrieving geolocation.
# stop - Stops nipe's IP masking... What else did you expect...?
# One annoying thing about nipe is that (to my knowledge) you cannot run it unless you are inside the same directory where it's located... That's why every command starts with cd to $nipe_location and ends in $starting_path.
ex_nipe() {
	# 1. start nipe.
	if [ $1 == start ]
	then
		echo -e "${YS} Masking IP with ${BoG}nipe${NEU}..."
		cd $nipe_location && perl nipe.pl start && cd $starting_path
		echo -e "	${GS} Started ${BoG}Nipe${NEU}. Attempting to retreive the mask address..."
		declare -i err_cnt=0
		while [[ $(cd $nipe_location && perl nipe.pl status | grep -i "sorry, it was not possible to establish a connection to the server" && cd $starting_path) ]]
		do # If we ever get the error where nipe could not connect to the server, I will start this while loop in an attempt to restart nipe to overcome this error, and if there are still errors, I'll abort the script.
			err_cnt+=1
			if [ $err_cnt -gt 3 ]
			then
				ex_nipe_err
			else
				echo -e "	${YE} Failed to connect to server. Attempting to restart ${BoG}Nipe${NEU}... (${err_cnt}/4)"
				cd $nipe_location && perl nipe.pl restart && cd $starting_path
			fi
		done
		echo -e "	${GP} Successfully retreived masked address!"
		nipe_ip_addr=$(cd $nipe_location && perl nipe.pl status | grep "Ip:" | awk {'print $3'} && cd $starting_path)
		echo -e "	${GP} Your IP address mask from nipe is $nipe_ip_addr."
		wan_check=$(curl -s https://ifconfig.me)
		if ! [ -z "$(echo "$wan_check" | grep -i -w "Forbidden")" ]; then
			echo -e "\n${RS} The IP address we got is blacklisted. Please try again later when nipe will provide a new IP.\n${RS} Aborting!"
			exit
		fi
		echo -e "	${GP} From https://ifconfig.me, your global IP address is $wan_check."
		if [ "$nipe_ip_addr" == "$wan_check" ] && [ "$wan_check" != "$ip_addr" ]; then
			echo -e "\n${GS} Your IP address has been successfully masked!\n"
			ip_mask=$wan_check
			geo_location=$(geoiplookup $ip_mask | cut -d ":" -f2 | sed 's/,/\ /')
			echo -e "${GS} You are currently in $(echo $geo_location | awk {'print $1'}), $(echo $geo_location | awk {'print $2'}). Quite the traveller, are you?\n"
		else
			echo -e "\n${RS} Your IP address hasn't been masked successfully. Aborting.\n"
			cd $nipe_location && perl nipe.pl stop && cd $starting_path
			exit
		fi
	# 2. stop nipe.
	elif [ $1 == stop ]
	then
		cd $nipe_location && perl nipe.pl stop && cd $starting_path
	else
		echo -e "${RWE} Argumental error! Aborting!"
		exit
	fi
}

# This pretty lil' thing asks the user to input information regarding the remote server they wish to connect to (IP, port, username, password) and the targets they wish to scan from the remote server. I've also added the ability to delete targets in case the user made a typo + a dynamic output system that (with the use of lies and deception) helps with visual clearity.
pre_ssh() {
	srv_addr=""
	srv_addr_stat=""
	ssh_port=22
	uname=""
	pass=""
	targets=()
	err=""
	local delete=""
	local finito=1
	local re='^[0-9]+$' # Credit 5
	echo -e "\n"
	while [ $finito != 0 ]
	do
		echo -e "\n${YS} Please fill out the following options by inputing the number followed by the variable:\n(Ex: 1 server.com)"
		# old design
		#
		#echo -e "	1) Remote server address: $srv_addr \n	2) SSH Port: $ssh_port \n	3) Username: $uname \n	4) Password: $pass \n	5) Targets: ${targets[@]} \n	6) Remove a target\n\n	0) Confirm Selection\n"
		#echo -e "$err\n"
		#

		# Check if the variable has a value: if they DON'T, print REQUIRED; else, print the value.
		echo -e "	1) Remote server address: $(if [ -z "$srv_addr" ]; then echo -e "${RYR}"; elif [[ "$srv_addr" =~ ^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ "$srv_addr" =~ ^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ "$srv_addr" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then echo -e "$srv_addr ${PUR}Local IP Address${NEU}"; else echo -e "$srv_addr"; fi)"
		echo -e "	2) SSH Port: $(if [ -z $ssh_port ]; then echo -e "${RYR}"; else echo -e "$ssh_port"; fi)"
		echo -e "	3) Username: $(if [ -z $uname ]; then echo -e "${RYR}"; else echo -e "$uname"; fi)"
		echo -e "	4) Password: $(if [ -z $pass ]; then echo -e "${RYR}"; else echo -e "$pass"; fi)"

		# Check if $targets stores any values: if it DOESN'T, print REQUIRED; if $targets contains more than 5 values, print the first three + a numeral indication for how many other values it stores on top of what's shown; else, print all the values.
		echo -e "	5) Targets: $(if [ -z $targets ]; then echo -e "${RYR}"; elif [ ${#targets[@]} -gt 5 ]; then echo -e "${targets[0]} ${targets[1]} ${targets[2]} and $((${#targets[@]} - 3)) more..."; else echo -e "${targets[@]}"; fi)"
		echo -e "	6) Remove a target\n\n	0) Confirm Selection\n"
		echo -e "$srv_addr_stat"
		echo -e "$err\n"
		read -p $'\e[1;40;93mINPUT\e[0m > ' option
		if ! [[ $option ]]; then err="${YE} No input was received!";  printf "\e[16A$(tput ed)"; continue; fi
		local get_num=$(echo $option | awk {'print $1'})
		local get_option=$(echo $option | awk {'print $2'})
		if [ $get_num == 1 ]
		then
			if [[ "$get_option" =~ ^192\.168\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ "$get_option" =~ ^10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || [[ "$get_option" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
				srv_addr=$get_option
				srv_addr_stat="${YE} ${YBU}NOTICE:${NEU} By connecting to a machine on your LAN, you'll be using your \033[4mUNMASKED\033[0m local IP address!"
				err=""
			else	
				srv_addr=$get_option
				srv_addr_stat=""
				err=""
			fi
		elif [ $get_num == 2 ]
		then
			# Check if the value in $get_opt is a number.
			if ! [[ $get_option =~ $re ]] # Credit 5
			then
				err="${YE} Value must be a number!"
			else
				ssh_port=$get_option
				err=""
			fi
		elif [ $get_num == 3 ]
		then
			uname=$get_option
			err=""
		elif [ $get_num == 4 ]
		then
			pass=$get_option
			err=""
		elif [ $get_num == 5 ]
		then
			targets+=($get_option)
			err=""
		elif [ $get_num == 6 ]
		then
			delete=$get_option
			ind=""
			loc=0
			tmp_targets=()
			for dex in ${!targets[@]}; do
				if [[ ${targets[$dex]} == $delete ]]; then
					ind=${dex}
					unset "targets[$ind]"
					for item in ${targets[@]}; do
						tmp_targets[$loc]=$item
						((++loc))
					done
					targets=()
					for z in ${tmp_targets[@]}; do
						targets+=($z)
					done
					break
				fi
			done
			if [ -z $ind ]; then # If the variable wasn't found in the loop above (hence ind would still be equal to ""/None/null)
				err="${YE} Couldn't find $delete in targets."
				delete="" # Only delete needs to be manually set to reset, since the continue command will skip over the variable resets bellow (which should remain empty since the if above didn't happen), but delete is NOT empty
				printf "\e[16A$(tput ed)"
				continue
			fi
			# The script will always reach here if the item to del exists!
			ind=""
			loc=0
			tmp_targets=()
			delete=""
			err=""
		elif [ $get_num == 0 ]
		then
			if [ -z $srv_addr ]
			then
				err="${YE} Remote server address is required!"
				printf "\e[16A$(tput ed)"
				continue
			elif [ -z $uname ]
			then
				err="${YE} Username is required!"
				printf "\e[16A$(tput ed)"
				continue
			elif [ -z $targets ]
			then
				err="${YE} Targets are required!"
				printf "\e[16A$(tput ed)"
				continue
			elif [ -z $pass ]
			then
				err="${YE} Currently, password is required. Hopefully I will be able to implement dict attack in the future..."
				printf "\e[16A$(tput ed)"
				continue
			fi
			while true
			do
				read -p $'\e[1A\e[K\e[1;40;93mINPUT\e[0m Are you sure all of the information is correct? [Y/n] ' bully_ann
				if [[ $bully_ann == "" ]] || [ $bully_ann == y ] || [ $bully_ann == Y ]
				then
					finito=0
					break 1
				elif [ $bully_ann == n ] || [ $bully_ann == N ]
				then
					break 1
				else
					continue
				fi
			done
		else
			err="${YE} Option number $get_num does not exist!"
		fi
		printf "\e[16A$(tput ed)"
	done
	sleep 2
	ex_ssh $uname $srv_addr $ssh_port $pass
}

# This function initializes the connection to the remote host by starting an SSH session.
# By using the ControlMaster option in OpenSSH (the ssh command) I can keep this session alive until 1) the time I set in ControlPersist runs out, or 2) I force the connection to close (via the end_ssh func).
# The reason for using such a method is to: A) allow the script to print back updates in real-time(~ish) without having to end and restart the connection every time, and B) reduce the amount of noise in the remote server's logs thanks to only using session (instead of constantly starting a new SSH session for every single command).
start_ssh() {
	local name="$1"
	local addr="$2"
	local port="$3"
	local pass="$4"
	local commands="$5"
	if [ -z "$commands" ]; then
		commands=`cat`
	fi
	sshpass -p $pass ssh -T -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath="$starting_path/RC_Results/ssh-%r@%h:%p" -o ControlPersist=$((3 + ${#targets[@]} * 3))m $name@$addr -p $port "$commands" # Note: ControlPersist = 3 minutes (base time to allow us to install whois & nmap if they're not installed) + 3 minutes * number for targets (in order to have enough time to scan every target)
}

# This func is used to send commands to the SSH session we have opened.
# Because it uses the already open session, we can send as many commands we want (even one a a time) and it still won't make any noise in the auth.log file (unless you execute a command with sudo).
mid_ssh() {
	local name="$1"
	local addr="$2"
	local port="$3"
	local commands="$4"
	if [ -z "$commands" ]; then
		commands=`cat`
	fi
	ssh -T -o StrictHostKeyChecking=no -o ControlMaster=auto -o ControlPath="$starting_path/RC_Results/ssh-%r@%h:%p" $name@$addr -p $port "$commands"
}

# The final func in the ssh trio. It's entire purpose is to make sure we close the session after we're done. We do NOT want to leave any strings loose, since it could lead us to being compromised!
end_ssh() {
	local name="$1"
	local addr="$2"
	local port="$3"
	ssh -o ControlPath="$starting_path/RC_Results/ssh-%r@%h:%p" -O "exit" $name@$addr -p $port
}

# In ex_ssh we (hopefully) secure a connection with the remote host and execute commands on it. In this function we also create and fill out both a log about our connection + whois and nmap scan results on the targets we set beforehand.
# This func relays on the 3 functions above (start_ssh, mid_ssh & end_ssh). The reason I've created those unique functions was to bypass the output of the MotD / welcome message you get when connecting to a remote host via SSH.
ex_ssh() {
	local name="$1"
	local addr="$2"
	local port="$3"
	local pass="$4"
	dir_path="$starting_path/RC_Results"
	res_path="$dir_path/${name}@${addr}"
	# Check if $dir_path exists, if not - create it
	if [ -d "$dir_path" ]; then
		echo -e "$GS Directory \"$dir_path\" exists."
	else

		echo -e "$YS Creating a new directory: $dir_path."
		mkdir $dir_path
	fi
	# Check and create remote host dir
	if [ -d "$res_path" ]; then
		echo -e "$GS A directory for $name from $addr already exists."
	else
		echo -e "$YS Creating a directory for remote server."
		mkdir $res_path
		echo -e "$GS Created a new directory: $res_path."
	fi

	# First step connecting to the remote server
	echo -e "$(date) - [#] Connecting to remote server via SSH..." >> $res_path/nr.log
	step1=$(start_ssh $name $addr $port $pass "netstat -nt | grep -i 'established'")
	if [ -z "$step1" ]; then
		echo -e "$RS Remote host is unreachable. Aborting."
		ex_nipe stop
		exit
	fi
	echo -e "$(date) - [#] Connection established" >> $res_path/nr.log
	if ! [ -z "$srv_addr_stat" ]; then # Again, letting the end user know that his IP is not hidden. Also, skipping over netstat command because - as it is been stated before in this script - your local IP address cannot be masked!
	       echo -e "${YS} Attention: You are connected to a remote on your local network. As such, you are using your local IP address which is NOT MASKED!"
	elif [ "$(echo -e \"$step1\" | grep -i $ip_addr)" ]; then # If our real IP exists inside the remote host netstat, abort the connection and the string
		echo -e "$RS IP IS NOT MASKED! ABORTING CONNECTION!"
		end_ssh $name $addr $port
		echo -e "$(date) - [#] Connection forcfully aborted (IP wasn't masked)" >> $res_path/nr.log
		exit
	fi

	# Second step gaining general info on the remote server (uptime, is the user in sudo group, etc)
	step2=$(mid_ssh $name $addr $port << DOC2
echo -e "[uptime] : \$(uptime)"
if id | grep -i "sudo"; then
echo -e "[Sudoer] : True"
else echo -e "[Sudoer] : False"
fi
echo -e "[Address] : \$(curl -s https://ifconfig.me)"
DOC2
)
	issudo=$(echo -e "$step2" | grep -w "\[Sudoer\]" | awk '{print $NF}')
	echo -e "\n$YS General Information:\n"
	echo -e "	$YE Remote Server IP Address: $(echo "$step2" | grep -i -w "\[Address\]" | cut -d : -f2-)"
	echo -e "	$YE Contry: $(geoiplookup $(echo "$step2" | grep -i -w "\[Address\]" | cut -d : -f2- | awk '{print $NF}') | awk '{print $NF}')"
	echo -e "	$YE Uptime: $(echo "$step2" | grep -i -w "\[uptime\]" | cut -d : -f2- | sed 's/^[ \t]*//')"
	if [ $issudo == True ]; then
		echo -e "	$YE Is $name part of sudo group? ${GRE}${issudo}${NEU}"
	else echo -e "	$YE Is $name part of sudo group? ${RED}${issudo}${NEU}"
	fi

	# Third step checking if the required tools are installed on the remote server
	echo -e "\n$YS Checking if necessary tools are installed on remote server..."
	rem_tools=(nmap whois)
	step3=$(mid_ssh $name $addr $port << DOC3
for tool in ${rem_tools[@]}; do
if ! command -v \$tool &> /dev/null; then
echo -e "	$RM \$tool is not installed."
else echo -e "	$GP \$tool is installed!"
fi
done
DOC3
)
	echo -e "$step3"
	rem_missing=$(echo -e "$step3" | grep -i -w "not installed" | awk '{print $2}')

	# Forth step installing the missing tools on the remote service
	if [ "$rem_missing" ]; then
		echo -e "\n$YE Attention: Some of the necessary tools are not installed on the remote server."
		if [ $issudo == True ]; then
			echo -e "	$GP User $name is part of sudo group!\n	Attempting to install tools via apt..."
			for miss in ${rem_missing[@]}; do
				echo -e "$(date) - [#] Installing $miss on remote server via apt" >> $res_path/nr.log
				step4=$(mid_ssh $name $addr $port << DOC4_1
if ! [ -z "\$(echo $pass | sudo -Sp "" apt-cache search $miss | grep -i -w "$miss")" ]; then
echo $pass | sudo -Sp "" apt-get install $miss -y &> /dev/null
echo -e "	$GP Finished installing $miss!"
else echo -e "	$RM Could not install $miss."
fi
DOC4_1
)
				echo -e "$(date) - [#] Finished installing $miss on remote server" >> $res_path/nr.log
			done
		else
			echo -e "	$RM User $name is not part of sudo group."
		fi
	else
		echo -e "\n$GS All required tools are installed on the remote server!"
	fi

	# Fifth step enumerating targets from remote host
	echo -e "\n\n$YS Starting to enumerate targets!"
	for target in ${targets[@]}; do
		for tool in ${rem_tools[@]}; do
			echo -e "$(date) - [#] Starting $tool enum on $target" >> $res_path/nr.log
			step5=$(mid_ssh $name $addr $port "$tool $target")
			echo -e "$(date) - [#] Finished $tool enume on $target" >> $res_path/nr.log
			echo -e "$step5" >> $res_path/${tool}_${target}
			echo -e "$GS Results for $tool enum on $target were saved on: $res_path/${tool}_${target}"
		done
	done

	# Sixth step disconnection
	end_ssh $name $addr $port &> /dev/null
	echo -e "$(date) - [#] Connection ended successfully" >> $res_path/nr.log
	echo -e "\n$GS Closed the SSH connection to $addr."
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

# /////////////////////////////////////
#          Credits / Sources
# /////////////////////////////////////
#
# 1. https://stackoverflow.com/a/28938235 - Colorful output :D
# 2. https://stackoverflow.com/a/71711652 - Catching and running a func on Ctrl+C
# 3.
# 4.
# 5. https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash - Check if val is int
# 6.
# 7.
