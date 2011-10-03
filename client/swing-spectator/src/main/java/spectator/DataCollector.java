package spectator;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;

import udphelper.MessageListener;

public class DataCollector implements MessageListener {

	private static final Map<String,String> REASON_TEXTS = new HashMap<String, String>();
	
	static {
		REASON_TEXTS.put("SEE_BEFORE_FIRST_ROLL", "wollte als erster am Zug sehen");
		REASON_TEXTS.put("LIED_ABOUT_MIA", "wer Mäxchen sagt, sollte Mäxchen haben");
		REASON_TEXTS.put("ANNOUNCED_LOSING_DICE", "man muss schon mehr sagen als vorher angesagt war");
		REASON_TEXTS.put("DID_NOT_ANNOUNCE", "hat nichts angesagt");
		REASON_TEXTS.put("DID_NOT_TAKE_TURN", "hat keinen Spielzug gemacht");
		REASON_TEXTS.put("INVALID_TURN", "wollte einen ungültigen Spielzug machen");
		REASON_TEXTS.put("SEE_FAILED", "wollte sehen... aber doch nicht sowas!");
		REASON_TEXTS.put("CAUGHT_BLUFFING", "hatte gehofft, dass das keiner überprüft");
		REASON_TEXTS.put("MIA", "Mäxchen");
		REASON_TEXTS.put("NO_PLAYERS", "niemand wollte mitspielen");
		REASON_TEXTS.put("ONLY_ONE_PLAYER", "alleine kann man nicht Mäxchen spielen");
	}
	
	private final RoundListener roundListener;
	private final Collection<ScoreListener> scoreListeners = new ArrayList<ScoreListener>();

	private StringBuilder currentRound = new StringBuilder();
	private int currentRoundNumber;
	
	public DataCollector(RoundListener roundListener) {
		this.roundListener = roundListener;
	}

	public void onMessage(String message) {
		String[] parts = message.split(";");
		if (parts[0].equals("ROUND STARTED")) {
			currentRoundNumber = Integer.parseInt(parts[1]);
			currentRound.setLength(0);
		} else if (parts[0].equals("PLAYER LOST") || parts[0].equals("ROUND CANCELED")) {
			appendFormattedMessage(parts);
			if (roundIsIncomplete()) return;
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
			String reason = formatReason(messageParts[2]);
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
		} else if (messageParts[0].equals("ROUND CANCELED")) {
			String reason = formatReason(messageParts[1]);
			formatted = "Runde abgebrochen: " + reason;
		}
		if (formatted != null) {
			currentRound.append(formatted);
		} else {
			currentRound.append(messageParts[0]);
		}
		currentRound.append("\n");
	}

	private String formatReason(String reasonCode) {
		String result = REASON_TEXTS.get(reasonCode);
		if (result == null) result = reasonCode;
		return result;
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
		return result + ": " + reason;
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
		if (roundIsIncomplete()) return;
		Scores scores = Scores.parse(message);
		for (ScoreListener listener : scoreListeners) {
			listener.scoresAfterRound(scores, currentRoundNumber);
		}
	}

	private boolean roundIsIncomplete() {
		return currentRoundNumber == 0;
	}

	public void addScoreListener(ScoreListener listener) {
		scoreListeners.add(listener);
	}

}
