package spectator;

import udphelper.MessageListener;

public class DataCollector implements MessageListener {

	private final RoundListener roundListener;
	private final ScoreListener scoreListener;

	private StringBuilder currentRound = new StringBuilder();
	private int currentRoundNumber;
	
	public DataCollector(RoundListener roundListener, ScoreListener scoreListener) {
		this.roundListener = roundListener;
		this.scoreListener = scoreListener;
	}

	public void onMessage(String message) {
		String[] parts = message.split(";");
		if (parts[0].equals("ROUND STARTING")) {
			currentRoundNumber = Integer.parseInt(parts[1]);
			currentRound.setLength(0);
		} else if (parts[0].equals("PLAYER LOST")) {
			appendFormattedMessage(parts);
			roundListener.roundCompleted(currentRoundNumber, currentRound.toString());
		} else if (parts[0].equals("SCORE")) {
			handleScores(message);
		} else {
			appendFormattedMessage(parts);
		}
	}

	private void appendFormattedMessage(String[] messageParts) {
		String formatted = null;
		if (messageParts[0].equals("ROUND STARTED")) {
			String[] players = messageParts[1].split(",");
			formatted = "Teilnehmer: " + germanJoin(players);
		} else if (messageParts[0].equals("ANNOUNCED")) {
			String player = messageParts[1];
			String dice = formatDice(messageParts[2]);
			formatted = player + " sagt an: " + dice;
		} else if (messageParts[0].equals("PLAYER LOST")) {
			String[] players = messageParts[1].split(",");
			String reason = messageParts[2];
			formatted = formatPlayerLost(players, reason);
		} else if (messageParts[0].equals("ACTUAL DICE")) {
			String dice = formatDice(messageParts[1]);
			formatted = "Die Würfel werden aufgedeckt: " + dice;
		} else if (messageParts[0].equals("PLAYER ROLLS")) {
			String player = messageParts[1];
			formatted = player + " würfelt...";
		} else if (messageParts[0].equals("PLAYER WANTS TO SEE")) {
			String player = messageParts[1];
			formatted = player + " will sehen!";
		}
		if (formatted != null) {
			currentRound.append(formatted);
		} else {
			currentRound.append(messageParts[0]);
		}
		currentRound.append("\n");
	}

	private String formatDice(String diceString) {
		String[] dieStrings = diceString.split(",");
		int die1 = Integer.parseInt(dieStrings[0]);
		int die2 = Integer.parseInt(dieStrings[1]);
		if (die1 == 2 && die2 == 1) {
			return "Mäxchen!";
		}
		if (die1 == die2) {
			switch (die1) {
				case 1: return "Einserpasch";
				case 2: return "Zweierpasch";
				case 3: return "Dreierpasch";
				case 4: return "Viererpasch";
				case 5: return "Fünferpasch";
				case 6: return "Sechserpasch";
			}
		}
		return "" + die1 + die2;
	}

	private String formatPlayerLost(String[] players, String reason) {
		String result;
		if (players.length == 1) {
			result = players[0] + " verliert";
		} else {
			result = germanJoin(players) + " verlieren";
		}
		return result + " (" + reason + ")";
	}

	private String germanJoin(String[] parts) {
		if (parts.length == 0) {
			return "";
		}
		String result = parts[0];
		if (parts.length == 1) {
			return result;
		}
		for (int i = 1; i < parts.length - 1; i++) {
			result += ", " + parts[i];
		}
		return result + " und " + parts[parts.length - 1];
	}

	private void handleScores(String message) {
		Scores scores = Scores.parse(message);
		scoreListener.currentScores(scores);
	}

}
