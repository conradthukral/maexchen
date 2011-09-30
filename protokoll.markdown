
Grundlagen
==========
- Kommunikation zeilenweise per UDP (utf8-kodierte Strings)
- Server öffnet einen bekannten Port
- Clients melden sich auf dem Port als Spieler an und werden ab da für jede Runde angeschrieben
- Clients haben für ihre Antwort ein recht enges Zeitfenster (250 ms)

Protokoll
=========

Anmelden
--------
- client->server: `REGISTER;name`
- Falls name gültig und neu ist, oder die registrierung unter demselben namen zuletzt von derselben IP kam:
  - Server kommuniziert mit dem Client ab jetzt, indem er Nachrichten an die Ursprungs-IP und Ursprungs-Port der Register-Nachricht schickt.
  - server->client: `REGISTERED`
- Ansonsten:
  server->client: `REJECTED`

Gültige Spielernamen
- enthalten keinen whitespace
- enthalten keine Doppelpunkte, Semikolons oder Kommas
- sind maximal 20 Zeichen lang

Start einer Spielrunde
-----------------------
- server->clients: `ROUND STARTING;rundennummer;token`
- client->server: `JOIN;token`

Falls mindestens ein Spieler teilnehmen will:
- Die teilnehmenden Spieler werden vom Server in eine zufällige Reihenfolge gebracht
- server->clients: `ROUND STARTED;spielernamen`
  wobei spielernamen eine kommagetrennte List der Mitspieler ist (in der Reihenfolge, in der diese Runde gespielt wird)

Ansonsten:

- server->clients: `ROUND CANCELED;NO_PLAYERS`
  woraufhin eine neue Runde gestartet wird.

(Runden mit nur einem Spieler werden direkt nach dem Start mit `ROUND CANCELED;ONLY_ONE_PLAYER` abgebrochen)

Ablauf einer Spielrunde
-----------------------
Reihum:

- server->client: `YOUR TURN;token`
- client->server: `command;token`
  wobei command eins der folgenden ist: `ROLL`, `SEE`
  
Bei `ROLL`:

- server->clients: `PLAYER ROLLS;name`
- server->client: `ROLLED;dice;token`
- client->server: `ANNOUNCE;dice';token`
- server->clients: `ANNOUNCED;name;dice`

Falls Mäxchen angesagt wurde, wird sofort aufgedeckt. Wenn tatsächlich Mäxchen gewürfelt wurde, verlieren alle anderen Spieler, ansonsten der ansagende.

- server -> clients: `PLAYER LOST;names;reason` (wobei names eine kommagetrennte liste ist)

Bei `SEE`:

Server überprüft, ob zuletzt angesagte Würfel okay sind

- server->clients: `PLAYER WANTS TO SEE;name`
- server->clients: `ACTUAL DICE;dice`
- server->clients: `PLAYER LOST;name;reason`

Wann immer ein Spieler nicht rechtzeitig antwortet oder etwas völlig falsch macht:

- server->clients: `PLAYER LOST;name;reason`

Nach Ende einer Runde:

- server->clients: `SCORE;spielerpunkte*`
  wobei spielerpunkte eine kommagetrennte Liste von Einträgen in der Form `name:punkte` ist und für jeden Spieler einen Eintrag enthält

Gründe, warum ein Spieler verliert
----------------------------------
<table>
<tr><th>Code</th><th>Bedeutung</th></tr>
<tr><td>
SEE_BEFORE_FIRST_ROLL:
</td><td>
Spieler wollte sehen, war aber als erster am Zug (es gab also noch keine Ansage vorher)
</td></tr>
<tr><td>
LIED_ABOUT_MIA:
</td><td>
Spieler hat Mäxchen angesagt, ohne Mäxchen zu haben
</td></tr>
<tr><td>
ANNOUNCED_LOSING_DICE:
</td><td>
Spieler hat zu niedrige Würfel angesagt
</td></tr>
<tr><td>
DID_NOT_ANNOUNCE:
</td><td>
Spieler hat nicht (rechtzeitig) angesagt, was gewürfelt wurde
</td></tr>
<tr><td>
DID_NOT_TAKE_TURN:
</td><td>
Spieler hat nicht (rechtzeitig) einen Zug gemacht
</td></tr>
<tr><td>
INVALID_TURN:
</td><td>
Spieler hat einen ungültigen Zug gemacht
</td></tr>
<tr><td>
SEE_FAILED:
</td><td>
Spieler wollte sehen, Ansage des vorhergehenden Spielers war aber richtig
</td></tr>
<tr><td>
CAUGHT_BLUFFING:
</td><td>
Spieler hat mehr angesagt als er hatte, und der nachfolgende Spieler wollte sehen
</td></tr>
<tr><td>
MIA:
</td><td>
Es wurde Mäxchen aufgedeckt
</td></tr>
</table>

