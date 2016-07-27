# modem-alice-telecom
Script per la gestione da command line linux del modem alice di telecom italia.
Per ora sono implementate le funzioni di base "wifilist", "reboot", "info" e "stats" ma è semplice aggiungerne altre con la struttura di login al modem funzionante.

Non so come si comporta con modem senza password impostata, fate sapere :)

# info
* Editare i parametri di configurazione in testa allo script
* Software necessari: md5sum, php
* Testato su: AGVTF_5.3.3 - modem fibra

#esempi
Uso: ./modemalice.sh {wifilist|reboot|info|stats}

Client connessi: **./modemalice.sh wifilist|grep "Nessun"|wc -l**

Se il risultato è 2 nesusn host è connesso, se è 1 o 0 ci sono client

Riavvio modem: **./modemalice.sh reboot**

#crontab
**59      4       3       *       *       /usr/bin/me/alice_fibra/modemalice.sh reboot**

riavvio mensile alle 4 e 59, ogni giorno 3 del mese

