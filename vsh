#!/usr/bin/env bash
#set -x

#########################################
#										#
#	@Author : Thibault Soubiran			#
#	@Date   : 12/05/2014				#
#	@Synop  : Client vsh, gestion arch 	#
#										#
#########################################

function usage {
	echo -e "Usage : $0 [OPTION] [SERVER] [PORT] [ARCHIVE]\n"
	echo -e "\t -list    : list archive on the server"
	echo -e "\t -browse  : browse archive on the server"
	echo -e "\t -extract : extract the archive\n"
}

function list {
	nc "$server" "$port" <<< list
	
}

function browse {
	# connect to the server
	# send browse command

	local prompt="vsh> "
	local path="/"
	
	read -p "$prompt" cmd
	cmd=(${cmd// / }) # split(" ")

	# loop until command quit
	while [[ ${cmd[0]} != "quit" ]]; do
		case ${cmd[0]} in
			"cd" )

				# if there is only one argument
				if (( ${#cmd[@]} == 2 )); then
					resp="$(nc "$server" "$port" <<< ${cmd[0]} ${cmd[1]})"

					# if the file is not in the archive
					if [[ $resp == "NOTFOUND" ]]; then
						echo "$path : not found"

					# if the path is absolute
					elif [[ ${cmd[1]:0:1} == "/" ]]; then
						path="${cmd[1]}"

					# if the path is relative
					else
						path="$path${cmd[1]}"

					fi

				# if there is many arguments
				elif (( ${#cmd[@]} > 2 )); then
					# TODO : manage argument with specials caracters
					true;

				else
					echo "An unexpected error occurred"

				fi
				;;

			"pwd" )
				echo "$path"
				;;

			"ls" )
				local resp;

				# if there are no arguments
				if (( ${#cmd[@]} == 1 )); then
					resp="$(nc "$server" "$port" <<< ${cmd[0]} $path)"

				# if there is an argument
				elif (( ${#cmd[@]} == 2 )); then
					resp="$(nc "$server" "$port" <<< ${cmd[0]} ${cmd[1]})"
				else
					# TODO : manage argument with specials caracters
					true;

				fi

				echo -e "$resp""\n"
				;;

			"cat" )
				# TODO : cat
				;;

			"rm" )
				# TODO : rm
				;;
			* )
				echo "command not found : ${cmd[0]}"
				;;
		esac

		# display shell
		read -p "$prompt" cmd
		cmd=(${cmd// / }) # split(" ")

	done
}

function extract {
	resp="$(nc "$server" "$port" <<< "extract" "$archiveName")"

	if [[ $resp == "NOTFOUND" ]]; then
		echo "$archiveName : not found"

	else
		arch=$(mktemps)
		echo "$resp" > "$arch"
		./tools/extractArchive "$arch" "$(pwd)"

	fi
}

if ! (( $# == 3 || $# == 4 )); then
	usage
	exit 1
fi

server="$2"
port="$3"
archiveName="$4"

if ! [[ $port =~ ^[0-9]+$ ]] && (( port >= 0 && port <= 65535)); then
	echo "$0: $port: is not a valid number"
	exit 2
fi

case "$1" in
	-list|-l )
		list
		;;
	-browse|-b )
		browse
		;;
	-extract|-x )
		extract
		;;
	*)
		usage
		exit 3
		;;
esac