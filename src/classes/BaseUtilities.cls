public class BaseUtilities {
    
    public static final String PROFILE_NAME_ADMIN = 'OCE Admin';
    
    // symbols
    public static final String EMPTY = '';
    public static final String SPACE = ' ';
    public static final String DOT = '.';
    public static final String SEMICOLON = ';';
    public static final String COMMA = ',';
    public static final String COMMA_SPACE = COMMA + SPACE;

    public static final String HYPHEN = '-';
	
	public static final String UNDERSCORE = '_';
	public static final String DOUBLE_UNDERSCORE = UNDERSCORE + UNDERSCORE;
	
    public static final String VBAR = '|';
    public static final String VBAR_SURROUNDED_BY_SPACES = SPACE + VBAR + SPACE;
    
    public static final String SINGLE_QUOTE = '\'';
    
    public static final String ELLIPSIS = '...';
    
    public static final String NEW_LINE = '\r\n';

    public static final String SLASH = '/';
    
    public static final Decimal ZERO = 0;
    public static final Decimal ONE = 1;
    
    public static final String TO_LABEL_FUNC = 'toLabel';
    // reg exps
    public static final String DOT_REGEXP = '\\.';
    public static final String NEW_LINE_REGEXP = '\\r?\\n';
	public static final String CSV_DELIMITER_REGEX = '\\s*,\\s*';
    
    // reg options
    public static final String CASE_INSENSITIVE_REGEXP_OPTION_ON = '(?i)';

    public enum FieldType {CREATABLE, NOTCREATABLE, ALL}

    /**
     * Converts a list of strings to lower case.
     * @param a list to convert.
     * @return converted list.
     */
    public static List<String> listToLowerCase(List<String> strings){
        //optimized for(String str : strings)
        for (Integer i = 0, size = strings.size(); i < size; ++i) {
            strings[i] = strings[i].toLowerCase();
        }
        return strings;
    }

    /**
     * Converts a list of strings to upper case.
     * @param a list to convert.
     * @return converted list.
     */
    public static List<String> listToUpperCase(List<String> strings){
        //optimized for(String str : strings)
        for (Integer i = 0, size = strings.size(); i < size; ++i) {
            strings[i] = strings[i].toUpperCase();
        }
        return strings;
    }

    /**
     * Return real null if string value equals to 'null'.
     * @value to be checked.
     * @retun null, if value equals to 'null'. Othewise, return value.
     */
    public static String resetIfNull(String value) {
        return 'null' == value ? null : value;
    }

    /**
     * Returns the unique values for a given field in a list of records. Null is not included.
     * @param objects the list of records.
     * @param field values from this field will be returned.
     * @return set of values; no null.
     *
     * Added by Oles Malkov 11.09.2017
     * Does not work with parent relationship fields i.e. parent__r.fieldName
     */
    public static Set<String> getFieldValues(SObject[] objects, SObjectField field) {
        return getFieldValues(objects, field.getDescribe().getName());
    }

    /**
     * Overload that accepts field as a string.
     */
    public static Set<String> getFieldValues(SObject[] objects, String field) {
        Set<String> result = new Set<String>();
        if (null != objects) {
            for (Integer i = 0, size = objects.size(); i < size; ++i) {
                result.add(String.valueOf(objects[i].get(field)));
            }
            result.remove(null);
        }
        return result;
    }

    /**
     * Overload that accepts field as a string and has toUpper parameter.
     */
    public static Set<String> getFieldValues(SObject[] objects, String field, Boolean toUpper) {
        Set<String> result = new Set<String>();
        if (null != objects) {
            for (Integer i = 0, size = objects.size(); i < size; ++i) {
                String fieldValue = String.valueOf(objects[i].get(field));
                result.add(toUpper ? fieldValue.toUpperCase() : fieldValue.toLowerCase());
            }
            result.remove(null);
        }
        return result;
    }
	
   /**
    * Today's date
    */
    public static Date today {
        
        get {
            return today();
        }
        
    }


    /**
    * Return today's date, i.e. similar to System.today(), but it supports mocking in test scope
    */
    public static Date today() {
        
        return
            System.today()
        ;
        
    }
    	
	/**
	* Split by punctuation
	*/
	public static List<String> splitByPunctuation(String source) {
		
		List<String> values = new List<String>();
		
		
		if (isNotNullOrEmpty(source)) {
			
			values =
				source.split(
					'[\\s,;:]+'
				)
			;
			
		}
		
			
		return values;	
		
	}
	
	
	
	/**
	* Split as csv
	*/
	public static List<String> splitCsv(String csvRow) {
		
		return coalesce(csvRow).split(CSV_DELIMITER_REGEX);
		
	}
	


	/**
	* Split multiselect value into separate options
	*/
	public static List<String> splitMultiselectToOptions(String value) {
		
		List<String> options = new List<String>();
		
		
		if (isNotNullOrEmpty(value)) {
			
			options =
				value.split(
					SEMICOLON
				)
			;
			
		}
		
		
		return options;
		
	}
	
	
	/**
	* Join separate options into multiselect value
	*/
	public static String joinOptionsIntoMultiselect(List<String> options) {
		
		return
			String.join(
				options,
				SEMICOLON
			)
		;
		
	}
	
	
	
	/**
	* Filter out nulls
	*/
	public static Set<Id> filterOutNulls(Set<Id> inIds) {
		
		Set<Id> outIds = new Set<Id>();
		
		
		for (Id inId : inIds) {
			
			if (inId == null) {
				continue;
			}
			
			outIds.add(inId);
			
		}
		
		
		return outIds;
		
	}
	
	
	
    /**
    * Filter out nulls or blanks from list
    */
    public static List<String> filterOutNullsOrBlanks(List<String> inStrings) {
        
        List<String> outStrings = new List<String>();
        
        
        for (String inString : inStrings) {
            
            if (String.isNotBlank(inString)) {
                outStrings.add(inString);
            }
            
        }
        
        return outStrings;
        
    }
	
	
	
    /**
    * Convert list of strings to set
    */
    public static Set<String> toSet(List<String> listOfStrings) {
        
        Set<String> setOfStrings = new Set<String>();
        
        
        if (isNotNullOrEmpty(listOfStrings)) {
        
            setOfStrings.addAll(listOfStrings);
            
        }
        
        
        return setOfStrings;
        
    }
	
	
	
    /**
    * Convert list of ids to set
    */
    public static Set<Id> toSet(List<Id> listOfIds) {
        
        Set<Id> setOfIds = new Set<Id>();
        
        
        if (isNotNullOrEmpty(listOfIds)) {
        
            setOfIds.addAll(
            	listOfIds
            );
            
        }
        
        
        return setOfIds;
        
    }
	

    
    /**
    * Check if two incoming strings are equivalent (i.e. equal ignoring case, leading & trailing whitespaces)
    */
    public static Boolean isEquivalent(String operandOne, String operandTwo) {
        
        if (String.isBlank(operandOne) && String.isBlank(operandTwo)) {
            return true;
        }
        
        
        if (String.isBlank(operandOne) || String.isBlank(operandTwo)) {
            return false;
        }
        
        
        return
            operandOne.trim().equalsIgnoreCase(operandTwo.trim())
        ;
        
    }
    
    
    
    /**
    * Check if two incoming list of sobjects are equivalent (i.e. both null or contain records with the same ids disregarding order)
    */
    public static Boolean isEquivalent(List<SObject> operandOne, List<SObject> operandTwo) {
        
        // consider null and empty list the same
        if (isNullOrEmpty(operandOne) && isNullOrEmpty(operandTwo)) {
            return true;
        }
        
        
        if (isNullOrEmpty(operandOne) || isNullOrEmpty(operandTwo)) {
            return false;
        }
        
        
        if (operandOne.size() <> operandTwo.size()) {
            return false;
        }
  
  
        return
            mapToIds(
                operandOne
            )
            ==
            mapToIds(
                operandTwo
            )
        ;
        
    }
    
    
    
    /**
    * Check if incoming object is null or empty (supports string & lists)
    */
    public static Boolean isNullOrEmpty(Object obj) {
        
        return
            obj == null
            ||
            (
                obj instanceof String
                &&
                String.isBlank( (String)obj )
            )
            ||
            (
                obj instanceof List<Object>
                &&
                ((List<Object>)obj).isEmpty()
            )
        ;   
        
    }
    
    
    /**
    * Check if incoming set of ids is null or empty
    */
    public static Boolean isNullOrEmpty(Set<Id> ids) {
        
        return
            ids == null
            ||
            ids.isEmpty()
        ;
        
    }
    
    
    /**
    * Check if incoming set of ids is not null or empty
    */
    public static Boolean isNotNullOrEmpty(Set<Id> ids) {
        
        return !isNullOrEmpty(ids);
        
    }
    
    
    /**
    * Check if incoming set of values is null or empty
    */
    public static Boolean isNullOrEmpty(Set<String> values) {
        
        return
            values == null
            ||
            values.isEmpty()
        ;
        
    }
    
    
    /**
    * Check if incoming set of values is not null or empty
    */
    public static Boolean isNotNullOrEmpty(Set<String> values) {
        
        return !isNullOrEmpty(values);
        
    }
    
    
    /**
    * Check if incoming map of ids to objects is null or empty
    */
    public static Boolean isNullOrEmpty(Map<Id, Object> idToObject) {
    	
    	return
    		idToObject == null
    		||
    		idToObject.size() == 0
    	;
    	
    }
    
    
    /**
    * Check if incoming map of ids to objects is not null or empty
    */
    public static Boolean isNotNullOrEmpty(Map<Id, Object> idToObject) {
    	
    	return
    		!isNullOrEmpty(
    			idToObject
    		)
    	;
    	
    }

    
    /**
    * Check if incoming object is not null or empty (supports string & lists)
    */
    public static Boolean isNotNullOrEmpty(Object obj) {
    
        return !isNullOrEmpty(obj);

    }
    
    
    /**
    * Assert condition and throw custom exception if not true.
    * This is a replacement of system assert method, cause it's not possible to catch thrown system exception.
    */
    public static void assert(Boolean condition, String message) {
        
        if (condition <> true) {
            
            throw 
                new CustomAssertException(
                    'Assertion Failed: ' + message
                )
            ;
            
        }
        
    }
    
    
    /**
    * Assert if objects match and throw custom exception if not true.
    * This is a replacement of system assert method, cause it's not possible to catch thrown system exception.
    */
    public static void assertEquals(Object expected, Object actual, String message) {
        
        if (expected <> actual) {
            
            throw 
                new CustomAssertException(
                    'Assertion Failed: ' + message + ': Expected: ' + expected + ' Actual: ' + actual
                )
            ;
            
        }
        
    }
    
    
    /**
    * Return empty string replacement in case of null source
    */
    public static String coalesce(String source) {
        
        return
            coalesce(
                source,
                EMPTY
            )
        ;
        
    }
    
    
    /**
    * Return provided replacement in case of null source
    */
    public static String coalesce(String source, String replacement) {
        
        return
            String.isBlank(source)
            ?
                replacement
                :
                source
        ;
        
    }
    
    
    /**
    * Return provided replacement in case of null source
    */
    public static Id coalesce(Id source, Id replacement) {
        
        return
            source == null
            ?
                replacement
                :
                source
        ;
        
    }
    
    
    /**
    * Return false replacement in case of null source
    */
    public static Boolean coalesce(Boolean source) {
        
        return
            source == null
            ?
                false
                :
                source
        ;
        
    }



    /**
    * Return provided replacement in case of null source
    */
    public static Boolean coalesce(Boolean source, Boolean replacement) {

        return
            source == null
            ?
                replacement
                :
                source
        ;

    }



    /**
     * Return provided replacement in case of null source
     */
    public static Integer coalesce(Integer source, Integer replacement) {

        return
                source == null
                        ?
                        replacement
                        :
                        source
                ;
    }


    
    /**
    * Return zero-number replacement in case of null source
    */
    public static Decimal coalesce(Decimal source) {
        
        return
            coalesce(
                source,
                ZERO
            )
        ;
        
    }

    
    
    /**
    * Return provided replacement in case of null source
    */
    public static Decimal coalesce(Decimal source, Decimal replacement) {
        
        return
            source == null
            ?
                replacement
                :
                source
        ;
        
    }



    /**
    * Convert incoming list into string using comma+space as default delimiter
    */
    public static String toString(List<String> values) {
        
        return
            toString(
                values, 
                COMMA_SPACE
            )
        ;
        
    }
    
    
    /**
    * Convert incoming list into string using provided delimiter
    */
    public static String toString(List<String> values, String delimiter) {
        
        return
            String.join(
                values,
                delimiter
            )
        ;
        
    }
    
    
    /**
    * Map incoming list of sobjects to array of another sobjects using provided field name refering to related record
    */
    public static List<SObject> mapToSObjects(List<SObject> objects, String sobjectFieldName) {
      
        List<SObject> sobjects = new List<SObject>();
      
         
        if (isNotNullOrEmpty(objects)) {
            
            for (SObject obj : objects) {
                
                sobjects.add(
                    obj.getSObject(sobjectFieldName)
                );
                
            }
            
        }
      
      
        return sobjects;
        
    }
    
    
    /**
    * Map list of sobjects to set of ids using provided field name to fetch id
    */
    public static Set<Id> mapToIds(List<SObject> objects, String idFieldName) {
      
        Set<Id> ids = new Set<Id>();
      
         
        if (isNotNullOrEmpty(objects)) {
            
            for (SObject obj : objects) {
                
                ids.add(
                    (Id)
                    obj.get(idFieldName)
                );
                
            }
            
        }
      
      
        return ids;
          
    }
    
    
    /**
    * Map list of sobjects to set of ids
    */
    public static Set<Id> mapToIds(List<SObject> objects) {
      
        Set<Id> ids = new Set<Id>();
      
         
        if (isNotNullOrEmpty(objects)) {
            
            for (SObject obj : objects) {
                ids.add(obj.Id);
            }
            
        }
      
      
        return ids;
          
    }
    
    
    /**
    * Map list of sobjects to list of strings using provided field name
    */
    public static List<String> mapToStrings(List<SObject> objects, String textFieldName) {
      
        List<String> values = new List<String>();
      
         
        if (isNotNullOrEmpty(objects)) {
            
            for (SObject obj : objects) {
                
                values.add(
                    String.valueOf(
                        obj.get(textFieldName)
                    )
                );
                
            }
            
        }
        
        
        return values;
          
    }
    
    
    /**
    * Wipe id field (i.e. set value to null) for incoming sobject.
    */
    public static SObject wipeId(SObject record) {
    
    	return 
    		(SObject)
    		getFirstIfAny(
	    		wipeId(
	    			CollectionUtilities.asList(
	    				record
	    			)
	    		)
    		)
    	;
    
    }
    
    
    /**
    * Wipe id field (i.e. set value to null) for all sobjects in incoming collections.
    */
    public static List<SObject> wipeId(List<SObject> records) {
    
    	return 
    		wipeField(
    			records, 
    			ObjectUtilities.FIELD_NAME_ID
    		)
    	;
    
    }
    
    
    /**
    * Wipe field (i.e. set value to null) for all sobjects in incoming collections.
    */
    public static List<SObject> wipeField(List<SObject> records, String fieldName) {
    	
    	for (SObject record : records) {
    		
    		record.put(
    			fieldName,
    			null
    		);
    		
    	}
    	
    	
    	return records;
    	
    }
    
    
    /**
    * Prepend provided prefix to specific text field for incoming sobject.
    */
    public static SObject prependToTextField(SObject record, String textFieldName, String prefix) {
    	
    	return
    		(SObject)
    		getFirstIfAny(
	    		prependToTextField(
	    			CollectionUtilities.asList(record),
	    			textFieldName,
	    			prefix
	    		)
    		)
    	;
    	
    }
    
    
    /**
    * Prepend provided prefix to specific text field for all sobjects in incoming collections.
    */
    public static List<SObject> prependToTextField(List<SObject> records, String textFieldName, String prefix) {
    	
    	for (SObject record : records) {
    		
    		record.put(
    			textFieldName,
    			(
	    			prefix
	    			+
	    			coalesce(
		    			String.valueOf(
			    			record.get(
			    				textFieldName
			    			)
		    			)
	    			)
    			)
    		);
    		
    	}
    	
    	
    	return records;
    	
    }
    
    
    /**
    * Convert set of ids to list
    */
    public static List<Id> toList(Set<Id> setOfIds) {
        
        List<Id> listOfIds = new List<Id>();
        
        
        if (setOfIds <> null) {
            
            listOfIds.addAll(setOfIds);
            
        }
        
        
        return listOfIds;
        
    }
    
    
    /**
    * Convert set of values to list
    */
    public static List<String> toList(Set<String> setOfValues) {
        
        List<String> listOfValues = new List<String>();
        
        
        if (setOfValues <> null) {
            
            listOfValues.addAll(setOfValues);
            
        }
        
        
        return listOfValues;
        
    }
    
    
    /**
    * Check whether incoming source match to provided regex pattern
    */
    public static Boolean match(String source, Pattern pattern) {
        
        return
            pattern.matcher(source).find()
        ;
        
    }
    
    
    /**
    * Check if incoming string matches provided regular expression
    */
    public static Boolean match(String source, String regEx) {

        return
            Pattern.matches(
                regEx, 
                coalesce(
                    source
                )
            )
        ;
        
    }
    
    
    /**
    * Wrap incoming string into regex
    */
    public static String asRegex(String source) {
        
        return
            String.isBlank(source)
            ?
                EMPTY
                :
                Pattern.quote(
                    source
                )
        ;
        
    }
    
    
    /**
    * Wrap incoming string into case-insensitive regex
    */
    public static String asCaseInsensitiveRegex(String source) {
        
        return
            String.isBlank(source)
            ?
                EMPTY
                :
                (
                    CASE_INSENSITIVE_REGEXP_OPTION_ON + asRegex(source)
                )
        ;
        
    }
    
    
    /**
    * Fetch value from incoming source by provided regexp
    */ 
    public static String extract(String source, String regexp) {
        
        Matcher matcher = 
            Pattern.compile(
                regexp
            ).matcher(source)
        ;
        
        
        return
            matcher.find() 
            ?
                matcher.group(1).trim()
                :
                null
        ;
        
    }
    
    
    /**
    * Parse number from incoming string.
    * Null is returned in case of error.
    */
    public static Integer parseNumber(String source) {
        
        if (String.isBlank(source)) {
            return null;
        }
        
        
        Integer result = null;
        
        
        try {
            
            result = Integer.valueOf(source);
            
        } catch (Exception exp) { 
        }
        
        
        return result;
        
    }
    
    
    /**
    * Check whether provided field path segment referes to field on incoming sobject
    */
    public static Boolean isField(SObject source, String fieldPathSegment) {
        
        return
            source.getSObjectType().getDescribe().fields.getMap().containsKey(
                fieldPathSegment.trim()
            )
        ;
        
    }
    
    
    /**
    * Check whether provided field path segment referes to children collections of incoming sobject
    */
    public static Boolean isChildrenCollections(SObject source, String fieldPathSegment) {
        
        for (Schema.ChildRelationship childRelationship : source.getSObjectType().getDescribe().getChildRelationships()) {
            
            if (
                isEquivalent(
                    childRelationship.getRelationshipName(),
                    fieldPathSegment
                )
            ) {
                
                return true;
                
            }
            
        }
        
        
        return false;
        
    }
    
    
    /**
    * Convert incoming object into property map (useful for reflection based techniques)
    */
    public static Map<String, Object> toPropertyMap(Object source) {
        
        return
            source <> null
            ?
                (Map<String, Object>)
                JSON.deserializeUntyped(
                    JSON.serialize(
                        source
                    )
                )
                :
                null
        ;
        
    }
    
    
    /**
    * Convert incoming object into list of property maps (useful for reflection based techniques)
    */
    public static List<Object> toPropertyList(Object source) {
        
        return
            source <> null
            ?
                (List<Object>)
                JSON.deserializeUntyped(
                    JSON.serialize(
                        source
                    )
                )
                :
                null
        ;
        
    }
    
    
    /**
    * Map incoming collection of objects (presumably some DTOs or view models) to string values extracted from the provided property
    */
	public static List<String> mapModelsToStrings(List<Object> models, String textPropertyName) {
		
		List<String> propertyValues = new List<String>();
		
		
		for (Object model : models) {
		
			propertyValues.add(
				String.valueOf(
					BaseUtilities.toPropertyMap(model).get(textPropertyName)
				)
			);
			
		}
		
		
		return propertyValues;
		
	}

    public static Map<String, String> getLabelValuePairs(List<Object> models) {

        Map<String, String> propertyLabelValuePairs = new Map<String, String>();

        for (Object model : models) {

            propertyLabelValuePairs.put(
                    String.valueOf(
                            BaseUtilities.toPropertyMap(model).get('label')
                    ),
                    String.valueOf(
                            BaseUtilities.toPropertyMap(model).get('value')
                    )
            );

        }

        return propertyLabelValuePairs;

    }
    
    
    /**
    * Map incoming collection of objects (presumably some DTOs or view models) to ids values extracted from the provided property
    */
	public static List<Id> mapModelsToIds(List<Object> models, String idPropertyName) {
		
		List<Id> propertyValues = new List<Id>();
		
		
		for (String idValue : mapModelsToStrings(models, idPropertyName)) {
			
			propertyValues.add(
				Id.valueOf(
					idValue
				)
			);
			
		}
		
		
		return propertyValues;
		
	}


    /**
    * Map incoming collection of objects (presumably some DTOs or view models) to boolean values extracted from the provided property
    */
	public static List<Boolean> mapModelsToBooleans(List<Object> models, String booleanPropertyName) {
		
		List<Boolean> propertyValues = new List<Boolean>();
		
		
		for (Object model : models) {
		
			propertyValues.add(
				Boolean.valueOf(
					BaseUtilities.toPropertyMap(model).get(booleanPropertyName)
				)
			);
			
		}
		
		
		return propertyValues;
		
	}
    
    
    /**
    * Get first element (if any) from incoming records collection, otherwise null is returned
    */
    public static Object getFirstIfAny(List<Object> records) {
        
        return
            isNullOrEmpty(records)
            ?
                null
                :
                records[0]
        ;
        
    }
    
    
    /**
    * Get first (if any) from incoming map (arbitrary one), otherwise null is returned
   	*/
   	public static SObject getFirstIfAny(Map<Id, SObject> idToRecord) {
   		
   		if (isNotNullOrEmpty(idToRecord)) {
	   		
	   		// get first element (yep, it would be arbitrary one, map doesn't enforce any order)
	   		for (SObject record : idToRecord.values()) {
	   			
	   			return record;
	   			
	   		}
	   		
   		}
   		
   		
		return null;
   		
   	}
    

    /**
    * Get first (if any) from incoming map (arbitrary one), otherwise null is returned
    */
    public static SObject getFirstIfAny(Map<String, SObject> stringToRecord) {
        
        if (isNotNullOrEmpty(stringToRecord)) {
            
            // get first element (yep, it would be arbitrary one, map doesn't enforce any order)
            for (SObject record : stringToRecord.values()) {
                
                return record;
                
            }
            
        }
        
        
        return null;
        
    }
    
	
   /**
    * Put incoming record into registry (if not there).
    * Returns existent record from the registry or just newly added.
    */
    public static SObject putIfNotThere(Map<Id, SObject> idToRecord, Id recordId, SObject newRecord) {

		SObject record = idToRecord.get(recordId);
		
		
		// not in the registry - inject new record
		if (record == null) {
			
			idToRecord.put(
				recordId,
				record = newRecord
			);
			
		}
		
		
		return record;
    	
    }
    
	
	
    /**
    * Get yesterday
    */
    public static Date getYesterday() {
        
        return
            getYesterday(
                BaseUtilities.today()
            )
        ;
        
    }


    /**
    * Get yeasterday
    */
    public static Date getYesterday(Date baseDate) {
        
        return
            baseDate.addDays(-1)
        ;
        
    }


    /**
    * Get tomorrow
    */
    public static Date getTomorrow() {
        
        return
            getTomorrow(
                BaseUtilities.today()
            )
        ;
        
    }


    /**
    * Get tomorrow
    */
    public static Date getTomorrow(Date baseDate) {
        
        return
            baseDate.addDays(1)
        ;
        
    }
    
    
    /**
    * Join two incoming set of ids
    */
    public static Set<Id> join(Set<Id> operandOne, Set<Id> operandTwo) {
    
        Set<Id> result = new Set<Id>();
        

        if (isNotNullOrEmpty(operandOne)) {
            
            result.addAll(
                operandOne
            );
            
        }


        if (isNotNullOrEmpty(operandTwo)) {
            
            result.addAll(
                operandTwo
            );
            
        }

        
        return result;  
        
    }
    
    
    /**
    * Join two incoming lists of sets of type Id
    */    
    public static Set<Id> join( List<Set<Id>> listSetIds ){

        if ( isNullOrEmpty( listSetIds ) ){
            return new Set<Id>();
        }


        Set<Id> resultSet = new Set<Id>();

        for ( Set<Id> setIds : listSetIds ){

            resultSet.addAll( setIds );
        }


        return resultSet;
    }


    /**
    * Union of two incoming set of ids.
    * New set is returned.
    */
    public static Set<Id> unite(Set<Id> operandOne, Set<Id> operandTwo) {
        
        return
            join(
                operandOne,
                operandTwo
            )
        ;
        
    }
    
    
    /**
    * Intersection of two incoming set of ids.
    * New set is returned.
    */
    public static Set<Id> intersect(Set<Id> operandOne, Set<Id> operandTwo) {
        
        Set<Id> result = new Set<Id>();
        

        // intersection with empty set = empty set      
        if (
            isNullOrEmpty(operandOne)
            ||
            isNullOrEmpty(operandTwo)
        ) {
            return result;
        }
        
        
        result.addAll(
            operandOne
        );
            
        
        result.retainAll(operandTwo);
        
        
        return result; 
        
    }


    /**
    * Intersection of two incoming set of strings.
    * New set is returned.
    */
    public static Set<String> intersect(Set<String> operandOne, Set<String> operandTwo) {
        
        Set<String> result = new Set<String>();
        

        // intersection with empty set = empty set      
        if (
            isNullOrEmpty(operandOne)
            ||
            isNullOrEmpty(operandTwo)
        ) {
            return result;
        }
        
        
        result.addAll(
            operandOne
        );
            
        
        result.retainAll(operandTwo);
        
        
        return result; 
        
    }
    
    
    /**
    * Set subtraction: operandOne - operandTwo
    * New set is returned.
    */
    public static Set<Id> subtract(Set<Id> operandOne, Set<Id> operandTwo) {
        
        Set<Id> result = new Set<Id>();
        

        // operand one empty: result => empty set
        if (isNullOrEmpty(operandOne)) {
            return result;
        }


        result.addAll(
            operandOne
        );
            

        // operand two empty: result => copy of operand one
        if (isNullOrEmpty(operandTwo)) {
            return result;
        }
        
        
        result.removeAll(operandTwo);
        
        
        return result; 
        
    }
    
    
    /**
    * Set subtraction: operandOne - operandTwo
    * New set is returned.
    */
    public static Set<String> subtract(Set<String> operandOne, Set<String> operandTwo) {
        
        Set<String> result = new Set<String>();
        

        // operand one empty: result => empty set
        if (isNullOrEmpty(operandOne)) {
            return result;
        }


        result.addAll(
            operandOne
        );
            

        // operand two empty: result => copy of operand one
        if (isNullOrEmpty(operandTwo)) {
            return result;
        }
        
        
        result.removeAll(operandTwo);
        
        
        return result; 
        
    }
    
    
    /**
    * Exclusive or
    */
    public static Boolean xor(Boolean operandOne, Boolean operandTwo) {
        
        return
            (
                operandOne == true
                &&
                operandTwo == false
            )
            ||
            (
                operandOne == false
                &&
                operandTwo == true
            )
        ;
        
    }
    

    /**
    * getLookupFieldNamePath (String fieldPath)
    * Returns a fieldPath for a relationship (e.g. for AccountId - will return Account.Name)
    */
    public static String getRelationshipFieldNamePath(String fieldPath) {
        String result = getRelationshipName(fieldPath) + '.Name';
        return result;
    }
    
    /**
    * getRelationshipName (String fieldPath)
    * Returns relationshipName from a fieldPath - e.g. from Custom_Lookup__c -> Custom_Lookup__r
    */
    public static String getRelationshipName(String fieldPath) {
        String result;
        if (fieldPath.contains('__c'))
        {
            result = fieldPath.replace('__c', '__r');
        }
        else
        {
            result = fieldPath.replace('Id', '');
        }
        return result;
    }
    
    /**
    * getFieldNameByRelationName (String fieldPath)
    * Returns relationshipName from a fieldPath - e.g. from Custom_Lookup__r -> Custom_Lookup__c
    */
    public static String getFieldNameByRelationName(String referenceFieldName) {
        if (referenceFieldName.contains('__r')){
            return referenceFieldName.replace('__r', '__c');
        }
        return referenceFieldName + 'Id';
    }

    /**
    * getValueForReferenceType (String fieldPath, SObject record)
    * Returns a value of relationship name by a fieldpath from a record (e.g. will return Account.Name value for a Contact record if will be called with params 'AccountId', contactRecord)
    */
    public static String getValueForReferenceTypeName(String fieldPath, SObject record) {
        String result = '';
        SObject parentSObject = record.getSObject(getRelationshipName(fieldPath));
        if (parentSObject != null) {
            result = String.valueOf(parentSObject.get('Name'));
        }
        return result;
    }
    
    
    
    /*
     * General custom assert exception to be used as a replacement of system one due to inability to catch it.
    */
    public class CustomAssertException extends Exception {
        
    }
    
    /*
     * Serves to make exception context more clear.
    */
    public class NoSuchSObjectException extends Exception {

    }

    /*
     * Serves to make exception context more clear.
    */
    public class NoSuchFieldException extends Exception {

    }
    
     /**
     * Check if user has assigned OCE Admin Profile.
     * @return Boolean.
     */
    public static Boolean isAdmin() {
        Boolean isAdmin = false;
        Profile profile = (Profile)DataLayer.querySingle([SELECT Id, Name FROM Profile WHERE Id = : UserInfo.getProfileId()]);
        if(PROFILE_NAME_ADMIN.equalsIgnoreCase(profile.Name)) {
            isAdmin = true;
        }
        return isAdmin;
    }
    
    
    /**
    * Wrap incoming string into single quotes escaping already existent quotes along the way.
    */
    public static String quote(String source) {
        
        return
            SINGLE_QUOTE
            +
            String.escapeSingleQuotes(
                coalesce(
                    source
                )
            )
            +
            SINGLE_QUOTE
        ;
        
    }
    
    
    /**
    * checks if sobject exists in the org.
    */

    public static Boolean isSobjectExist(String sobjectName){
        
        if(Schema.getGlobalDescribe().get(sobjectName) != null)
            return true;
        else 
            return false;

    }

    /**
    *  This method is used to get Get all fields of an Object.
    *   @param      thisSObject - the Object Type passed to the method.
    *   @return     list<string> - the list of String returned.
    */   

    public static List<string> getAllFields( sObject thisSObject) {
        list<string> fields = new list<string>();
        for(String f: thisSObject.getsObjectType().getDescribe().fields.getMap().Keyset()) {
            fields.add(f);
        }
        return fields;
    }

    /**
    *  This method is used to get Get all fields of an Object by type of fields.
    *   @param      objectName - the Object Type passed to the method.
    *   @param      type - fields type: FieldType.CREATABLE, FieldType.NOTCREATABLE, FieldType.ALL
    *   @return     list<string> - the list of String returned.
    */
    public static List<String> getFieldsOfObject(String objectName, FieldType type) {

        List<String> fieldsNames = new List<String>();

        for( Schema.DescribeFieldResult fieldDescription : ObjectUtilities.getObjectFieldsDescribes( objectName ) ) {

            if( type == null || type == FieldType.ALL ) {
                fieldsNames.add( fieldDescription.getName() );
                continue;
            }

            if( type == FieldType.CREATABLE && fieldDescription.isCreateable() ) {
                fieldsNames.add( fieldDescription.getName() );
                continue;
            }

            if( type == FieldType.NOTCREATABLE && !fieldDescription.isCreateable() ) {
                fieldsNames.add( fieldDescription.getName() );
                continue;
            }

        }

        return fieldsNames;
    }

    /**
    *  Check if any approval process is active for the sObject.
    */ 
    public static boolean isApprovalProcessActive(String sObjectType){
        List<ProcessDefinition> approvalProcess = (List<ProcessDefinition>)DataLayer.queryAll([select  Id,State,TableEnumOrId from ProcessDefinition 
                                                    where State = 'Active' and TableEnumOrId =:sObjectType and Type='Approval']);
        
        if(approvalProcess.size() > 0)
            return true;
        else 
            return false;
    }
 
    /**
    * Get profile by id
    */
    public static Profile getProfileById( Id profileId ) {
        return (Profile)DataLayer.querySingle([SELECT Name 
                FROM Profile 
                WHERE Id = : profileId]);
    }
	
	
	
    /**
    * Truncate incoming string to provided number of charachters, optionally append ellipsis
    */
    public static String truncate(String source, Integer numberOfCharacters, Boolean appendEllipsis) {
        
        return
            (
                String.isBlank(source)
                ||
                source.length() <= numberOfCharacters
            )
            ?
                source
                :
                (
                    source.left(numberOfCharacters) 
                    + 
                    (appendEllipsis ? ELLIPSIS : EMPTY)
                )
        ;
        
    }
    
    
    
    /**
    * Shorten incoming string to provided length and added ellipsis
    */
    public static String shortenTo(String source, Integer numberOfCharacters) {
    	
    	return
    		truncate(
    			source,
    			numberOfCharacters,
    			true
    		)
    	;
    	
    }
    
    
    
    /**
    * Format incoming message with one provided param
    */
    public static String format(String message, Object value) {
    	
    	return
			String.format(
				message,
				new List<String> {
					String.valueOf(
						value
					)
				}
			)
		;
    	
    }
    
    /**
     * Analogue of Javascript Array Filter function
     */
    public static List<Object> filter(List<Object> genericObjectList, FilterInterface filter) {
        List<Object> filteredList = new List<Object>();
        for ( Object genericObject: genericObjectList ) {
            Map<String, Object> mapRepresentation = toPropertyMap( genericObject );
            if ( filter.filter( mapRepresentation ) ) {
                filteredList.add( genericObject );
            }
        }
        return filteredList;
    }
    
    
    
    /**
    * Log incoming exception (location is provided)
    */		
	public static void log(Exception exp, String whereOccured) {
		
		LogService.getLogger().logException(
			exp, 
			whereOccured
		);
		
	}
    
    
    
    /**
    * Log incoming exception (no specific location set)
    */		
	public static void log(Exception exp) {
		
		log(exp, null);
		
	}
    
    
    
    /**
    * Log and re-throw incoming exception (no specific location set)
    */		
	public static void logAndRethrow(Exception exp) {
		
		logAndRethrow(exp, null);
		
	}
    
    
    
    /**
    * Log and re-throw incoming exception (location is provided)
    */		
	public static void logAndRethrow(Exception exp, String whereOccured) {
		
		log(exp, whereOccured);
		
		throw exp;
		
	}
    
    /**
    * @description Method getRecords returns QuickAction Metadata records by selected location
    * @param Exception ex Exception to log and to convert to AuraHandledException from.
    * @param String whereOccured where this exception occured.
    * @return AuraHandledException exception object.
    */
    public static AuraHandledException getAuraHandledException(Exception ex, String whereOccured) {
        BaseUtilities.log(ex, whereOccured);
        return AuraUtils.throwHandledException(ex.getMessage());
    }
    
	
	
    /*
    * Casts any value to specified convertion type. 
    * @param convertToType do NOT suport any reference to generic 'Object', since JSON deserialize processing.
    * E.g. may be used to cast generic Map<Object, Object> to Map<Id, Account> map.
    */
    public static Object castToType( Object value, Type convertToType ){

        if ( value == null ){
            return null;
        }

        if ( convertToType == null ){
            return value;
        }


        Object result = null;


        try {

            result = 
                JSON.deserialize(
                    JSON.serialize(
                        value
                    ),
                    convertToType
                );               

        } catch( Exception e ){ 

            throw new BaseException( 'invalid convertion type for specified value' );

        }


        return result;

    }


    /* 
    *   @incomingObjectMap is either object or Map. Set and List are not supported.
    */
    public static Object retainProperties( Object incomingObjectMap, List<Object> propertiesToRetain, Type convertToType ){


        if ( incomingObjectMap == null 
            || 
            convertToType == null
            ||
            propertiesToRetain == null 
        ){

            return incomingObjectMap;
        }


        Map<String, Object> propertyMap =
            toPropertyMap( incomingObjectMap );
        

        //for set of string property names 
        Set<String> propertiesToRetainSet = new Set<String>();
        
        for ( Object valueToRetain : propertiesToRetain ){
            
            propertiesToRetainSet.add( 
                String.valueOf( 
                    valueToRetain
                ) 
            );

        }


        Map<String, Object> resultMap = new Map<String, Object>();


        for ( String key : propertyMap.keySet() ){
            
            if ( propertiesToRetainSet.contains( key ) ){

                resultMap.put(
                    key,
                    propertyMap.get( key )
                );

            }

        }


        return 
            castToType(
                resultMap,
                convertToType
            );

    }


    /*
    * converts string to Boolean. null value returns false.
    */
    public static Boolean toBoolean( String valueStr ){

        //any string other then 'true' wlil return false (replace null to empty string).
        return 
            Boolean.valueOf(
                BaseUtilities.coalesce(
                    valueStr
                )
            );

    }


    public static Map<String, Set<String>> mergeTwoMaps(Map<String, Set<String>> firstMap, Map<String, Set<String>> secondMap) {

        Map<String, Set<String>> resultMap = new Map<String, Set<String>>(firstMap);

        for(String key : secondMap.keySet()) {

            Set<String> firstMapValueForKey = firstMap.get(key);

            if( BaseUtilities.isNullOrEmpty(firstMapValueForKey) ) {
                firstMapValueForKey = new Set<String>();
            }

            firstMapValueForKey.addAll(secondMap.get(key));
            resultMap.put(key, firstMapValueForKey);

        }

        return resultMap;
    }
	
	
	/**
	* Wrap incoming string into provided delimiter, i.e. prepending and appending
	*/
	public static String wrapIn(String source, String delimiter) {
		
		return delimiter + source + delimiter;
		
	}

    /**
    * Wrap FieldName with toLabel() SOQL function for getting values translated
    * Adding it here because of patching restrictions and existing dependency
    * Todo: move to the appropriate class
    *
    * @param fieldName - field to wrap
    *
    * @return String - wrapped field for query
    */
    public static String wrapFieldWithToLabelFunction(SObjectField fieldToken) {
        return wrapFieldWithToLabelFunction(String.valueOf(fieldToken));
    }

    /**
    * Wrap FieldName with toLabel() SOQL function for getting values translated
    * Adding it here because of patching restrictions and existing dependency
    * Todo: move to the appropriate class
    *
    * @param fieldName - field to wrap
    *
    * @return String - wrapped field for query
    */
    public static String wrapFieldWithToLabelFunction(String fieldName) {
        return 'toLabel(' + fieldName + ')';
    }

    /**
     * Remove the `toLabel' function from the fields
     *
     * @param fields list of fields
     *
     * @return list of fields without the toLabel function
     */
    public static List<String> removeFieldToLabelWrap(List<String> fields){
        List<String> newFields = new List<String>();

        for(String field : fields){
            if(field.startsWith(TO_LABEL_FUNC)){
                field = field.removeStart(TO_LABEL_FUNC);
                field = field.removeStart('(');
                field = field.removeEnd(')');
            }

            newFields.add(field);
        }

        return newFields;
    }

    /**
    * Wrap picklist and multipicklist Fields with toLabel() SOQL function for getting values translated
    * Adding it here because of patching restrictions and existing dependency
    * Todo: move to the appropriate class
    *
    * @param sObjectType - sObjectToken, fields belongs to
    * @param fieldSet - fields to check and wrap
    *
    * @return Set<String> - fields wrapped field for query
    */
    public static List<String> encloseWithLabelFunction(SObjectType sObjectType, Set<String> fieldSet){
        Map<String, Schema.SObjectField> fieldResultMap = sObjectType.getDescribe().fields.getMap();
        List<String> fields = new List<String>();

        for (String fieldName : fieldSet){
            if (!fieldResultMap.containsKey(fieldName.toLowerCase())){
                fields.add(fieldName);
            } else {
                String type = fieldResultMap.get(fieldName.toLowerCase()).getDescribe().getType().name();

                if (type.equalsIgnoreCase('picklist') || type.equalsIgnoreCase('multipicklist')) {
                    fields.add('toLabel(' + fieldName + ')');
                } else {
                    fields.add(fieldName);
                }
            }
        }
        return fields;
    }

	
	
	/**
	* Wait for one sec
	*/
	public static void waitForOneSecond() {
		
		wait(1000);
		
	}
	
	
	
	/**
	* Wait for provided number of milli sec (use with caution, do not pass huge values, otherwise it may hit CPU limit)
	*/
	public static void wait(Integer millisec) {
    	
		if (millisec == null || millisec < 0) {
      		return;
		}
		
		Long startTime = DateTime.now().getTime();
		Long finishTime = DateTime.now().getTime();
    	
    	while ((finishTime - startTime) < millisec) {
      		finishTime = DateTime.now().getTime();
    	}
    	
	}
	
	
	
	/**
	* Get record id in null-safe way
	*/
	public static Id getRecordIdIfAny(SObject record) {
		
		return
			record <> null 
			? 
				record.Id 
				: 
				null
		;
		
	}
	
	
}