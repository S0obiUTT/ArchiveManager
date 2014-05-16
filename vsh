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
	echo -e "Usage : $0 [OPTION] [ARCHIVE]\n"
	echo -e "\t -list    : list archive on the server"
	echo -e "\t -browse  : browse archive on the server"
	echo -e "\t -extract : extract the archive\n"
	exit 1
}

function list {
	# connect to the server
	# send list command
	
	respArray=(${resp//,/ }) # split(",")
	for a in "${respArray[@]}"; do
		echo "$a"
	done
}

function browse {
	# connect to the server
	# send browse command
	
	read -p "vsh> " cmd
	local path

	# loop until command quit
	while [[ $cmd != "quit" ]]; do
		case "$cmd" in
			"cd" )
				;;

			"pwd" )
				;;

			"ls" )
				;;

			"cat" )
				;;

			"rm" )
				;;
		esac
		# display shell
		read -p "vsh> " cmd
	done

		# send command to serv
		# display response
	true;
}

function extract {
	# connect to the server
	# send extract command
	# get the file
	# extract
	true;
}

if ! (( $# == 3 || $# == 4 )); then
	usage
fi

declare server="$2"
declare port="$3"

if ! [[ $port =~ ^[0-9]+$ ]]; then
	echo "$0: $port: is not a valid number"
	exit 2
fi


case $1 in
	-list|-l )
		list;
		;;
	-browse|-b )
		declare archiveName="$4"
		browse;
		;;
	-extract|-x )
		declare archiveName="$4"
		extract;
		;;
	*)
		usage
		;;
esac