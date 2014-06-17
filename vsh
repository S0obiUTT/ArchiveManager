#!/usr/bin/env bash
set -f # avoid bash intrepretation
#set -x

#########################################
#										#
#	@Author : Thibault Soubiran			#
#	@Date   : 12/05/2014				#
#	@Synop  : Client vsh, gestion arch 	#
#										#
#########################################

declare -r archNotFound="ARCHNOTFOUND"

function usage {
	echo -e "Usage : $0 [OPTION] [SERVER] [PORT] [ARCHIVE]\n"
	echo -e "\t -list    : list archive on the server"
	echo -e "\t -browse  : browse archive on the server"
	echo -e "\t -extract : extract the archive\n"
}

# Check if the path is absolute
# $1 - Path to check
function isPathAbsolute {
	if [[ ${1:0:1} == "/" ]]; then
		echo "1"
	else
		echo "0"
	fi

}

# Get the path with ".." substitution
# $1 - path
function getPathSubstitution {
	local argSplit=(${1//\// })
	local i=0
	local nbRm=0

	for rep in "${argSplit[@]}" ;do
		if [[ $rep == ".." ]] && (( i != 0)); then
			unset argSplit[$((i-2*nbRm-1))]
			unset argSplit[$i]
			if (( i-2 >= 0 )) && [[ ${argSplit[i-2]} != "" ]];then
				((nbRm++))
			fi
		elif [[ $rep == ".." ]] && (( i == 0)) || [[ $rep == "." ]]; then
			unset argSplit[$i]
			if (( i-2 >= 0 )) && [[ ${argSplit[i-2]} != "" ]];then
				((nbRm++))
			fi
		fi
		((i++))
	done

	local IFS="/"
	echo "/${argSplit[*]}"

}

# Get full path of the argument
# $1 - basic path
# $2 - file/folder argument
function getFullPathFile {
	local path="$1"
	local arg="$2"

	# if the path is absolute
	if (( $(isPathAbsolute $arg) )); then
		getPathSubstitution "$arg"

	# if the path is relative
	else
		# if last caracter is "/"
		if [[ ${path: -1:1} == "/" ]]; then
			getPathSubstitution "$path$arg"
		else
			getPathSubstitution "$path/$arg"
		fi

	fi
}

# Send browse command to the server
# $1 - command to send
# $2 - argument of the command
function sendBrowseCmd {
	nc "$server" "$port" <<< "browse $archiveName $1 $2" 2>&1
}

# List all archives on the server
function list {
	nc "$server" "$port" <<< list

}

# Open a shell to browse the archive
function browse {

	# send a dummy command to test if the archive is present
	if [[ $(sendBrowseCmd cd /) == $archNotFound ]]; then
		echo "$archiveName : archive not found"
		return;
	fi 

	declare -r dirNotFound="DIRNOTFOUND"
	declare -r fileNotFound="FILENOTFOUND"

	local path="/"
	local prompt="vsh:$path> "

	read -p "$prompt" cmd
	cmd=(${cmd// / }) # split(" ")

	# loop until command quit
	while [[ ${cmd[0]} != "exit" ]]; do
		case ${cmd[0]} in
			"cd" )
				# if there is only one argument
				if (( ${#cmd[@]} == 2 )); then
					pathToCd="$(getFullPathFile $path ${cmd[1]})"

					resp="$(sendBrowseCmd ${cmd[0]} $pathToCd)"

					# if the file is not in the archive
					if [[ $resp == $dirNotFound ]]; then
						echo "${cmd[1]} : not found"

					else
						path="$pathToCd"

					fi

				# if there is many arguments
				elif (( ${#cmd[@]} > 2 )); then
					echo "${cmd[0]}: too much argument"

				fi
				;;

			"pwd" )
				echo "$path"
				;;

			"ls" )
				# if there are no arguments
				if (( ${#cmd[@]} == 1 )); then
					resp="$(sendBrowseCmd ${cmd[0]} $path)\n"
					echo -e "$resp"

				# if there is only one argument
				elif (( ${#cmd[@]} == 2 )); then
					pathToList="$(getFullPathFile $path ${cmd[1]})"

					resp="$(sendBrowseCmd ${cmd[0]} $pathToList)"

					if [[ $resp == $dirNotFound || $resp == $fileNotFound ]]; then
						echo "${cmd[1]} : not found"

					else
						echo -e "$resp\n"
					fi

				# if there is an argument
				elif (( ${#cmd[@]} > 2 )); then
					for elem in "${cmd[@]:1}"; do
						echo -e "$elem:"
						pathToList="$(getFullPathFile $path $elem)"

						resp="$(sendBrowseCmd ${cmd[0]} $pathToList)"

						if [[ $resp == $dirNotFound || $resp == $fileNotFound ]]; then
							echo "${cmd[1]} : not found"

						else
							echo -e "$resp\n"
						fi
					done

				fi
				;;

			"cat" )
				# if there is only one argument
				if (( ${#cmd[@]} == 2 )); then
					pathToCat="$(getFullPathFile $path ${cmd[1]})"

					resp="$(sendBrowseCmd ${cmd[0]} $pathToCat)"

					# if the file is not in the archive
					if [[ $resp == $dirNotFound || $resp == $fileNotFound ]]; then
						echo "${cmd[1]} : not found"

					else
						echo "$resp"
					fi

				# if there are many arguments
				elif (( ${#cmd[@]} > 2 )); then
					for elem in "${cmd[@]:1}"; do
						pathToCat="$(getFullPathFile $path $elem)"

						resp="$(sendBrowseCmd ${cmd[0]} $pathToCat)"

						# if the file is not in the archive
						if [[ $resp == $dirNotFound || $resp == $fileNotFound ]]; then
							echo "${cmd[1]} : not found"

						else
							echo -e "$resp\n"
						fi
					done

				# if there are no arguments
				else
					echo "${cmd[0]}: no argument"

				fi
				;;

			"rm" )
				if (( ${#cmd[@]} == 2 )); then
					pathToRm="$(getFullPathFile $path ${cmd[1]})"

					resp="$(sendBrowseCmd ${cmd[0]} $pathToRm)"

					# if the file is not in the archive
					if [[ $resp == $dirNotFound || $resp == $fileNotFound ]]; then
						echo "${cmd[1]} : not found"

					else
						echo "${cmd[1]} : successfully removed"
					fi

				# if there are many arguments
				elif (( ${#cmd[@]} > 2 )); then
					for elem in "${cmd[@]:1}"; do
						pathToRm="$(getFullPathFile $path $elem)"

						resp="$(sendBrowseCmd ${cmd[0]} $pathToRm)"

						# if the file is not in the archive
						if [[ $resp == $dirNotFound || $resp == $fileNotFound ]]; then
							echo "${cmd[1]} : not found"

						else
							echo "$elem : successfully removed"
						fi
					done;

				else
					echo "${cmd[0]}: no argument"

				fi
				;;

			"" )
				;;

			"exit")
				return;
				;;

			* )
				echo "command not found : ${cmd[0]}"
				;;
		esac

		# display shell
		local prompt="vsh:$path> "
		read -p "$prompt" cmd
		cmd=(${cmd// / }) # split(" ")

	done
}

# Extract a specific archive
function extract {
	resp="$(nc "$server" "$port" <<< "extract $archiveName")"

	if [[ $resp == $archNotFound ]]; then
		echo "$archiveName : archive not found"

	else
		arch=$(mktemp)
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

if ! [[ $port =~ ^[0-9]+$ ]] && (( port > 0 && port <= 65535)); then
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
	* )
		usage
		exit 3
		;;
esac