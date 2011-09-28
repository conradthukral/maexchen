package spectator;

import javax.swing.table.AbstractTableModel;

public class ScoreTableModel extends AbstractTableModel {

	private static final long serialVersionUID = 1L;
	
	private final Scores scores;

	public ScoreTableModel(Scores scores) {
		this.scores = scores;
	}

	public int getRowCount() {
		return scores.size();
	}

	public int getColumnCount() {
		return 2;
	}

	public Object getValueAt(int rowIndex, int columnIndex) {
		String playerName = scores.players().get(rowIndex);
		if (columnIndex == 0) {
			return playerName;
		}
		return scores.scoreFor(playerName);
	}
	
	@Override
	public String getColumnName(int column) {
		if (column == 0) {
			return "Spieler";
		}
		return "Punkte";
	}

}
