package spectator;

import java.awt.EventQueue;
import java.io.IOException;

import javax.swing.UIManager;

import udphelper.UdpCommunicator;

public class Main {
	
	public static void main(String[] args) throws IOException {
		final SpectatorApplication window = new SpectatorApplication();

		RoundListener roundListener = new ThrottlingRoundListener(new RoundListener() {
			public void roundCompleted(int roundNumber, String completeRound) {
				window.updateRoundData(roundNumber, completeRound);
			}
		});
		
		ScoreListener highscoreUpdater = new ScoreListener() {
			public void scoresAfterRound(Scores scores, int roundNumber) {
				window.showScores(roundNumber, scores);				
			}
		};
		ScoreListener pointsPerMinuteUpdater = new PointsPerMinuteCalculator(new PointsPerMinuteDatasetUpdater(window.getPointsPerMinute()));
		
		DataCollector dataCollector = new DataCollector(roundListener);
		dataCollector.addScoreListener(highscoreUpdater);
		dataCollector.addScoreListener(pointsPerMinuteUpdater);
		
		UdpCommunicator communicator = new UdpCommunicator("localhost", 9000);
		communicator.addMessageListener(dataCollector);
		communicator.getMessageSender().send("REGISTER_SPECTATOR;spectator");
		
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
					window.show();
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
		
		communicator.listenForMessages();
	}
	
}
