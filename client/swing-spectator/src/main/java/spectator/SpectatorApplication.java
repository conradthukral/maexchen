package spectator;

import java.awt.BorderLayout;
import java.awt.EventQueue;
import java.awt.Font;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import javax.swing.JFrame;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextPane;
import javax.swing.table.TableModel;
import javax.swing.JPanel;
import javax.swing.JProgressBar;

public class SpectatorApplication {

	private JFrame frmMxchen;
	private JTextPane roundText;
	private JScrollPane scrollPane;
	private JTable table;
	private JPanel panel;
	private JTextPane roundHeader;
	private JProgressBar progressBar;

	/**
	 * Create the application.
	 */
	public SpectatorApplication() {
		initialize();
		Executors.newSingleThreadScheduledExecutor().scheduleAtFixedRate(new IncrementProgressBar(progressBar, 1), 1, 1, TimeUnit.SECONDS);
	}
	
	public void show() {
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
		
		table = new JTable();
		table.setFont(new Font("Arial", Font.PLAIN, 18));
		table.getTableHeader().setFont(new Font("Arial", Font.PLAIN, 18));
		table.setRowHeight(25);
		table.setRowSelectionAllowed(false);
		table.setFillsViewportHeight(true);

		scrollPane = new JScrollPane(table);
		scrollPane.setViewportBorder(null);
		frmMxchen.getContentPane().add(scrollPane, BorderLayout.EAST);
		
		panel = new JPanel();
		frmMxchen.getContentPane().add(panel, BorderLayout.CENTER);
		panel.setLayout(new BorderLayout(0, 0));
		
		roundText = new JTextPane();
		panel.add(roundText, BorderLayout.CENTER);
		roundText.setFont(new Font("Arial", Font.PLAIN, 18));
		roundText.setEditable(false);
		roundText.setText("Text");
		
		roundHeader = new JTextPane();
		roundHeader.setText("Round 42");
		roundHeader.setFont(new Font("Arial", Font.PLAIN, 18));
		roundHeader.setEditable(false);
		panel.add(roundHeader, BorderLayout.NORTH);
		
		progressBar = new JProgressBar();
		progressBar.setValue(10);
		progressBar.setMaximum(10);
		panel.add(progressBar, BorderLayout.SOUTH);
	}

	private TableModel createScoreModel(Scores scores) {
		return new ScoreTableModel(scores);
	}

	public void updateRoundData(final int roundNumber, final String message) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				roundHeader.setText("Runde " + roundNumber);
				roundText.setText(message);
				progressBar.setValue(0);
			}
		});
	}

	public void showScores(Scores scores) {
		table.setModel(createScoreModel(scores));
		table.invalidate();
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

}
