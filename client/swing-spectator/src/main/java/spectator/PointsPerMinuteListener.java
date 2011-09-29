package spectator;

public interface PointsPerMinuteListener {

	void addDataPoint(long timestamp, String player, double pointsPerMinute);

}
