#! /bin/bash

servername=$2
port=$3

if [ $1 = "-list" ]; then
	echo "list"
elif [ $1 = "-browse" ]; then
for((;;))
do
       	read -p "vsh:> " cmd
       	echo $cmd | nc -v $servername $port;
done
elif [ $1 = "-extract" ]; then
	echo "extract"
else
	echo "erreur dans la commande"
fi
