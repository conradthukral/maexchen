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
- client->server: REGISTER;name
- Falls name neu ist, oder die registrierung unter demselben namen zuletzt von derselben IP kam:
  - Server kommuniziert mit dem Client ab jetzt, indem er Nachrichten an die Ursprungs-IP und Ursprungs-Port der Register-Nachricht schickt.
  - server->client: REGISTERED
- Ansonsten:
  server->client: REJECTED

(TODO: passwort weg, dafür IP-vergleich einbauen)
  
Start einer Spielrunde
-----------------------
- server->clients: ROUND STARTING;rundennummer;token
- client->server: JOIN;token

Falls mindestens ein Spieler teilnehmen will:
- server->clients: ROUND STARTED;spielernamen
  wobei spielernamen eine kommagetrennte List der Mitspieler ist (in der Reihenfolge, in der diese Runde gespielt wird)

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
- server->clients: PLAYER ROLLS;name
- server->client: ROLLED;dice;token
- client->server: ANNOUNCE;dice';token
- server->clients: ANNOUNCED;name;dice

Falls Mäxchen angesagt wurde, wird sofort aufgedeckt. Wenn tatsächlich Mäxchen gewürfelt wurde, verlieren alle anderen Spieler, ansonsten der ansagende.
- server -> clients: PLAYER LOST;names;reason (wobei names eine kommagetrennte liste ist)

Bei SEE:
Server überprüft, ob zuletzt angesagte Würfel okay sind
- server->clients: PLAYER WANTS TO SEE;name
- server->clients: ACTUAL DICE;dice
- server->clients: PLAYER LOST;name;reason

Wann immer ein Spieler nicht rechtzeitig antwortet oder etwas völlig falsch macht:
- server->clients: PLAYER LOST;name;reason

Nach Ende einer Runde:
- server->clients: SCORE;spielerpunkte*
  wobei spielerpunkte eine kommagetrennte Liste von Einträgen in der Form name:punkte ist und für jeden Spieler einen Eintrag enthält

Reason-Codes
------------
SEE_BEFORE_FIRST_ROLL: Spieler wollte sehen, war aber als erster am Zug (es gab also noch keine Ansage vorher)
LIED_ABOUT_MIA: Spieler hat Mäxchen angesagt, ohne Mäxchen zu haben
ANNOUNCED_LOSING_DICE: Spieler hat zu niedrige Würfel angesagt
DID_NOT_ANNOUNCE: Spieler hat nicht (rechtzeitig) angesagt, was gewürfelt wurde
DID_NOT_TAKE_TURN: Spieler hat nicht (rechtzeitig) einen Zug gemacht
INVALID_TURN: Spieler hat einen ungültigen Zug gemacht
SEE_FAILED: Spieler wollte sehen, Ansage des vorhergehenden Spielers war aber richtig
CAUGHT_BLUFFING: Spieler hat mehr angesagt als er hatte, und der nachfolgende Spieler wollte sehen
MIA: Es wurde Mäxchen aufgedeckt

