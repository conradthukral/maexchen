package spectator;

import java.util.ArrayList;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;

public class Scores {

	private final SortedMap<String, Integer> scores = new TreeMap<String, Integer>();
	
	public static Scores parse(String message) {
		Scores result = new Scores();
		String scoresPart = message.substring(message.indexOf(';') + 1);
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
		return new ArrayList<String>(scores.keySet());
	}
	
	public int scoreFor(String player) {
		Integer result = scores.get(player);
		if (result == null) return 0;
		return result;
	}
	
	public int size() {
		return scores.size();
	}

}
