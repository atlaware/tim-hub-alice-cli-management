#!/bin/bash

##-------------------------CONFIG---------------------------------------

alice="192.168.1.1" # indirizzo del modem, default: 192.168.1.1
user="admin" # user, default admin
pass="" # password, non so se/come funziona sui modem senza password, provate :)
tmp="/tmp/"
#proxy="-x "127.0.0.1:9090"" # solo per debug, non abilitare
vermodem="AGVTF_5.3.0" # versione del modem su cui ho testato lo script

##------------------------END-CONF---------------------------------------

cd "$(dirname "$0")"

function clogin(){
	curl -L $proxy -c $tmp/alice_cookie -e "http://$alice/" -o $tmp/alice_out1.txt http://$alice
}
function elablogin(){
	xauth=$(cat $tmp/alice_cookie |grep xAuth|cut -d$'\t' -f 7)
	xauthenc=$(php -r "echo urlencode('$xauth');")
	nonce=$(cat $tmp/alice_out1.txt |grep "var nonce"|cut -d '"' -f 2)
	echo -n "$nonce" > $tmp/alice_nonce
	echo -n "$user:Technicolor Gateway:$pass" > $tmp/alice_ha1
	echo -n "GET:/index_auth.lp" > $tmp/alice_ha2
	ha1=$(md5sum $tmp/alice_ha1|cut -d ' ' -f 1)
	ha2=$(md5sum $tmp/alice_ha2|cut -d ' ' -f 1)
	echo -n "$ha1:$nonce:00000001:xyz:auth:$ha2" > $tmp/alice_hidepw
	hidepw=$(md5sum $tmp/alice_hidepw|cut -d ' ' -f 1)
}
function login() {
	curl -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out2.txt -e "http://$alice/index_auth.lp" -d "rn=$xauthenc&hidepw=$hidepw" http://$alice/index_auth.lp
}
function operazione() {
	curl -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -o $tmp/alice_out3.txt http://$alice/$1
}
function operazione_data() {
        curl -L $proxy -c $tmp/alice_cookie -b $tmp/alice_cookie -d "$2" -o $tmp/alice_out3.txt http://$alice/$1
}
function main() {
	elablogin
	login

	# CHECK se login completo
	loginko=$(cat $tmp/alice_out2.txt|grep fallita|wc -l)
	if [ $loginko -gt 0 ]; then
		echo "Effettuo login completo"
		clogin
		elablogin
		login		
	fi
}

# OPERAZIONI
case $1 in 
	wifilist)
		echo "Wifilist"
		main
		operazione "wlanStatus.lp?wifiPage=wifi"
		cat $tmp/alice_out3.txt
	;;
	reboot)
		echo "Reboot"
		main
		operazione_data "resetAG.lp" "rn=$xauthenc&action=saveRestart"
		#cat $tmp/alice_out3.txt	
	;;
        *)
	    echo "-------------Gestione Modem Telecom Alice-----------------"
	    echo "Editare i parametri di configurazione in testa allo script"
	    echo "Software necessari: md5sum, php"
	    echo "Testato su: $vermodem"
            echo "----------------------------------------------------------"
            echo $"Uso: $0 {wifilist|reboot}"
            exit 1
esac
