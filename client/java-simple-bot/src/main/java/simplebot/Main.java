package simplebot;

import java.io.IOException;

import udphelper.MessageListener;
import udphelper.UdpCommunicator;

public class Main {

	public static void main(String[] args) throws IOException {
		String serverHost = args[0];
		int serverPort = Integer.parseInt(args[1]);
		String clientName = args[2];
		
		UdpCommunicator communicator = new UdpCommunicator(serverHost, serverPort);
		MessageListener bot = new RandomBot(clientName, communicator.getMessageSender());
		communicator.addMessageListener(bot);
		communicator.listenForMessages();
	}

}
