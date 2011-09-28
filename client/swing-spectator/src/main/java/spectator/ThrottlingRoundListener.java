package spectator;

public class ThrottlingRoundListener implements RoundListener {

	private final RoundListener decorated;
	private long lastTimestamp = Long.MIN_VALUE;

	public ThrottlingRoundListener(RoundListener decorated) {
		this.decorated = decorated;
	}

	public void roundCompleted(int roundNumber, String completeRound) {
		long now = System.currentTimeMillis();
		if (now > lastTimestamp + 10000) {
			lastTimestamp = now;
			decorated.roundCompleted(roundNumber, completeRound);
		}
	}

}
