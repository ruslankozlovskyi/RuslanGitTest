/**
* Helper class to hold soql related utilities, e.g. validation query syntax etc.
*/
public with sharing class SoqlUtilities {

	// sorting directions
	public static final String SORTING_ASC = 'ASC';
	public static final String SORTING_DESC = 'DESC';
	
	
	// date literals
	public static final String DATE_LITERAL_TODAY = 'TODAY';
	public static final String DATE_LITERAL_YESTERDAY = 'YESTERDAY';
	public static final String DATE_LITERAL_TOMORROW = 'TOMORROW';
	public static final String DATE_LITERAL_THIS_WEEK = 'THIS_WEEK';
	public static final String DATE_LITERAL_LAST_WEEK = 'LAST_WEEK';
	public static final String DATE_LITERAL_NEXT_WEEK = 'NEXT_WEEK';
	public static final String DATE_LITERAL_THIS_MONTH = 'THIS_MONTH';
	public static final String DATE_LITERAL_LAST_MONTH = 'LAST_MONTH';
	public static final String DATE_LITERAL_NEXT_MONTH = 'NEXT_MONTH';
	public static final String DATE_LITERAL_THIS_QUARTER = 'THIS_QUARTER';
	public static final String DATE_LITERAL_LAST_QUARTER = 'LAST_QUARTER';
	public static final String DATE_LITERAL_NEXT_QUARTER = 'NEXT_QUARTER';
	public static final String DATE_LITERAL_THIS_YEAR = 'THIS_YEAR';
	public static final String DATE_LITERAL_LAST_YEAR = 'LAST_YEAR';
	public static final String DATE_LITERAL_NEXT_YEAR = 'NEXT_YEAR';
	public static final String DATE_LITERAL_LAST_30_DAYS = 'LAST_N_DAYS:30';
	public static final String DATE_LITERAL_LAST_60_DAYS = 'LAST_N_DAYS:60';
	public static final String DATE_LITERAL_LAST_90_DAYS = 'LAST_N_DAYS:90';

	
	
	/**
	* Escape soql term, i.g. object/field name
	*/
	public static String escape(String term) {
		
		return 
			BaseUtilities.isNullOrEmpty(term)
			?
				term
				:
				String.escapeSingleQuotes(
					term
				)
		;
		
	}
	
	
	
	/**
	* Get main object to execute query against, i.e. the one mentioned in FROM section
	*/
	public static String getFromObjectName(String query) {
		
		return 
			query
				.replaceAll('\\(.*?\\)', '')
				.replaceAll('(?i).*FROM\\s+(\\w+).*', '$1')
		;
		
	}
	
	
	
	/**
	* Generate string representation of fields list to be used in SELECT statement from incoming set
	*/
	public static String toListOfFields(Set<String> fieldNames) {
		
		List<String> escapedFieldNames = new List<String>();
		
		
		for (String fieldName : fieldNames) {
			
			escapedFieldNames.add(
				escape(
					fieldName
				)
			);
			
		}
		
		
		return 
        	BaseUtilities.toString(
        		escapedFieldNames
        	)
        ;
		
	}
	
	
	
	/**
	* Wrap incoming term as keyword criteria to be used in LIKE statement
	*/
	public static String asKeywordCriteria(String term) {
		
		return '\'%' + String.escapeSingleQuotes(term) + '%\'';
		
	}
	
	
	
	/**
	* Check whether incoming query has a valid syntax, i.e. is safe to execute.
	* Note that 1 DML statement is issued here to check.
	* To limit the number of records it would be reasonable for incoming query to have 'LIMIT 1' appended.
	*/
	public static Boolean isValidQuery(String query) {
		
		Boolean isValid = true;
		
		
		try {
			
			DataLayer.queryAll(query);
			
		} catch (Exception exp) {
			
			isValid = false;
			
		}
		
		
		return isValid;
		
	}
	
	
	
	/**
	* Check whether provided sorting mode is ascending
	*/
	public static Boolean isAscending(String sortingDirection) {
		
		return
			BaseUtilities.isEquivalent(
				sortingDirection,
				SORTING_ASC
			)
		;
		
	}
	
	
	
	/**
	* Check whether provided sorting mode is descending
	*/
	public static Boolean isDescending(String sortingDirection) {
		
		return
			BaseUtilities.isEquivalent(
				sortingDirection,
				SORTING_DESC
			)
		;
		
	}
	
	
}