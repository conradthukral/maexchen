Mia protocol
============

Preliminaries
-------------
- Communication row vise per UDP (utf8-encoded Strings)
- Server opens a known port
- Clients register themselves as player and are -- from then on -- notified for each round
- Clients have to respond within in a narrow time frame (250 ms)
- Alternatively a client could register as a spectator. Spectators are not able to actively participate in the game. Yet they will receive all messages every other client would receive

Registration
------------
- client->server: `REGISTER;name`
- client->server: `REGISTER_SPECTATOR;name`

Valid names need to satisfy the following criteria:
- contains no whitespaces
- contains no colon, semicolons, or commas
- consist of up to 20 characters

To receive a positive response (server->client: `REGISTERED`) from the server:
- the name has to be valid and new
- the initial registration for that name originated from the same client IP address
Given a positive response, the server continues its client communication only through the originating IP and the port used for the registration message.

When the above criteria are not satisfied, the server negatively responds with server->client: `REJECTED`.

Round start
-----------

- server->clients: `ROUND STARTING;token`
- client->server: `JOIN;token`

If at least one player participates:
- the server shuffles the participating players
- server->clients: `ROUND STARTED;roundnumber;playernames` (wheras `playernames` is a ordered, comma separated list of all participating players. The lists order corresponds to how the round is going to be played.)

Else:
- server->clients: `ROUND CANCELED;NO_PLAYERS` (a new round is started immediately)

Rounds with just one player are canceled right after their start: `ROUND CANCELED;ONLY_ONE_PLAYER`

Round actions
-------------
In adherence to the previously announced order:
- server->client: `YOUR TURN;token`
- client->server: `command;token` (where `command` has to be either `ROLL` or `SEE`)

On `ROLL`:
- server->clients: `PLAYER ROLLS;name`
- server->client: `ROLLED;dice;token`
- client->server: `ANNOUNCE;dice';token`
- server->clients: `ANNOUNCED;name;dice`

When Mia is announced, the round ends and dies are shown. Given Mia was indeed rolled, all player but the announcer lose, otherwise the announcer loses.
- server -> clients: `PLAYER LOST;names;reason` (where `names` is a comma separated list)

On `SEE`:
- Server checks if last announced dies are valid and determines the losing players
- server->clients: `PLAYER WANTS TO SEE;name`
- server->clients: `ACTUAL DICE;dice`
- server->clients: `PLAYER LOST;name;reason`

Whenever a players does not respond in time or does something wrong:
- server->clients: `PLAYER LOST;name;reason`

At the end of each round:
- server->clients: `SCORE;playerpoints` (where `playerpoints` is a comma separated list with entries in the form of `name:points`)

Reasons for losing a round
--------------------------
- `SEE_BEFORE_FIRST_ROLL`: Player wanted to `SEE`, but was first to act (no dies were announced before)
- `LIED_ABOUT_MIA`: Player announced Mia without actually having Mia
- `ANNOUNCED_LOSING_DICE`: Player announced dies that were lower than the previously announced ones
- `DID_NOT_ANNOUNCE`: Player did not announce (in time)
- `DID_NOT_TAKE_TURN`: Player did not announce turn (in time)
- `INVALID_TURN`: Player commanded an invalid turn
- `SEE_FAILED`: Player wanted to `SEE`, but previous player announced dies correctly
- `CAUGHT_BLUFFING`: Player announced higher dies than actually given and the succeeding player wanted to `SEE`
- `MIA`: Mia was announced
