package spectator;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Scores {

	private final Map<String, Integer> scores = new HashMap<String, Integer>();
	
	private final Comparator<String> compareByScores = new Comparator<String>() {
		public int compare(String o1, String o2) {
			int score1 = scoreFor(o1);
			int score2 = scoreFor(o2);
			return score2 - score1;
		}
	};
	
	public static Scores parse(String message) {
		Scores result = new Scores();
		String scoresPart = message.substring(message.indexOf(';') + 1);
		if (scoresPart.isEmpty()) {
			return result;
		}
		String[] playerScores = scoresPart.split(",");
		for (String playerScore : playerScores) {
			int index = playerScore.indexOf(':');
			String name = playerScore.substring(0, index);
			int score = Integer.parseInt(playerScore.substring(index+1));
			result.put(name, score);
		}
		return result;
	}

	private void put(String name, int score) {
		scores.put(name, score);
	}
	
	public List<String> players() {
		ArrayList<String> result = new ArrayList<String>(scores.keySet());
		Collections.sort(result, compareByScores);
		return result;
	}
	
	public int scoreFor(String player) {
		Integer result = scores.get(player);
		if (result == null) return 0;
		return result;
	}
	
	public int size() {
		return scores.size();
	}

	public boolean hasPlayer(String player) {
		return scores.containsKey(player);
	}

}
