package spectator;

import java.util.LinkedList;
import java.util.Queue;

public class PointsPerMinuteCalculator implements ScoreListener {

	private static final long ONE_MINUTE = 60000;
	private static final long UPDATE_INTERVAL = 10000;

	private static final int MIN_SMOOTHING_FACTOR = 5;
	private static final int MAX_SMOOTHING_FACTOR = 5;

	private static class ScoreSnapshot {
		public Scores scores;
		public long timestamp;
		
		public ScoreSnapshot(Scores scores, long timestamp) {
			this.scores = scores;
			this.timestamp = timestamp;
		}
	}
	
	private final Queue<ScoreSnapshot> previousScores = new LinkedList<ScoreSnapshot>();
	private final PointsPerMinuteListener listener;
	
	private long lastCheckpoint = 0;

	public PointsPerMinuteCalculator(PointsPerMinuteListener listener) {
		this.listener = listener;
	}

	public void scoresAfterRound(Scores scores, int roundNumber) {
		long now = System.currentTimeMillis();
		if (now - lastCheckpoint >= UPDATE_INTERVAL) {
			createCheckpoint(new ScoreSnapshot(scores, now));
			lastCheckpoint = now;
		}
	}

	private void createCheckpoint(ScoreSnapshot currentScores) {
		if (previousScores.size() >= MIN_SMOOTHING_FACTOR) {
			ScoreSnapshot referenceScores = previousScores.peek();
			calculatePointsPerMinute(referenceScores, currentScores);
		}
		previousScores.add(currentScores);
		while (previousScores.size() > MAX_SMOOTHING_FACTOR) {
			previousScores.poll();
		}
	}

	private void calculatePointsPerMinute(ScoreSnapshot previous, ScoreSnapshot current) {
		Scores previousScores = previous.scores;
		Scores currentScores = current.scores;
		for (String player : currentScores.players()) {
			if (!previousScores.hasPlayer(player)) {
				continue;
			}
			int previousPoints = previousScores.scoreFor(player);
			int currentPoints = currentScores.scoreFor(player);
			int deltaPoints = currentPoints - previousPoints;
			if (deltaPoints > 0) {
				long deltaTime = current.timestamp - previous.timestamp;
				double pointsPerMinute = calculatePointsPerMinute(deltaPoints, deltaTime);
				listener.addDataPoint(current.timestamp, player, pointsPerMinute);
			}
		}
	}

	private double calculatePointsPerMinute(int deltaPoints, long deltaTime) {
		return deltaPoints * ONE_MINUTE / deltaTime;
	}

}
