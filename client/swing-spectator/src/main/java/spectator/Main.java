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
		
		ScoreListener scoreListener = new ScoreListener() {
			
			public void scoresAfterRound(Scores scores, int roundNumber) {
				window.showScores(roundNumber, scores);				
			}
		};
		
		UdpCommunicator communicator = new UdpCommunicator("localhost", 9000);
		communicator.addMessageListener(new DataCollector(roundListener, scoreListener));
		communicator.getMessageSender().send("REGISTER;spectator");
		
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
