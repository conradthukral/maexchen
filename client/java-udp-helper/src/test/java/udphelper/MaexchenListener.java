package udphelper;

import java.io.IOException;

import udphelper.MessageListener;
import udphelper.UdpCommunicator;

public class MaexchenListener {

	public static class PrintingMessageListener implements MessageListener {

		public void onMessage(String message) {
			System.out.println(message);
		}

	}

	public static void main(String[] args) throws IOException {
		UdpCommunicator communicator = new UdpCommunicator("localhost", 9000);
		System.out.println("Client port: " + communicator.getLocalPort());
		
		communicator.addMessageListener(new PrintingMessageListener());
		communicator.send("REGISTER;listener;listener");
		communicator.listenForMessages();
	}

}
