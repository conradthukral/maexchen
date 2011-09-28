package spectator;

import java.awt.BorderLayout;
import java.awt.EventQueue;
import java.util.List;

import javax.swing.JFrame;
import javax.swing.JTable;
import javax.swing.JTextPane;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.TableModel;

public class SpectatorApplication {

	private JFrame frmMxchen;
	private JTable table;
	private JTextPane textPane;

	/**
	 * Create the application.
	 */
	public SpectatorApplication() {
		initialize();
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
		frmMxchen.setBounds(100, 100, 556, 439);
		frmMxchen.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		textPane = new JTextPane();
		frmMxchen.getContentPane().add(textPane, BorderLayout.CENTER);
		textPane.setEditable(false);
		textPane.setText("Text");
		
		table = new JTable();
		frmMxchen.getContentPane().add(table, BorderLayout.EAST);
		table.setModel(createScoreModel(new Scores()));
	}

	private TableModel createScoreModel(Scores scores) {
		return new ScoreTableModel(scores);
	}

	public void setRoundDescription(final String message) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				textPane.setText(message);
			}
		});
	}

	public void showScores(Scores scores) {
		table.setModel(createScoreModel(scores));
		table.invalidate();
	}

}
