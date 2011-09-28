package spectator;

import java.awt.BorderLayout;
import java.awt.EventQueue;
import java.awt.Font;

import javax.swing.JFrame;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.JTextPane;
import javax.swing.table.TableModel;

public class SpectatorApplication {

	private JFrame frmMxchen;
	private JTextPane textPane;
	private JScrollPane scrollPane;
	private JTable table;

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
		frmMxchen.setSize(800, 600);
		frmMxchen.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		textPane = new JTextPane();
		textPane.setFont(new Font("Arial", Font.PLAIN, 18));
		frmMxchen.getContentPane().add(textPane, BorderLayout.CENTER);
		textPane.setEditable(false);
		textPane.setText("Text");
		
		table = new JTable();
		table.setFont(new Font("Arial", Font.PLAIN, 18));
		table.getTableHeader().setFont(new Font("Arial", Font.PLAIN, 18));
		table.setRowHeight(25);
		table.setRowSelectionAllowed(false);
		table.setFillsViewportHeight(true);

		scrollPane = new JScrollPane(table);
		scrollPane.setViewportBorder(null);
		frmMxchen.getContentPane().add(scrollPane, BorderLayout.EAST);
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
