/**
* Helper class to hold collection related utilities.
*/
public with sharing class CollectionUtilities {
	
	// regex
	public static final String ARRAY_NOTATION_INDEX_REGEX = '\\[\\s*(\\d+)\\s*\\]';
	
	// enum to hold specific values, like 'no value' (cause null itself is still a value)
	public enum Value { NO_VALUE }
	
	
	
	/**
	* Get value by key from map (if present) or return default one
	*/
	public static Object getValueIfPresent(Map<String, Object> keyToValue, String key, Object defaultValue) {
		
		if (keyToValue == null || keyToValue.isEmpty()) {
			return defaultValue;
		}
		
		
		return
    		keyToValue.containsKey(key)
    		?
    			keyToValue.get(key)
    			:
    			defaultValue
		;
		
	}
	
	
	
	/**
	* Increment value by
	*/
	public static Integer incrementValueBy(Map<String, Object> keyToValue, String key, Integer increment) {
		
		Object rowOldValue = keyToValue.get(key);
		Integer newValue;
		
		
		// key does not exist - simply use incoming value as a new one, i.e. assuming 0 as an init value
		if (rowOldValue == null) {
			
			newValue = increment;
			
		
		// key exists - increment by provided value	
		} else {
			
			newValue =
				(
					NumberUtilities.toInteger(
						rowOldValue, 
						0
					) 
					+ 
					increment
				)
			;
			
		}
		
		
		keyToValue.put(
			key,
			newValue
		);
		
		
		return newValue;
		
	}
	
	
	
	/**
	* Organize data source based on the order of provided collection (id is used for matching).
	*/
	public static List<SObject> organize(List<SObject> orderSource, List<SObject> dataSource) {
		
		List<SObject> orderedData = new List<SObject>();
		
		
		// early exit if empty collection
		if (
			BaseUtilities.isNullOrEmpty(
				orderSource
			)
			||
			BaseUtilities.isNullOrEmpty(
				dataSource
			)
		) {
			return orderedData;
		}
		
		
		// index source by id
		Map<Id, SObject> idToData = indexById(dataSource);
		
		
		// loop through order items
		for (SObject orderItem : orderSource) {
			
			// get data item
			SObject dataItem = idToData.get(orderItem.Id);
			
			// data item not found - go to next one
			if (dataItem == null) {
				continue;
			}
			
			// gather data items in correct order
			orderedData.add(
				dataItem
			);
			
		}
		
		
		return orderedData;
		
	}
	
	
	
	/**
	* Index incoming sobjects by id
	*/
	public static Map<Id, SObject> indexById(List<SObject> source) {
		
		return
			new Map<Id, SObject>(
				source
			)
		;
		
	}
	
	
	
	/**
	* Index by id field (non-unique, i.e. more than one values possible)
	*/
	public static Map<Id, List<SObject>> indexById(List<SObject> records, String idFieldName) {
		
		Map<Id, List<SObject>> idToRecords = new Map<Id, List<SObject>>();
		
		
		for (SObject record : records) {
			
			Id idFieldValue = 
				ObjectUtilities.toId(
					record.get(
						idFieldName
					)
				)
			;
			
			
			List<SObject> recordsForId = idToRecords.get(idFieldValue);
			
			
			if (recordsForId == null) {
				
				recordsForId = new List<SObject>();
				
				idToRecords.put(
					idFieldValue,
					recordsForId
				);
				
			}
			
			
			recordsForId.add(
				record
			);
			
		}
		
		
		return idToRecords;
		
	}
	
	
	
	/**
	* Index by unique id field
	*/
	public static Map<Id, SObject> indexByUniqueId(List<SObject> records, String uniqueIdFieldName) {
		
		Map<Id, SObject> idToRecord = new Map<Id, SObject>();
		
		
		for (SObject record : records) {
			
			idToRecord.put(
				ObjectUtilities.toId(
					record.get(
						uniqueIdFieldName
					)
				),
				record
			);
			
		}
		
		
		return idToRecord;
		
	}
	
	
	
	/**
	* Index by string
	*/
	public static Map<String, SObject> indexByUniqueString(List<SObject> records, String indexFieldName) {
		
		Map<String, SObject> nameToRecord = new Map<String, SObject>();
		
		
		for (SObject record : records) {
			
			nameToRecord.put(
				String.valueOf(
					record.get(
						indexFieldName
					)
				),
				record
			);
			
		}
		
		
		return nameToRecord;
		
	}
	
	
	
    /**
    * Wrap incoming string into set
    */
    public static Set<String> asSet(String value) {
        
        return
            new Set<String> {
                value
            }
        ;
        
    }
    
    
    
    /**
    * Wrap incoming id into set
    */
    public static Set<Id> asSet(Id id) {
        
        return
            new Set<Id> {
                id
            }
        ;
        
    }
        

    public static Set<String> asSet( List<Object> objects, String keyAttribute ){

        return 
            asMap(
                objects,
                keyAttribute,
                null
            )
            .keySet();
    }


    public static Set<Id> asSetIds( List<SObject> sobjects, Schema.SObjectField referenceField ){

        Set<Id> resultIds = new Set<Id>();

        for ( String valueIdStr : 
            asSet(
                sobjects,
                String.valueOf( referenceField )
            )
        ){
            if ( valueIdStr != null ){
                resultIds.add( Id.valueOf( valueIdStr ) );
            }            
        }

        return resultIds;
    }    

    
    /**
    * Wrap incoming sobject into list
    */
    public static List<SObject> asList(SObject record) {
    	
    	return
    		new List<SObject> {
    			record
    		}
    	;
    	
    }
    
    public static Map<String, Object> asMap(List<Object> objects, String keyAttribute, String valueAttribute) {
    	Map<String, Object> result = new Map<String, Object>();

    	System.assert(keyAttribute != null);

    	for (Object obj : objects) {
    		result.put(
    			String.valueOf(BaseUtilities.toPropertyMap(obj).get(keyAttribute)),
    			valueAttribute != null ? BaseUtilities.toPropertyMap(obj).get(valueAttribute) : obj
    		);
    	}

    	return result;
    }

    public static Map<String, String> asStringMap(List<Object> objects, String keyAttribute, String valueAttribute) {
    	
    	Map<String, String> result = new Map<String, String>();
    	Map<String, Object> objectMap = asMap(objects, keyAttribute, valueAttribute);

    	for (String key : objectMap.keySet()) {
    		result.put(
    			key,
    			String.valueOf(objectMap.get(key))
    		);
    	}

    	return result;
    }
    

    /**
     * Groups list to a Map, where key=sobject[fieldName], value=list of matching sobjects
     * and converts it to respective Map @convertToTypeMap
    */
    public static Object asGrouppedMap( List<SObject> sobjects, Schema.SObjectField field, Type convertToTypeMap ){

        return 
            asGrouppedMap(
                sobjects,
                String.valueOf( field ),
                convertToTypeMap
            );
    }


    /**
     * Groups list to a Map, where key=sobject[fieldName], value=list of matching sobjects
     * and converts it to respective Map @convertToTypeMap
    */
    public static Object asGrouppedMap( List<SObject> sobjects, String fieldName, Type convertToTypeMap ){

        return 
            BaseUtilities.castToType(
                asGrouppedMap(
                    sobjects,
                    PackageUtilities.addNamespacePrefixToObjectField( fieldName )
                ),
                convertToTypeMap
            );
    }


    /**
     * Groups list to a Map, where key=sobject[fieldName], value=list of matching sobjects
    */
    public static Map<Object, List<Object>> asGrouppedMap( List<Object> objects, String fieldName ){

        if ( BaseUtilities.isNullOrEmpty( objects ) ){
            return new Map<Object, List<Object>>();
        }


        Map<Object, List<Object>> resultMap = new Map<Object, List<Object>>();


        for ( Object objectItem : objects ){

            if ( objectItem == null ){
                continue; //skip
            }

            Map<String, Object> key2Value = 
                BaseUtilities.toPropertyMap( objectItem );

            if ( ! key2Value.containsKey( fieldName ) ){
                continue; //skip
            }


            Object valueKey = key2Value.get( fieldName );

            if ( ! resultMap.containsKey( valueKey ) ){
                
                resultMap.put( 
                    valueKey, 
                    new List<Object>{ objectItem } 
                );

            } else {

                resultMap.get( valueKey).add( objectItem );
            }  

        }

        return resultMap;

    }


    /**
    * Convert incoming set of string values to lower case
    */
    public static Set<String> toLowerCase(Set<String> originalValues) {
    	
    	Set<String> loweredCaseValues = new Set<String>();
    	
    	
    	for (String originalValue : originalValues) {
    		
    		loweredCaseValues.add(
    			originalValue == null
    			?
    				originalValue
    				:
    				originalValue.toLowerCase()
    		);
    		
    	}
    	
    	
    	return loweredCaseValues;
    	
    }
    
    
    
    /**
    * Convert incoming map to another one with lower-cased version of keys
    */
    public static Map<String, Object> toLowerCaseKey(Map<String, Object> keyToValue) {
    	
    	Map<String, Object> lowerCaseKeyToValue = keyToValue.clone();
    	lowerCaseKeyToValue.clear();
    	
    	
    	for (String key : keyToValue.keySet()) {
    		
    		lowerCaseKeyToValue.put(
    			(
    				BaseUtilities.isNullOrEmpty(key)
    				?
    					key
    					:
    					key.toLowerCase()
    			),
    			keyToValue.get(
    				key
    			)
    		);
    		
    	}
    	
    	
    	return lowerCaseKeyToValue;
    	
    }
	
	
	
	/**
	* Reverse incoming list
	*/
	public static List<Object> reverse(List<Object> originalObjects) {
		
		List<Object> reverseObjects = createListOfSameType(originalObjects);
		
		
		for (Integer i = originalObjects.size() - 1; i >= 0; i--) {
			
			reverseObjects.add(
				originalObjects[i]
			);
			
		}
		
		
		return reverseObjects;
		
	}
	
	
	
	/**
	* Create new list of the same type as incoming one - useful for building some generic solutions, e.g. reverse
	*/
	public static List<Object> createListOfSameType(List<Object> source) {
		
		List<Object> target = source.clone();
		
		target.clear();
		
		
		return target;
		
	}
	
	
	
	/**
	* Clone incoming list to new one with concrete type (if any), i.e. not generic sobject (useful for some tricky operations, e.g. upsert)
	*/
	public static List<SObject> cloneToConcreteType(List<SObject> source) {
		
		// early exit - empty source
		if (BaseUtilities.isNullOrEmpty(source)) {
			return source;
		}
		
		// get object type from the first element
		Schema.SObjectType concreteObjectType = source[0].getSObjectType();
        
        
        // early exit - cannot detect concrete object type in incoming collection
        if (concreteObjectType == null) {
        	return source;
        }
        
        
        String concreteListType = 'List<' + concreteObjectType + '>';
        List<SObject> concreteClone = (List<SObject>)Type.forName(concreteListType).newInstance();
        
        concreteClone.addAll(source);
        
        
        return concreteClone;
            
	}
	
	
	
	/**
	* Concat two incoming lists into single new one
	*/
	public static List<Object> concat(List<Object> operandOne, List<Object> operandTwo) {
		
		// clone first list
		List<Object> result = operandOne.clone();
		
		// copy all elements from the second one
		result.addAll(operandTwo);
		
		
		return result;
		
	}
	
	
	
    /**
    * Get specified number of items from the beginning of the source list
    */
    public static List<Object> limitTo(List<Object> source, Integer count) {
		
		return
			subList(
				source,
				0,
				count
			)
		;
		
    }
	
	
	
    /**
    * Extract sublist from incoming list: [start, ...) till the end of the list
    */
    public static List<Object> subList(List<Object> source, Integer start) {
    	
    	return
    		subList(
    			source,
    			start,
    			source.size()
    		)
    	;
    	
    }
	
	
	
    /**
    * Extract sublist from incoming list: [start, finish)
    */
    public static List<Object> subList(List<Object> source, Integer start, Integer finish) {
        
        List<Object> destination = createListOfSameType(source);
        
        if (BaseUtilities.isNullOrEmpty(source)) {
            return destination;
        }
        
        
        Integer actualStart = (start == null || start < 0 ? 0 : start);
        Integer actualFinish =  (finish == null || finish > source.size() ? source.size() : finish);
        
        
        if (actualStart > source.size() || actualFinish <= 0 || actualStart >= actualFinish) {
            return destination;
        }
        
        
        for (Integer i = actualStart; i < actualFinish; i++) {
            
            destination.add(
                source[i]
            );
            
        }
        
        
        return destination;
        
    }
	
	
	
	/**
	* Filter to records with change in provided field, e.g. when filtering in trigger context
	*/
	public static List<SObject> filterToChanged(List<SObject> newRecords, Map<Id, SObject> idToOldRecord, String fieldNameToCompare) {
		
		List<SObject> changedRecords = (List<SObject>)createListOfSameType(newRecords);
		
		
		for (SObject newRecord : newRecords) {
			
			// fetch old record
			SObject oldRecord = idToOldRecord.get(newRecord.Id);
			
			// move to the next one if old record is not found - just in case
			if (oldRecord == null) {
				continue;
			}
			
			
			// skip not changed records
			if (
				equals(
					newRecord.get(
						fieldNameToCompare
					), 
					oldRecord.get(
						fieldNameToCompare
					)
				)
			) {
				continue;
			}
			
			
			// collect changed records
			changedRecords.add(
				newRecord
			);
			
		}
		
		
		return changedRecords;
		
	}
	
	
	
	/**
	*  Find first element in incoming collection based on provided property = value
	*/
	public static Object findFirst(List<Object> incomingRecords, String property, Object value) {
		
		return
			BaseUtilities.getFirstIfAny(
				filterTo(
					incomingRecords,
					property,
					value,
					1
				)
			)
		;
		
	}
	
	
	
	/**
	* Filter incoming collection based on provided property = value
	*/
	public static List<Object> filterTo(List<Object> incomingRecords, String property, Object value) {
		
		return
			filterTo(
				incomingRecords,
				property,
				value,
				incomingRecords.size()
			)
		;
		
	}
	
	
	
	/**
	* Filter incoming collection based on provided property = value and limit results to specified number of records
	*/
	public static List<Object> filterTo(List<Object> incomingRecords, String property, Object value, Integer recordsLimit) {
		
		return
			filterTo(
				incomingRecords,
				new Map<String, Object> {
					property		=>		value
				},
				recordsLimit
			)
		;
		
	}
	
	
	
	/**
	* Find first element in incoming collection based on provided property having set of incoming values
	*/
	public static Object findFirst(List<Object> incomingRecords, String property, Set<String> values) {
		
		return
			BaseUtilities.getFirstIfAny(
				filterTo(
					incomingRecords,
					property,
					values,
					1
				)
			)
		;
		
	}
	
	
	
	/**
	* Filter incoming collections based on provided property having set of incoming values
	*/
	public static List<Object> filterTo(List<Object> incomingRecords, String property, Set<String> values) {
		
		return
			filterTo(
				incomingRecords,
				property,
				values,
				incomingRecords.size()
			)
		;
		
	}
	
	
	
	/**
	* Filter incoming collections based on provided property having set of incoming values and limit results to specified number of records
	*/
	public static List<Object> filterTo(List<Object> incomingRecords, String property, Set<String> values, Integer recordsLimit) {
		
		return
			filterTo(
				incomingRecords,
				new Map<String, Object> {
					property		=>		ConditionBuilder.inSet(values)
				},
				recordsLimit
			)
		;
		
	}
	
	
	
	/**
	* Find first element in incoming collection based on provided criteria (map = "logical and")
	*/
	public static Object findFirst(List<Object> incomingRecords, Map<String, Object> criterionToMatch) {
		
		return
			BaseUtilities.getFirstIfAny(
				filterTo(
					incomingRecords,
					criterionToMatch,
					1
				)
			)
		;	
		
	}
	
	
	
	/**
	* Filter incoming collection based on provided criteria: map = "logical and"
	*/
	public static List<Object> filterTo(List<Object> incomingRecords, Map<String, Object> criterionToMatch) {
		
		return
			filterTo(
				incomingRecords,
				criterionToMatch,
				incomingRecords.size()
			)
		;	
		
	}
	
	
	
	/**
	* Filter incoming collection based on provided criteria: map = "logical and" and limit results to specified number of records
	*/
	public static List<Object> filterTo(List<Object> incomingRecords, Map<String, Object> criterionToMatch, Integer recordsLimit) {
		
		return
			filterTo(
				incomingRecords,
				new List<Map<String, Object>> {
					criterionToMatch
				},
				recordsLimit
			)
		;
		
	}

	
	
	/**
	* Find first element in incoming collection based on provided criteria (map = "logical and", list = "logical or")
	*/
	public static Object findFirst(List<Object> incomingObjects, List<Map<String, Object>> criteriaToMatch) {
		
		return
			BaseUtilities.getFirstIfAny(
				filterTo(
					incomingObjects,
					criteriaToMatch,
					1
				)
			)
		;
		
	}
	
	
	
	/**
	* Filter incoming collection based on provided criteria (map = "logical and", list = "logical or")
	*/
	public static List<Object> filterTo(List<Object> incomingObjects, List<Map<String, Object>> criteriaToMatch) {
		
		return
			filterTo(
				incomingObjects,
				criteriaToMatch,
				incomingObjects.size()
			)
		;
		
	}
	
	
	
	/**
	* Filter incoming collection based on provided criteria (map = "logical and", list = "logical or") and limit results to specified number of records
	*/
	public static List<Object> filterTo(List<Object> incomingObjects, List<Map<String, Object>> criteriaToMatch, Integer recordsLimit) {
		
		List<Object> filteredObjects = createListOfSameType(incomingObjects);
		
		// convert incoming objects into list of property maps to be able to access properties in a dynamic way
		List<Object> incomingRecords = BaseUtilities.toPropertyList(incomingObjects);
		
		
		// loop through records
		for (
			Integer i = 0; 
			(
				// has not reached end of the collection yet
				i < incomingRecords.size() 
				&& 
				(
					// no limit restriction set
					recordsLimit == null
					||
					// has not found enough records to stop searching
					filteredObjects.size() < recordsLimit
				)
			);
			i++
		) {
			
			Map<String, Object> incomingRecord = (Map<String, Object>)incomingRecords[i];
			
			
			// loop through criteria - enough for one to match
			for (Map<String, Object> criterionToMatch : criteriaToMatch) {
			
				Boolean isMatch = true;
				
				
				// loop through criteria properties - all should match
				for (String criterionName : criterionToMatch.keySet()) {
					
					Object criterionValue = criterionToMatch.get(criterionName);
					
					// not match => move to next criterion
					if (
						!
						matchCriterion(
							incomingRecord, 
							criterionName,
							criterionValue
						)
					) {
						
						isMatch = false;
						
						break;
						
					}
					
				}
				
				
				// stop processing if found match with the whole criterion
				if (isMatch) {
					
					filteredObjects.add(
						incomingObjects[i]
					);
					
					break;
					
				}
				
			}
		
		}
		
		
		return filteredObjects;
		
	}
	
	
	
	// evaluate criterion
	private static Boolean matchCriterion(Map<String, Object> record, String criterionName, Object criterionValue) {
		
		// get actual value from record based on criterion name
		Object actualValue = getPropertyValueByPath(record, criterionName);
		
		
		// early exit - condition fails if value is not accessible, e.g. properties chain breaks at some stage
		if (actualValue == Value.NO_VALUE) {
			return false;
		}
		
		
		if (criterionValue instanceof ConditionInterface) {
			
			return
				(
					(ConditionInterface)criterionValue
				).match(
					actualValue
				)
			;
			
		} else {
			
			return
				actualValue == criterionValue
			;
			
		}
		
	}
	
    
    
    // get object property value by path, e.g. item.type.name
    private static Object getPropertyValueByPath(Map<String, Object> record, String propertyPath) {
    	
        Object propertyValue = record;
        
        
        // loop through property path
        for (String propertyPathSegment : propertyPath.split(BaseUtilities.DOT_REGEXP, -1)) {
	    	
	    	// can not continue moving along the chain since gap (i.e. null reference) has been discovered - no value
	    	if (propertyValue == null) {
	    		return Value.NO_VALUE;
	    	}
	    	
	    	
	    	Map<String, Object> intermediateRecord = (Map<String, Object>)propertyValue;
			
	    	// transform property name - strip collection index (if any) and prepend namespace
	    	String adaptedPropertyName = 
	    		PackageUtilities.addNamespacePrefixToObjectField(
	    			propertyPathSegment.substringBefore('[').trim()
	    		)
	    	;
	    	
	    	
	    	// early exit if property from provided path is not available - no value
	    	if (!intermediateRecord.containsKey(adaptedPropertyName)) {
	    		return Value.NO_VALUE;
	    	}
	    	
	    	
    		propertyValue = intermediateRecord.get(adaptedPropertyName);
    		
    		
    		// no way to do anything with null value - it's still valid value (but only if it's the last iteration)
    		if (propertyValue == null) {
    			continue;
    		}
    		
	    	
	    	// deal with arrays
	    	if (propertyValue instanceof List<Object>) {
	    		
	    		List<Object> intermediateArray = (List<Object>)propertyValue;
	    		
	    		
                // fetch collection index (if any), e.g. items[2].name => 2
                Integer propertyPathSegmentCollectionIndex =
                	parseElementIndexFromArrayNotation(
                        propertyPathSegment
                    )
                ;
                
                // whole collection should be treated as a value at this step, i.e. no need to fetch specific element
                if (propertyPathSegmentCollectionIndex == null) {
                
                	continue;
               
               
				// index is out of range - no value
                } else if (propertyPathSegmentCollectionIndex >= intermediateArray.size()) {
                	
                	return Value.NO_VALUE;
                	
                
                // extracting specific array element
                } else {
                    
                    propertyValue = 
                    	intermediateArray[
                    		propertyPathSegmentCollectionIndex
                    	]
                    ;
                
                }
	    		
	    	}
	    	
        }
        
        
        return propertyValue;
    	
    }
    
    
    
    // parse element index from array notation
    private static Integer parseElementIndexFromArrayNotation(String arrayNotationToken) {
    	
    	return
	        BaseUtilities.parseNumber(
	            BaseUtilities.extract(
	                arrayNotationToken,
	                ARRAY_NOTATION_INDEX_REGEX
	            )
	        )
		;
    	
    }
	
	
	
	// compare two values of ounknown type
	private static Boolean equals(Object operandOne, Object operandTwo) {
		
		if (
			operandOne instanceof String
			&&
			operandTwo instanceof String
		) {
			
			return 
				BaseUtilities.isEquivalent(
					String.valueOf(
						operandOne
					), 
					String.valueOf(
						operandTwo
					)
				)
			;
			
		}
		
		
		return operandOne == operandTwo;
		
	}


	
}