package udphelper;

@FunctionalInterface
public interface MessageListener {
	
	void onMessage(String message);
	
}
