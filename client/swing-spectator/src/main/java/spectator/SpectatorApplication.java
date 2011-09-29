package spectator;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.EventQueue;
import java.awt.Font;
import java.awt.Insets;
import java.awt.SystemColor;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JProgressBar;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextPane;
import javax.swing.SwingConstants;
import javax.swing.table.TableModel;

import net.miginfocom.swing.MigLayout;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.data.time.TimeSeriesCollection;
import javax.swing.JSplitPane;

public class SpectatorApplication {

	private JFrame frmMxchen;
	private JTextPane roundText;
	private JScrollPane scrollPane;
	private JTable table;
	private JPanel leftColumn;
	private JProgressBar progressBar;
	private JPanel rightColumn;
	private JLabel scoresTableHeader;
	private JLabel roundHeader;
	private JLabel lblNchsteRunde;
	private JLabel lblHistorie;
	private ChartPanel chartPanel;
	private TimeSeriesCollection pointsPerMinute;
	private JSplitPane splitPane;

	/**
	 * Create the application.
	 */
	public SpectatorApplication() {
		initialize();
		Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate(
				new IncrementProgressBar(progressBar, 1), 1, 1,
				TimeUnit.SECONDS);
	}

	public void show() {
		// GraphicsDevice defaultScreen =
		// GraphicsEnvironment.getLocalGraphicsEnvironment().getDefaultScreenDevice();
		// if (defaultScreen.isFullScreenSupported()) {
		// frmMxchen.setUndecorated(true);
		// defaultScreen.setFullScreenWindow(frmMxchen);
		// }
		frmMxchen.setVisible(true);
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		frmMxchen = new JFrame();
		frmMxchen.setTitle("Mäxchen!");
		frmMxchen.setSize(800, 600);
		frmMxchen.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

		rightColumn = new JPanel();
		rightColumn.setBackground(SystemColor.window);
		rightColumn.setBorder(null);
		rightColumn.setLayout(new MigLayout("", "[grow,fill]", "[15px][][][]"));
		scoresTableHeader = new JLabel("Warte auf ersten Punktestand...");
		scoresTableHeader.setFont(new Font("Arial", Font.BOLD, 18));
		rightColumn.add(scoresTableHeader, "cell 0 0,alignx left,aligny top");
		scoresTableHeader.setVerticalAlignment(SwingConstants.TOP);
		scoresTableHeader.setHorizontalAlignment(SwingConstants.LEFT);
		scoresTableHeader.setAlignmentY(Component.TOP_ALIGNMENT);

		table = new JTable();
		table.setOpaque(false);
		table.setBorder(null);
		table.setFillsViewportHeight(true);
		table.setFont(new Font("Arial", Font.PLAIN, 18));
		table.getTableHeader().setFont(new Font("Arial", Font.PLAIN, 18));
		table.setRowHeight(25);
		table.setRowSelectionAllowed(false);

		scrollPane = new JScrollPane(table);
		scrollPane.setBorder(null);
		scrollPane.setOpaque(false);
		rightColumn.add(scrollPane, "cell 0 1");

		lblHistorie = new JLabel("Punkte pro Minute");
		lblHistorie.setFont(new Font("Arial", Font.BOLD, 18));
		rightColumn.add(lblHistorie, "cell 0 2");

		pointsPerMinute = new TimeSeriesCollection();
		JFreeChart chart = ChartFactory.createTimeSeriesChart("", "", "",
				pointsPerMinute, true, false, false);
		chartPanel = new ChartPanel(chart);
		rightColumn.add(chartPanel, "cell 0 3");

		leftColumn = new JPanel();
		leftColumn.setBackground(Color.WHITE);
		leftColumn.setBorder(null);
		leftColumn.setLayout(new MigLayout("", "[][grow,fill]",
				"[][grow,fill][]"));

		roundHeader = new JLabel("Warte auf erste Runde...");
		roundHeader.setFont(new Font("Arial", Font.BOLD, 18));
		leftColumn.add(roundHeader, "cell 0 0 2 1");

		lblNchsteRunde = new JLabel("nächste Runde:");
		leftColumn.add(lblNchsteRunde, "cell 0 2");

		roundText = new JTextPane();
		roundText.setMargin(new Insets(0, 0, 0, 0));
		roundText.setOpaque(false);
		leftColumn.add(roundText, "cell 0 1 2 1,grow");
		roundText.setFont(new Font("Arial", Font.PLAIN, 18));
		roundText.setEditable(false);

		progressBar = new JProgressBar();
		progressBar.setValue(10);
		progressBar.setMaximum(10);
		leftColumn.add(progressBar, "cell 1 2,growx,aligny top");

		splitPane = new JSplitPane();
		splitPane.setResizeWeight(1.0);
		splitPane.setLeftComponent(leftColumn);
		splitPane.setRightComponent(rightColumn);
		frmMxchen.getContentPane().add(splitPane, BorderLayout.CENTER);
	}

	private TableModel createScoreModel(Scores scores) {
		return new ScoreTableModel(scores);
	}

	public void updateRoundData(final int roundNumber, final String message) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				roundHeader.setText("Ablauf von Runde " + roundNumber);
				roundText.setText(message);
				progressBar.setValue(0);
			}
		});
	}

	public void showScores(final int roundNumber, final Scores scores) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				scoresTableHeader.setText("Punktestand nach Runde "
						+ roundNumber);
				table.setModel(createScoreModel(scores));
				table.invalidate();
			}
		});
	}

	private static class IncrementProgressBar implements Runnable {

		private final JProgressBar progressBar;
		private final int increment;

		public IncrementProgressBar(JProgressBar progressBar, int increment) {
			this.progressBar = progressBar;
			this.increment = increment;
		}

		public void run() {
			progressBar.setValue(progressBar.getValue() + increment);
		}

	}

	public TimeSeriesCollection getPointsPerMinute() {
		return pointsPerMinute;
	}

}
