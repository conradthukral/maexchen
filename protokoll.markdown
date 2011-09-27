Grundlagen
==========
- Kommunikation zeilenweise per UDP (utf8-kodierte Strings)
- Server öffnet einen bekannten Port
- Clients melden sich auf dem Port als Spieler an und werden ab da für jede Runde angeschrieben

TODOs
=====
- allgemeines Timeout?
- zufällige reihenfolge beschreiben
- einschränkungen für spielernamen aus dem protokoll ableiten

Protokoll
=========

Anmelden
--------
- client->server: REGISTER;name;passwort
- Falls name neu ist oder das vorher gespeicherte Passwort stimmt:
  - Server kommuniziert mit dem Client ab jetzt, indem er Nachrichten an die Ursprungs-IP und Ursprungs-Port der Register-Nachricht schickt.
  - server->client: REGISTERED;punktestand
- Ansonsten:
  server->client: REJECTED

(TODO: passwort weg, dafür IP-vergleich einbauen)
  
Start einer Spielrunde
-----------------------
- server->clients: ROUND STARTING;token
- client->server: JOIN;token

Falls mindestens ein Spieler teilnehmen will:
- server->clients: ROUND STARTED;spielerinfos*
  wobei spielerinfos mehrfach vorkommen kann und die folgende Form hat:
  name:punktestand

(TODO: Punktestand in separate Nachricht am Ende einer Runde verlegen)
  
Ansonsten:
- server->clients: ROUND CANCELED;no players
  woraufhin eine neue Runde gestartet wird.

Ablauf einer Spielrunde
-----------------------
Reihum:
- server->client: YOUR TURN;token
- client->server: command;token
  wobei command eins der folgenden ist: ROLL, SEE(?)
  
Bei ROLL:
- server->client: ROLLED;dice;token
- client->server: ANNOUNCE;dice';token
- server->clients: ANNOUNCED;name;dice

Bei SEE:
Server überprüft, ob zuletzt angesagte Würfel okay sind
- server->clients: ACTUAL DICE;dice
- server->clients: PLAYER LOST;name;reason

Wann immer ein Spieler nicht rechtzeitig antwortet oder sonst etwas falsch macht:
- server->clients: PLAYER LOST;name;reason

