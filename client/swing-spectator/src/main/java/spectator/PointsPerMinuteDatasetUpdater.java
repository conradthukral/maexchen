package spectator;

import java.util.Date;

import org.jfree.data.time.Second;
import org.jfree.data.time.TimeSeries;
import org.jfree.data.time.TimeSeriesCollection;

public class PointsPerMinuteDatasetUpdater implements PointsPerMinuteListener {

	private final TimeSeriesCollection dataset;
	
	public PointsPerMinuteDatasetUpdater(TimeSeriesCollection dataset) {
		this.dataset = dataset;
	}

	public void addDataPoint(long timestamp, String player, double pointsPerMinute) {
		TimeSeries series = getSeries(player);
		series.add(new Second(new Date(timestamp)), pointsPerMinute);
	}

	private TimeSeries getSeries(String player) {
		TimeSeries series = dataset.getSeries(player);
		if (series == null) {
			series = new TimeSeries(player, Second.class);
			dataset.addSeries(series);
		}
		return series;
	}

}
