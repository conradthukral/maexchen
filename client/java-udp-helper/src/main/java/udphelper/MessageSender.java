package udphelper;

import java.io.IOException;

public interface MessageSender {

	public void send(String message) throws IOException;
	
}
