package simplebot;

import java.io.IOException;

import udphelper.UdpCommunicator;

public class Main {

	public static void main(String[] args) throws IOException {
		String serverHost = args[0];
		int serverPort = Integer.parseInt(args[1]);
		String clientName = args[2];
		
		UdpCommunicator communicator = new UdpCommunicator(serverHost, serverPort);
		communicator.addMessageListener(new SimpleBot(clientName, communicator.getMessageSender()));
		communicator.listenForMessages();
	}

}
