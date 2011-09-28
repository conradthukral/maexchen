package spectator;

import udphelper.MessageListener;

public class DataCollector implements MessageListener {

	private StringBuilder currentRound = new StringBuilder();
	
	private final RoundListener roundListener;
	private final ScoreListener scoreListener;
	
	public DataCollector(RoundListener roundListener, ScoreListener scoreListener) {
		this.roundListener = roundListener;
		this.scoreListener = scoreListener;
	}

	public void onMessage(String message) {
		if (message.startsWith("ROUND STARTED")) {
			currentRound.setLength(0);
			currentRound.append(message).append("\n");
		} else if (message.startsWith("PLAYER LOST")) {
			currentRound.append(message);
			roundListener.roundCompleted(currentRound.toString());
		} else if (message.startsWith("SCORE")) {
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
