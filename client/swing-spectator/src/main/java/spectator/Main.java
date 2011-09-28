package spectator;

import java.awt.EventQueue;
import java.io.IOException;

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
			
			public void currentScores(Scores scores) {
				window.showScores(scores);				
			}
		};
		
		UdpCommunicator communicator = new UdpCommunicator("localhost", 9000);
		communicator.addMessageListener(new DataCollector(roundListener, scoreListener));
		communicator.getMessageSender().send("REGISTER;spectator");
		
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					window.show();
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
		
		communicator.listenForMessages();
	}
	
}
