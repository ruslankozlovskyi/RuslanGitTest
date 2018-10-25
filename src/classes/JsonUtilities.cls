/**
* Helper class to hold json related utilities.
*/
public with sharing class JsonUtilities {
	
	
	/**
	* Parse incoming json as general object
	*/
	public static Map<String, Object> toObject(String value) {
		
		return
			(Map<String, Object>)
            JSON.deserializeUntyped(
            	value
			)
		;
		
	}

	
}