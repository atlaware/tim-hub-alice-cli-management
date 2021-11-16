#!/bin/bash

##-------------------------CONFIG---------------------------------------

alice="192.168.1.1" # indirizzo del modem, default: 192.168.1.1
user="admin" # user, default admin
pass="password" # password
tmp="/tmp/"
#verb="-v"
#proxy="-x "127.0.0.1:9090"" # solo per debug, non abilitare
vermodem="POSTE ITALIANE H2640 PMZHP_1.0.1_001" # versione del modem su cui ho testato lo script

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
	rm $tmp/alice_out2.txt
	rm $tmp/alice_out3.txt
	rm $tmp/shapass

	echo $sessionTOKEN 
	echo $xml_root
	echo $password
}
function login() {
	echo -n "TOKEN:"
	echo $sessionTOKEN 
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out4.txt -d "Password=$password&Username=admin&_sessionTOKEN=$sessionTOKEN&action=login" -e "https://$alice/"  "http://$alice/?_type=loginData&_tag=login_entry" 
	rm $tmp/alice_out4.txt
}
function operazione() {
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out.txt -e "https://$alice/" "http://$alice/$1"
}
function operazione_data() { 
	curl $verb -k -m 10 -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out_data.txt -d "$2" -e "https://$alice/" "http://$alice/$1"
}
function nowInMs() {
  echo "$(($(date +'%s * 1000 + %-N / 1000000')))"
}
function main() {
	elablogin
	login
}

TIMESTAMP="$(nowInMs)"

# OPERAZIONI
case $1 in 
	wlandhcp)
		echo "Wlan DHCP"
		main
		operazione "?_type=menuView&_tag=localNetStatus&Menu3Location=0&_=$TIMESTAMP"
		operazione "?_type=menuData&_tag=accessdev_ssiddev_lua.lua&_=$TIMESTAMP"		
		cat $tmp/alice_out.txt
	;;
	wlanstatus)
		echo "WLAN Status"
		main
		operazione "?_type=menuView&_tag=localNetStatus&Menu3Location=0&_=$TIMESTAMP"
		operazione "?_type=menuData&_tag=wlan_status_lua.lua&_=$TIMESTAMP"
		cat $tmp/alice_out.txt
	;;	
	dnshostnames)
		main
		operazione "?_type=menuView&_tag=dns&Menu3Location=0&_=$TIMESTAMP"
		operazione "?_type=menuData&_tag=dns_hostname_lua.lua&_=$TIMESTAMP"
		cat $tmp/alice_out.txt
	;;	
	dslstatus)
		main
		operazione "?_type=menuView&_tag=dslWanStatus&Menu3Location=0&_=$TIMESTAMP"
		operazione "?_type=menuData&_tag=dsl_interface_status_lua.lua&_=$TIMESTAMP"
		cat $tmp/alice_out.txt
	;;	
	wanstatus)
		main
		operazione "?_type=menuView&_tag=dslWanStatus&Menu3Location=0&_=$TIMESTAMP"
		operazione "?_type=menuData&_tag=wan_internet_lua.lua&TypeUplink=1&pageType=1&_=$TIMESTAMP"
		cat $tmp/alice_out.txt
	;;	
	ddnsstatus)
		main
		operazione "?_type=menuView&_tag=ddns&Menu3Location=0&_=$TIMESTAMP"
		operazione "?_type=menuData&_tag=ddns_lua.lua&_=$TIMESTAMP"
		cat $tmp/alice_out.txt
	;;	
	reboot)
		main
		operazione "?_type=menuView&_tag=rebootAndReset&Menu3Location=0"
		sessionTOKENtemp=$(echo -n -e $(cat $tmp/alice_out.txt |grep Token|cut -d '"' -f 2|cut -d '"' -f 1))
		operazione_data "?_type=menuData&_tag=devmgr_restartmgr_lua.lua&_=$TIMESTAMP" "IF_ACTION=Restart&Btn_restart=&_sessionTOKEN=$sessionTOKENtemp"	
		cat $tmp/alice_out_data.txt	
	;;
esac