#!/usr/bin/env bash
#set -x

#########################################
#										#
#	@Author : Kevin Personnic			#
#	@Date   : 17/05/2014				#
#	@Synop  : Server vsh, gestion arch 	#
#										#
#########################################

function usage {
	echo -e "Usage : $0 {PORT}"
	exit 1
}

if (( $# != 1 ))
then
	usage
fi


for((;;));
do
	nc -vlp $1 -e controller_vsh;
done
