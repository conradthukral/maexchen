package simplebot;

import java.io.IOException;

import udphelper.MessageListener;
import udphelper.MessageSender;

public class SimpleBot implements MessageListener {

	private final MessageSender messageSender;

	public SimpleBot(String name, MessageSender messageSender) {
		this.messageSender = messageSender;
		tryToSend("REGISTER;" + name);
	}

	private void tryToSend(String message) {
		try {
			messageSender.send(message);
		} catch (IOException e) {
			System.err.println("Failed to send " + message + ": " + e.getMessage());
		}
	}

	public void onMessage(String message) {
		System.out.println(message);
		String[] parts = message.split(";");
		if (parts[0].equals("ROUND STARTING")) {
			tryToSend("JOIN;"+parts[1]);
		} else if (parts[0].equals("YOUR TURN")) {
			tryToSend("ROLL;"+parts[1]);
		} else if (parts[0].equals("ROLLED")) {
			tryToSend("ANNOUNCE;" + parts[1] + ";" + parts[2]);
		}
	}

}
