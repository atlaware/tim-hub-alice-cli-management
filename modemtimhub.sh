#!/bin/bash

##-------------------------CONFIG---------------------------------------

alice="192.168.1.1" # indirizzo del modem, default: 192.168.1.1
user="USERNAME" # user, default admin
pass="PASSWORD" # password
tmp="/tmp/"
#verb="-v"
#proxy="-x "127.0.0.1:9090"" # solo per debug, non abilitare
vermodem="TIM HUB+ (ZTE H388)" # versione del modem su cui ho testato lo script

##------------------------END-CONF---------------------------------------

cd "$(dirname "$0")"

function elablogin(){
	rm $tmp/alice_cookie
	#curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out1.txt http://$alice/
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out2.txt -e "https://$alice/"  "http://$alice/?_type=loginData&_tag=login_entry"
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out3.txt -e "https://$alice/"  "http://$alice/?_type=loginData&_tag=login_token"
	sessionTOKEN=$(jq '.sess_token' $tmp/alice_out2.txt|tr -d "\"")
	xml_root=$(cat $tmp/alice_out3.txt|cut -d '>' -f 2|cut -d '<' -f 1)
	echo -n "$pass$xml_root" > $tmp/shapass
	password=$(sha256sum $tmp/shapass|cut -d ' ' -f1)
	rm $tmp/shapass

	echo $sessionTOKEN 
	echo $xml_root
	echo $password
}
function login() {
	echo -n "TOKEN:"
	echo $sessionTOKEN 
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out4.txt -d "Password=$password&Username=admin&_sessionTOKEN=$sessionTOKEN&action=login" -e "https://$alice/"  "http://$alice/?_type=loginData&_tag=login_entry"
}
function operazione() {
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out.txt -e "https://$alice/" "http://$alice/$1"
}
function operazione_data() { 
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out_data.txt -d "$2" -e "https://$alice/" "http://$alice/$1"
	
}
function main() {
	elablogin
	login
}

# OPERAZIONI
case $1 in 
	wifilist)
		echo "Wifilist"
		main
		operazione ""
		operazione "?_type=menuData&_tag=wlan_homepage_lua.lua&InstNum=5"
		cat $tmp/alice_out.txt
	;;
	info)
		echo "Info"
		main
		operazione "?_type=menuView&_tag=dslWanStatus"
		operazione "?_type=menuData&_tag=dsl_interface_status_lua.lua"
		cat $tmp/alice_out.txt 
	;;
	reboot)
		echo "Reboot"
		main
		operazione "?_type=menuView&_tag=rebootAndReset&Menu3Location=0"
		sessionTOKENtemp=$(echo -n -e $(cat $tmp/alice_out.txt |grep Token|cut -d '"' -f 2|cut -d '"' -f 1))
		operazione_data "?_type=menuData&_tag=devmgr_restartmgr_lua.lua" "IF_ACTION=Restart&Btn_restart=&_sessionTOKEN=$sessionTOKENtemp"
		
		cat $tmp/alice_out_data.txt	
	;;
	stats)   
	echo "stats"
		main
		operazione "?_type=menuView&_tag=dslWanStatus"
		operazione "?_type=menuData&_tag=dsl_interface_status_lua.lua"
		cat $tmp/alice_out.txt
	;;
	*)
	    echo "-------------Gestione Modem TIM HUB-----------------"
	    echo "Editare i parametri di configurazione in testa allo script"
	    echo "Software necessari: jq, sha256sum"
	    echo "Testato su: $vermodem"
            echo "----------------------------------------------------------"
            echo $"Uso: $0 {wifilist|reboot|info}"
            exit 1
esac
