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
			currentRound.append(message);
			roundListener.roundCompleted(currentRoundNumber, currentRound.toString());
		} else if (parts[0].equals("SCORE")) {
			handleScores(message);
		} else {
			currentRound.append(message).append("\n");
		}
	}

	private void handleScores(String message) {
		Scores scores = Scores.parse(message);
		scoreListener.currentScores(scores);
	}

}
