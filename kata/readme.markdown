This Kata is shamelessly copied from the one for the [Craftsmen-Coding-Contest](/lomin/ccc-kata/wiki).

To complete this Kata, your task is to implement a program that

1. sends `START` as UTF-8 encoded UDP message to a well-known port on a server
2. listens for a reply message containing a simple mathematical task (on the port from which the start message was sent)
3. calculates the result
4. sends the result to the server
5. repeats until message is either `ALL CORRECT` or something like `3 WRONG, 2 CORRECT`

The content of the messages are strings with the following structure:

`<function>:<uuid>:<parameter>:<parameter>[:<parameter>]*`

where `<function>` is one of `ADD`, `MULTIPLY`, `SUBTRACT`. Parameters are integers. There are at least two parameters, but there can be more.

Example server messages are:

1. `ADD:4160806a2f2846759d6c7e764f4bcbd5:184:106:107`
2. `SUBTRACT:45429b851ac549fc9e2e38f9ee289061:27:107:91:55`
3. `MULTIPLY:6868c974bf7140eabb18b826bedacd54:175:126:172:119`

The structure of the expected response are:

`<uuid>:<result>`

The correct responses for the example server messages are respectively:

1. `4160806a2f2846759d6c7e764f4bcbd5:397`
2. `45429b851ac549fc9e2e38f9ee289061:-226`
3. `6868c974bf7140eabb18b826bedacd54:451319400`

The goals of the Kata are to make you comfortable with the socket interface of your chosen language and the structure of a text-based protocol similiar to the protocol used in the Craftsmen-Coding-Contest.
