/**
* Helper class to hold object related utilities, e.g. dealing with fields etc.
*/
public with sharing class ObjectUtilities {
	

    public enum Permission {
        CREATE, EDIT, REMOVE
    }

    // id's related
    public static final String FIELD_NAME_ID = 'Id';
    
    public static final Integer SHORT_ID_LENGTH = 15;
    public static final Integer LONG_ID_LENGTH = 18;
    public static final String FIELD_NAME_DEVELOPER_NAME = 'DeveloperName';
    public static final String FIELD_NAME_NAMESPACE_PREFIX = 'NamespacePrefix';
    public static final String FIELD_TAB_NAME = 'TabName__c';
    public static final String FIELD_TYPE_NAME = 'Type__c';
    public static final String TAB_NAME = 'Tab';
	
	    
    public static final Set<String> FIELD_NAMES_TO_EXCLUDE_FROM_CLONING = 
    	new Set<String> {
    		SyncTransactionDao.OFFLINE_ID_FIELD_NAME
    	}
    ;
	
	
    private static final Set<Schema.DisplayType> STRING_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.base64,
        Schema.DisplayType.Email,
        Schema.DisplayType.MultiPicklist,
        Schema.DisplayType.Phone,
        Schema.DisplayType.Picklist,
        Schema.DisplayType.String,
        Schema.DisplayType.TextArea,
        Schema.DisplayType.URL
    };
    private static final Set<Schema.DisplayType> ID_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.ID,
        Schema.DisplayType.Reference
    };
    private static final Set<Schema.DisplayType> DOUBLE_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.Currency,
        Schema.DisplayType.Double,
        Schema.DisplayType.Percent
    };
    private static final Set<Schema.DisplayType> BOOLEAN_TYPES = new Set<Schema.DisplayType>{
        Schema.DisplayType.Boolean,
        Schema.DisplayType.Combobox
    };
    
    
    // system fields
    private static final Set<String> SYSTEM_FIELDS =
    	CollectionUtilities.toLowerCase(
	    	new Set<String> {
	    		'Id',
	    		'IsDeleted',
	    		'CreatedById',
	    		'CreatedDate',
	    		'LastModifiedById',
	    		'LastModifiedDate',
	    		'SystemModstamp'
	    	}
    	)
    ;


    private static Map<String, String> SOBJECT_NAME_2_NAME_FIELD = new Map<String, String>{
        'Event' => 'Subject',
        'Task' => 'Subject',
        'Idea' => 'Title',
        'Solution' => 'SolutionName',
        'Case' => 'CaseNumber',
        'OrderItem' => 'OrderItemNumber'
    };


    // cache
    private static Map<String, Schema.DescribeSObjectResult> objectNameToDescribeResult = new Map<String, Schema.DescribeSObjectResult>();
    
    private static Map<String, Boolean> objectNameToSelfReference = new Map<String, Boolean>();
    

    private static Map<String, Map<String, Schema.SObjectField>> sobjectName2FieldName2FieldToken =
        new Map<String, Map<String, Schema.SObjectField>>();

    /**
     * Searches for sObject names that do not contain substrings specified by filters. Case insensitive.
     * @param filters - list of string to sift out sObject names.
     * @return a set of filter sObject names.
     */
    public static Set<String> getFiltredSObjectsNames (List<String> filters){
        Set<String> result = new Set<String>();
        if(null == filters){
            filters = new List<String>();
        }
        List<Schema.SObjectType> allSObjectTypes = Schema.getGlobalDescribe().values();
        //optimized for(Schema.SObjectType sObjectType : allSObjectTypes)
        for (Integer i = 0, size = allSObjectTypes.size(); i < size; ++i) {
            String sObjectName = String.valueOf(allSObjectTypes[i]);
            Boolean isFiltered = false;
            //optimized for(String filter : filters)
            for (Integer j = 0, filtersSize = filters.size(); j < filtersSize; ++j) {
                if(null != filters[j] && sObjectName.containsIgnoreCase(filters[j])){
                    isFiltered = true;
                    break;
                }
            }
            if(!isFiltered){
                result.add(sObjectName);
            }
        }
        return result;
    }

    /**
     * Returns a map of field API name to its Schema.SObjectField for passed sObjectName.
     * @param sObjectName which fields have to be returned.
     * @return the map of sObject fields.
     */
    public static Map<String, Schema.SObjectField> getSObjectFieldsMap(String sObjectName){
        return getObjectDescribe(sObjectName).fields.getMap();
    }

    /**
    * Check whether incoming field set exists from provided SObject type (works with fully qualified and local names).
    */
    public static Boolean existFieldSet(Schema.DescribeSObjectResult objectDescribe, String fieldSetName) {
        
        return
            getObjectFieldSet(objectDescribe, fieldSetName) 
            <> 
            null
        ;
        
    }
    
    
    
    /**
    * Get fields for provided SObject type from field set identified by name.
    */
    public static List<Schema.FieldSetMember> getFieldsFromFieldSet(Schema.DescribeSObjectResult objectDescribe, String fieldSetName) {

        // early exist if field set doesn't exist        
        if (!existFieldSet(objectDescribe, fieldSetName)) {
            return new List<Schema.FieldSetMember>();
        }
        
        
        return
            getObjectFieldSet(
                objectDescribe, 
                fieldSetName
            ).getFields()
        ;
        
    }
    
    /**
    * Get fields for provided SObject type from field set identified by name.
    */
    public static List<Schema.FieldSetMember> getReadAllowedFieldsFromFieldSet(Schema.DescribeSObjectResult objectDescribe, String fieldSetName) {
        
        List<Schema.FieldSetMember> fieldSetMemberList = new List<Schema.FieldSetMember>();
        
        for (Schema.FieldSetMember fieldMember: 
            getFieldsFromFieldSet(
                objectDescribe, 
                fieldSetName
            )
        ) {
            
            if ( PermissionDao.isFieldReadAllowed(
                    UserInfo.getUserId(),
                    objectDescribe.getName(),
                    fieldMember.getFieldPath()
                )
                ==
                true
            ) {
                
                fieldSetMemberList.add(fieldMember);
            }
        }
        
        return fieldSetMemberList;
    
    }
    
    
    
    /**
    * Get object field by incoming name (works with fully qualified and local names).
    */
    public static Schema.FieldSet getObjectFieldSet(Schema.DescribeSObjectResult objectDescribe, String fieldSetName) {
    
        Map<String, Schema.FieldSet> fullyQualifiedNameToFieldSet = objectDescribe.fieldSets.getMap();
        
        
        // prepend namesapce to field set and search for it
        Schema.FieldSet fieldSet =
            fullyQualifiedNameToFieldSet.get(
                PackageUtilities.addNamespacePrefixToFieldSet(
                    fieldSetName
                )
            )
        ;
        
        // early exit: stop searching if found
        if (fieldSet <> null) {
            return fieldSet;
        }
        
        
        // search for field set by originally provided name and returns what has been found (since no more alternatives)
        return 
            fullyQualifiedNameToFieldSet.get(
                fieldSetName               
            )
        ;
    
    }
    
    
    
    /**
    * Map list of incoming field set members to field paths, i.e. format ready to be used in a dynamic SOQL query
    */
    public static List<String> mapFieldSetMembersToPaths(List<Schema.FieldSetMember> fieldSetMembers) {
        
        if (BaseUtilities.isNullOrEmpty(fieldSetMembers)) {
            return new List<String>();
        }
        
        
        List<String> fieldPaths = new List<String>();
        
        
        for (Schema.FieldSetMember fieldSetMember : fieldSetMembers) {
            
            fieldPaths.add(
                fieldSetMember.getFieldPath()
            );
            
        }
        
        
        return fieldPaths;
        
    }
    
    
    
    /**
    * Map list of incoming field set members to labels
    */
    public static List<String> mapFieldSetMembersToLabels(List<Schema.FieldSetMember> fieldSetMembers) {
        
        if (BaseUtilities.isNullOrEmpty(fieldSetMembers)) {
            return new List<String>();
        }
        
        
        List<String> fieldLabels = new List<String>();
        
        
        for (Schema.FieldSetMember fieldSetMember : fieldSetMembers) {
            
            fieldLabels.add(
                fieldSetMember.getLabel()
            );
            
        }
        
        
        return fieldLabels;
        
    }
    
    /**
    * Get record types of sobject.
    * @param sObjectName which record types have to be returned.
    * @return a map of record types ids to record types names.
    */
    public static Map<String, Id> getSObjectRecordTypes(String sObjectName) {
        Map<String, Id> result = new Map<String, Id>();
        List<Schema.RecordTypeInfo> recordTypes = getObjectDescribe(sObjectName).getRecordTypeInfos();
        Map<String, Object> recordTypesMap = CollectionUtilities.asMap(recordTypes, 'name', 'recordTypeId');

        for (String key : recordTypesMap.keySet()) {
            result.put(
                key,
                (Id)recordTypesMap.get(key)
            );
        }

        return result;
    }
    
    /**
    * Get record types of sobject.
    * @param sObjectName which record types have to be returned.
    * @return a List of record types.
    */
    public static List<RecordType> getSObjectRecordTypesList(String sObjectName) {

        try {
            return (List<RecordType>)DataLayer.queryAll([

                SELECT Id, Name, DeveloperName, IsPersonType, SObjectType, IsActive, NamespacePrefix
                FROM RecordType
                WHERE IsActive = TRUE AND SObjectType =: sObjectName

            ]);
        } catch(Exception ex) {
            throw BaseUtilities.getAuraHandledException(ex, 'ObjectUtilities.getSObjectRecordTypesList()');
        }

    }
    
    /**
    * Get name by incoming sobject instance
    */
    public static String getSobjectName(SObject record) {
        
        return 
            String.valueOf(
                record.getSObjectType()
            )
        ;
        
    }
    
    
    
    /**
    * Get name by incoming record id
    */
    public static String getSobjectName(String recordId) {
        
        return
            String.valueOf(
                Id.valueOf(
                    recordId
                ).getSObjectType()
            )
        ;
        
    }
    
    
    
    /**
    * Convert incoming object name to fully qualified one
    */
    public static String toFullyQualifiedObjectName(String objectName) {
        
        return
        
            String.valueOf(
            
                getObjectType(
                    objectName
                )
                
            )
            
        ;
        
    }
    
    
    
    /**
    * Convert incoming field name to fully qualified one
    */
    public static String toFullyQualifiedFieldName(String objectName, String fieldName) {
    	
    	return
    	
    		String.valueOf(
    		
    			getObjectField(
    			
    				getObjectDescribe(
                    	objectName
                	),
                	
                	fieldName
    			)
    			
    		)
    		
    	;	
    	
    }

    /**
     * @description Create new sobject instances by its type and set record ids
     * @param objectType - Sobject type
     * @param recordIds - set of the record ids
     * @return list of the new sobject instances
     */
    public static List<SObject> newSobjectInstances(SObjectType objectType, Set<Id> recordIds) {
        return newSobjectInstances(String.valueOf(objectType), recordIds);
    }

    /**
     * @description Create new sobject instances by name and set record ids
     * @param objectName - Sobject name
     * @param recordIds - set of the record ids
     * @return list of the new sobject instances
     */
    public static List<SObject> newSobjectInstances(String objectName, Set<Id> recordIds) {
        List<SObject> sobjects = new List<SObject>();
        for (Id recordId : recordIds) {
            sobjects.add(
                newSobjectInstance(objectName, recordId)
            );
        }
        return sobjects;
    }
    
    /**
    * Create new sobject instance by name and set provided fields values
    */
    public static SObject newSobjectInstance(String objectName, Map<String, Object> fieldToValue) {
    	
    	return
    		copyFields(
    			fieldToValue,
    			newSobjectInstance(
    				objectName
    			)
    		)
    	;
    	
    }
    
    
    
    /**
    * Create new empty sobject instance by name and set incoming id (optionally)
    */
    public static SObject newSobjectInstance(String objectName, Id recordId) {
        
        SObject record = 
            getObjectType(objectName).newSObject()
        ;
        

        // set id of the record        
        if (recordId <> null) {
            
            record.put(
                'Id', 
                recordId
            );
        
        }
        
        
        return record;
        
    }
    
    
    
    /**
    * Create new empty sobject instance by name
    */
    public static SObject newSobjectInstance(String objectName) {
        
        return 
            newSobjectInstance(
                objectName,
                (Id)null
            )
        ;
        
    }
    
    
    
    /**
    * Create new empty sobject instance by sobject
    */
    public static SObject newSobjectInstance(SObject source) {
        
        return 
            newSobjectInstance(
                String.valueOf(
                	source.getSObjectType()
                ),
                (Id)null
            )
        ;
        
    }

    /*
     * Set a list of children records to the parent Sobject field
     */
    public static SObject setSObjectChildren(SObject parent, String fieldName, List<SObject> children) {
        String serializedParent = JSON.serialize(parent);
        Map<String, Object> untypedParent = (Map<String, Object>) JSON.deserializeUntyped(serializedParent);

        untypedParent.put(
            fieldName,
            new Map<String, Object> {
                'records' => children
            }
        );

        return (SObject) JSON.deserialize(JSON.serialize(untypedParent), SObject.class);
    }
    
    
    
    /**
    * Create object of specified type and populated with provided values
    */
    public static Object toObject(Map<String, Object> fieldNameToValue, Type objectType) {
        
        return 
            JSON.deserialize(
                JSON.serialize(
                    fieldNameToValue
                ), 
                objectType
            )
        ;
        
    }
    
    
    
    /**
    * Get object name (fully qualified one) by record id
    */
    public static String toObjectName(Id recordId) {
    	
    	return
    		String.valueOf(
    			recordId.getSObjectType()
    		)
    	;
    	
    }
    
    
    
    /**
    * Convert incoming object to short version of id (just substring extraction, no actual parsing as id)
    */
    public static String asShortId(Object source) {
        
        return
            BaseUtilities.coalesce(
                String.valueOf(
                    source
                )
            )
            .left(SHORT_ID_LENGTH)
        ;
        
    }
    
    
    
    /**
    * Convert incoming object to record id.
    * Return null in case of failure (e.g. invalid format) instead of throwing exception.
    */
    public static Id toId(Object source) {
        
        String value = String.valueOf(source);
        
        
        if (String.isBlank(value)) {
            return null;
        }


        Id recordId = null;
        
        
        try {
            
            recordId = 
                Id.valueOf(
                    value.trim()
                )
            ;
            
        } catch (Exception exp) {
            
            // returned null would be an indicator of error
            
        }


        return recordId;
        
    }
    
    

    /**
    * Is not valid id
    */
    public static Boolean isNotId(Object value) {
        
        return
            !
            isId(value)
        ;
        
    }
    
    

    /**
    * Is valid id
    */
    public static Boolean isId(Object value) {
        
        return
            toId(value) <> null
        ;
        
    }
    
    
    
	/*
	* Check whether incoming id represents organization object
	*/
	public static Boolean isOrgId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			Organization.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents profile object
	*/
	public static Boolean isProfileId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			Profile.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents user object
	*/
	public static Boolean isUserId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			User.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents contact object
	*/
	public static Boolean isContactId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			Contact.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents account object
	*/
	public static Boolean isAccountId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			Account.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents organization wide email address object
	*/
	public static Boolean isOrgWideEmailAddressId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			OrgWideEmailAddress.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents attachment object
	*/
	public static Boolean isAttachmentId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			Attachment.SObjectType
		;
		
	}
	
	
	
	/*
	* Check whether incoming id represents content version object
	*/
	public static Boolean isContentVersionId(Object sourceId) {
		
		return 
			Id.valueOf(
				String.valueOf(
					sourceId
				)
			).getSObjectType() 
			== 
			ContentVersion.SObjectType
		;
		
	}
    
    
    
    /**
    * Check whether incoming object exists
    */
    public static Boolean isObject(String objectName) {
        
        return
            getObjectType(objectName) <> null
        ;
        
    }
    
    

    /**
    * Check whether incoming field exists for provided object name, e.g. isField('Account', 'Name')
    */
    public static Boolean isField(String objectName, String fieldName) {
        
        return
            isObject(objectName)
            &&
            isField(
                getObjectDescribe(objectName),
                fieldName
            )
        ;
        
    }
    
    

    /**
    * Check whether incoming field exists for provided object type, e.g. isField(Schema.SobjectType.Account, 'Name')
    */
    public static Boolean isField(Schema.DescribeSObjectResult objectDescribe, String fieldName) {
        
        return
            objectDescribe <> null
            &&
            (
                getFieldDescribe(
                    objectDescribe, 
                    fieldName
                ) 
                <> 
                null
            )
        ;
        
    }
    

    
    /**
    * Check whether provided field path segment referes to field on incoming sobject
    */
    public static Boolean isField(SObject source, String fieldPathSegment) {
        if(source == null){
            return false;
        }
        
        return
            isField(
                source.getSObjectType().getDescribe(),
                fieldPathSegment.trim()
            )
        ;
        
    }
    
    
    
    /**
    * Check whether incoming field is a system one
    */
    public static Boolean isSystemField(String fieldName) {
    	
    	return
    		SYSTEM_FIELDS.contains(
    			fieldName.toLowerCase().trim()
    		)
    	;
    	
    }
    
    
    
    /**
    * Convert incoming value to type compatible with provided field (to be able to populated the field with returned value)
    */
    public static Object convertValueToFieldType(String objectName, String fieldName, Object originalValue) {
        
        String stringifiedOriginalValue = String.valueOf(originalValue);
        
        
        // id
        if (isIdField(objectName, fieldName)) {
            
            return
                originalValue instanceof Id
                ?
                    originalValue
                    :
                    Id.valueOf(
                        stringifiedOriginalValue
                    )
            ;
            
        
        // decimal
        } else if (isDecimalField(objectName, fieldName)) {
                        
            return
                originalValue instanceof Decimal
                ?
                    originalValue
                    :
                    Decimal.valueOf(
                        stringifiedOriginalValue
                    )
            ;
        
            
        // integer
        } else if (isIntegerField(objectName, fieldName)) {
                        
            return
                originalValue instanceof Integer
                ?
                    originalValue
                    :
                    Integer.valueOf(
                        stringifiedOriginalValue
                    )
            ;
            
        
        // boolean
        } else if (isBooleanField(objectName, fieldName)) {
            
            return
                originalValue instanceof Boolean
                ?
                    originalValue
                    :
                    Boolean.valueOf(
                        stringifiedOriginalValue
                    )
            ;
        
        
        // date
        } else if (isDateField(objectName, fieldName)) {
            
            return
                originalValue instanceof Date
                ?
                    originalValue
                    :
                    Date.valueOf(
                        stringifiedOriginalValue
                    )
            ;
            

        // date time            
        } else if (isDateTimeField(objectName, fieldName)) {
            
            return
                originalValue instanceof DateTime
                ?
                    originalValue
                    :
                    DateTime.valueOfGmt(
                        normalizeDateTime(
                            stringifiedOriginalValue
                        )
                    )
            ;
            
        
        // blob
        } else if (isBlobField(objectName, fieldName)) {
            
            return
                originalValue instanceof Blob
                ?
                    originalValue
                    :
                    Blob.valueOf(
                        stringifiedOriginalValue
                    )
            ;
            
            
        // looks like it doesn't require special conversion, e.g. some text            
        } else {
            
            return originalValue;
            
        }
        
    }
    
    
    
    /**
    * Check whether incoming field name is id
    */
    public static Boolean isIdFieldName(String fieldName) {
        
        return
            BaseUtilities.isEquivalent(
                FIELD_NAME_ID,
                fieldName
            )
        ;
        
    }
    
    
    
    /**
    * Check whether incoming field name is not id
    */
    public static Boolean isNotIdFieldName(String fieldName) {
        
        return
            !
            isIdFieldName(
                fieldName
            )
        ;
        
    }
    
    
    
    /**
    * Check whether incoming field is not permissionalbe
    */
    public static Boolean isNotPermissionableField(String objectName, String fieldName) {
        
        return
            !
            isPermissionableField(
                objectName,
                fieldName
            )
        ;
        
    }
    
    
    
    /**
    * Check whether incoming field is permissionalbe
    */
    public static Boolean isPermissionableField(String objectName, String fieldName) {
        
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        
        // early exit if field not found
        if (fieldDescribe == null) {
            return false;
        }
        
        
        return fieldDescribe.isPermissionable();
        
    }
    
    
    
    /**
    * Check whether incoming field is createable but not updateable
    */
    public static Boolean isCreateableButNotUpdateableField(String objectName, String fieldName) {
        
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        
        // early exit if field not found
        if (fieldDescribe == null) {
            return false;
        }
        
        
        return 
            fieldDescribe.isCreateable()
            &&
            !
            fieldDescribe.isUpdateable()
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is id
    */
    public static Boolean isIdField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                Schema.DisplayType.Id
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is decimal
    */
    public static Boolean isDecimalField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                new Set<Schema.DisplayType> {
                    Schema.DisplayType.Currency,
                    Schema.DisplayType.Double,
                    Schema.DisplayType.Percent
                }
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is integer
    */
    public static Boolean isIntegerField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                new Set<Schema.DisplayType> {
                    Schema.DisplayType.Integer
                }
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is boolean
    */
    public static Boolean isBooleanField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                Schema.DisplayType.Boolean
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is a date
    */
    public static Boolean isDateField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                Schema.DisplayType.Date
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is a date time
    */
    public static Boolean isDateTimeField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                Schema.DisplayType.DateTime
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field is a reference, i.e. lookup or master-detail relationship
    */
    public static Boolean isReferenceField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                Schema.DisplayType.Reference
            )
        ;
        
    }


    /**
    * Check whether provided field is a reference, i.e. lookup or master-detail relationship
    */
    public static Boolean isReferenceField(DescribeFieldResult describe) {

        return
            describe.getType()
            ==
            Schema.DisplayType.Reference
        ;

    }

    
    /**
    * Check whether provided field is a blob field, i.e. represents large base64-encoded chunk of data, e.g. Attachment.Body
    */
    public static Boolean isBlobField(String objectName, String fieldName) {
        
        return
            isFieldOfType(
                objectName,
                fieldName,
                Schema.DisplayType.base64
            )
        ;
        
    }
    
    
    
    /**
    * Check whether provided field has an expected field type
    */
    public static Boolean isFieldOfType(String objectName, String fieldName, Schema.DisplayType expectedFieldType) {
        
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        
        // early exit if field not found
        if (fieldDescribe == null) {
            return false;
        }
        
        
        return
            fieldDescribe.getType()
            ==
            expectedFieldType
        ;
        
    }
    
    
    
    /**
    * Check whether provided field has one of the expected field types
    */
    public static Boolean isFieldOfType(String objectName, String fieldName, Set<Schema.DisplayType> expectedFieldTypes) {
        
        Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(objectName, fieldName);
        
        // early exit if field not found
        if (fieldDescribe == null) {
            return false;
        }
        
        
        for (Schema.DisplayType expectedFieldType : expectedFieldTypes) {
            
            if (fieldDescribe.getType() == expectedFieldType) {
                
                return true;
                
            }
            
        }
        
        
        return false;
        
    }
    
    
    
    /**
    * Get field label (works with fully qualified and local names).
    */
    public static String getFieldLabel(String objectName, String fieldName) {
        
        Schema.DescribeFieldResult fieldDescribe =
            getFieldDescribe(
                objectName, 
                fieldName
            )
        ;
        
        
        return
            fieldDescribe == null
            ?
                null
                :
                fieldDescribe.getLabel()
        ;
        
    }
    
    
    
    /**
    * Get field label (works with fully qualified and local names).
    * If some field is not found, null is returned on appropriate position in outcoming collection.
    */
    public static List<String> getFieldsLabels(String objectName, List<String> fieldNames) {
        
        List<String> fieldsLabels = new List<String>();
        
        
        for (String fieldName : fieldNames) {
            
            fieldsLabels.add(
                getFieldLabel(
                    objectName,
                    fieldName
                )
            );
            
        }
        
        
        return fieldsLabels;
        
    }
    
    
    
    /**
    * Get field describe (works with fully qualified and local names).
    */
    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
        
        Schema.DescribeSObjectResult objectDescribe = getObjectDescribe(objectName);
        
        
        if (objectDescribe == null) {
            return null;
        }
        
        
        return getFieldDescribe(objectDescribe, fieldName);
        
    }
    
    
    
    /**
    * Get field describe (works with fully qualified and local names).
    */
    public static Schema.DescribeFieldResult getFieldDescribe(Schema.DescribeSObjectResult objectDescribe, String fieldName) {
                
        Schema.SObjectField objectField = getObjectField(objectDescribe, fieldName);
        
        
        return
            objectField == null
            ?
                null
                :
                objectField.getDescribe()
        ;
        
    }
    
    
    
    /**
    * Get object field by incoming name (works with fully qualified and local names).
    */
    public static Schema.SObjectField getObjectField(Schema.DescribeSObjectResult objectDescribe, String fieldName) {
    
        Map<String, Schema.SObjectField> fullyQualifiedNameToField = objectDescribe.fields.getMap();
        
        
        // prepend namesapce to field name and search for it
        Schema.SObjectField fieldType =
            fullyQualifiedNameToField.get(
                PackageUtilities.addNamespacePrefixToObjectField(
                    fieldName
                )
            )
        ;
        
        // early exit: stop searching if found
        if (fieldType <> null) {
            return fieldType;
        }
        
        
        // search for field by originally provided name and returns what has been found (since no more alternatives)
        return 
            fullyQualifiedNameToField.get(
                fieldName                
            )
        ;
    
    }



    /**
    * Get object fields by incoming name (works with fully qualified and local names).
    */
    public static List<Schema.SobjectField> getObjectFieldsByFieldNames(
        Schema.DescribeSObjectResult sobjectDescribe,
        List<String> fieldNames
    ){

        List<Schema.SobjectField> fieldTypes = new List<Schema.SobjectField>();

        Map<String, Schema.SObjectField> fullyQualifiedNameToField = sobjectDescribe.fields.getMap();


        for ( String fieldName : fieldNames ){

            // prepend namespace to field name and search for it
            Schema.SObjectField fieldType =
                fullyQualifiedNameToField.get(
                    PackageUtilities.addNamespacePrefixToObjectField(
                        fieldName
                    )
                )
            ;


            // stop searching if found
            if (fieldType <> null) {

                fieldTypes.add( fieldType );

                // add to list and proceed with next iteration.
                continue;

            }


            // search for field by originally provided name and returns what has been found (since no more alternatives)
            fieldType =
                fullyQualifiedNameToField.get(
                    fieldName
                )
            ;


            // ignore non-existing field names
            if (fieldType <> null) {
                fieldTypes.add( fieldType );
            }

        }


        return fieldTypes;

    }

    
    
    /**
    * Get describes for sortable fields of incoming object (works with fully qualified and local names).
       */
       public static List<Schema.DescribeFieldResult> getObjectSortableFieldsDescribes(String objectName) {
        
        List<Schema.DescribeFieldResult> sortableFieldDescribes = new List<Schema.DescribeFieldResult>();
        
        
        for (Schema.DescribeFieldResult fieldDescribe : getObjectFieldsDescribes(objectName)) {
            
            if (fieldDescribe.isSortable()) {
                
                sortableFieldDescribes.add(
                    fieldDescribe
                );
                
            }
            
        }
        
        
        return sortableFieldDescribes;
           
       }
    
    public static Set<String> getObjectFieldNames(String objectName) {
        Set<String> fieldNames = new Set<String>();

        Schema.DescribeSObjectResult objectDescribe = getObjectDescribe(objectName);
        
        if (objectDescribe == null) {
            return fieldNames;
        }

        for (Schema.SObjectField objectField : objectDescribe.fields.getMap().values()) {
            
            fieldNames.add(
                objectField.getDescribe().getLocalName()
            );
            
        }

        return fieldNames;
    }
    
    /**
    * Get describes for all fields of incoming object (works with fully qualified and local names).
       */
       public static List<Schema.DescribeFieldResult> getObjectFieldsDescribes(String objectName) {
        
        List<Schema.DescribeFieldResult> fieldDescribes = new List<Schema.DescribeFieldResult>();
        
        
        Schema.DescribeSObjectResult objectDescribe = getObjectDescribe(objectName);
        
        if (objectDescribe == null) {
            return fieldDescribes;
        }
        
        
        for (Schema.SObjectField objectField : objectDescribe.fields.getMap().values()) {
            
            fieldDescribes.add(
                objectField.getDescribe()
            );
            
        }
        
        
        return fieldDescribes;
           
       }


        /**
        * getLookupFieldNamePath (String fieldPath)
        * Returns a fieldPath for a relationship (e.g. for AccountId - will return Account.Name)
        * Takes into account Sobjects like Case, Event etc which have no 'Name' field.
        */
        public static String getRelationshipFieldNamePath( String sobjectName, String fieldName ) {

            return
                getRelationshipFieldNamePath(
                    getObjectField(
                        getObjectDescribe( sobjectName ),
                        fieldName
                    )
                )
            ;

        }


        /**
        * getLookupFieldNamePath (String fieldPath)
        * Returns a fieldPath for a relationship (e.g. for AccountId - will return Account.Name)
        * Takes into account Sobjects like Case, Event etc which have no 'Name' field.
        */
        public static String getRelationshipFieldNamePath(Schema.SobjectField fieldToken) {
            return
                getRelationshipFieldNamePath(
                    fieldToken.getDescribe()
                )
            ;
        }


        /**
        * getLookupFieldNamePath (String fieldPath)
        * Returns a fieldPath for a relationship (e.g. for AccountId - will return Account.Name)
        * Takes into account Sobjects like Case, Event etc which have no 'Name' field.
        */
        public static String getRelationshipFieldNamePath(Schema.DescribeFieldResult fieldDescribe) {

            //Contact__c => 'Contact__r', ContactId => 'Contact'
            String rlpName = fieldDescribe.relationshipName;


            //Contact.AccountId => Account (Schema)
            Schema.SObjectType referenceTo = fieldDescribe.referenceTo.get(0);


            //compound result
            String result =
                rlpName
                +
                '.'
                +
                getObjectNameField( String.valueOf( referenceTo ) ).getName()
            ;

            return result;

        }


        /**
        * Get object 'name' field, e.g. 'Account' -> 'Account.Name', 'Case' -> 'Case.Subject' etc.
        * Used as a helper to 'getObjectNameField' method to avoid unnecessary describe requests.
        */
        public static String getSobjectNameField(String sobjectName) {

            if ( sobjectName.endsWith('__c') ){

                return 'Name';

            } else if ( sobjectName.endsWith('__mdt') ){

                return 'DeveloperName';

            } else if ( sobjectName.endsWith('Status') ){

                return 'ApiName';

            } else if ( SOBJECT_NAME_2_NAME_FIELD.containsKey( sobjectName ) ){

                return SOBJECT_NAME_2_NAME_FIELD.get( sobjectName );

            } else if ( isField( sobjectName, 'Name' ) ){

                return 'Name';

            }

            //no named field found - highly unlikely
            return
                ObjectUtilities.getObjectNameField(
                    sobjectName
                )
                .getName()
            ;

        }


       /**
       * Get object 'name' field, i.e. the one which is used as text representation of a record (Name in most cases)
       */
       public static Schema.DescribeFieldResult getObjectNameField(String objectName) {
           
           List<Schema.DescribeFieldResult> fieldsDescribes =  getObjectFieldsDescribes(objectName);
           
           // early exit - can not get fields for provided object name
           if (BaseUtilities.isNullOrEmpty(fieldsDescribes)) {
               return null;
           }
           
           
           // loop through fields and find first named one
           for (Schema.DescribeFieldResult describeFieldResult : fieldsDescribes) {
               
               if (describeFieldResult.isNameField()) {
                   
                   return describeFieldResult;
                   
               }
               
           }
           
           
           // no named field found - highly unlikely
           return null;
           
       }

    /**
     * Gets Labels for Object .
     * @param        String sObjectType
     * @return       Map<String, String>
     */
    public static Map<String, String> geFieldNameLabelMap(String objectName) {
        List<Schema.DescribeFieldResult> fields = getObjectFieldsDescribes(objectName);

        return CollectionUtilities.asStringMap(fields, 'localName', 'label');
    }

    /**
     * Gets Labels for Object .
     * @param        String sObjectType
     * @return       Map<String, String>
     */
    public static Map<String, String> geFieldLabelNameMap(String objectName) {
        List<Schema.DescribeFieldResult> fields = getObjectFieldsDescribes(objectName);

        return CollectionUtilities.asStringMap(fields, 'label', 'localName');
    }
       
    public static List<String> getActivePicklistValues(String objectName, String fieldName) {
        return
            BaseUtilities.mapModelsToStrings(
                getActivePicklistEntries(objectName, fieldName),
                'value'
            );
    }
       
    /**
    * Get active picklist entries
    */
    public static List<Schema.PicklistEntry> getActivePicklistEntries(String objectName, String fieldName) {
        
        List<Schema.PicklistEntry> activePicklistEntries = new List<Schema.PicklistEntry>();
        
        
        for (Schema.PicklistEntry picklistEntry : getPicklistEntries(objectName, fieldName)) {

            // filter to active entries         
            if (picklistEntry.isActive() == true) {
                
                activePicklistEntries.add(
                    picklistEntry
                );  
                
            }
            
        }
        
        
        return activePicklistEntries;
        
    }
       
       
       
    /**
    * Get picklist entries
    */
    public static List<Schema.PicklistEntry> getPicklistEntries(String objectName, String fieldName) {
        
        return
            getFieldDescribe(
                objectName, 
                fieldName
            ).getPicklistValues()
        ;
        
    }
    
    
    /**
    * Get default picklist entry
    */
    public static Schema.PicklistEntry getDefaultPicklistEntry( Schema.SObjectField fieldToken ) {

        return getDefaultPicklistEntry(fieldToken.getDescribe());

    }


    /**
    * Get default picklist entry
    */
    public static Schema.PicklistEntry getDefaultPicklistEntry( Schema.DescribeFieldResult picklistFieldDescribe ) {
        
        return getDefaultPicklistEntry(picklistFieldDescribe.getPicklistValues());
        
    }

    
    /**
    * Get default picklist entry
    */
    public static Schema.PicklistEntry getDefaultPicklistEntry( List<Schema.PicklistEntry> picklistValues ) {
        
        List<Schema.PicklistEntry> activePicklistValues = new List<Schema.PicklistEntry>();
        
        
        for (Schema.PicklistEntry picklistEntry : picklistValues ) {

            //return default value
            if ( picklistEntry.isDefaultValue() ){
                
                return picklistEntry;
            }
                
            // filter to active entries
            if ( picklistEntry.isActive() ){

                activePicklistValues.add( picklistEntry );
            }

        }
        

        return 
            activePicklistValues.isEmpty()            
            ?
                null
                :
                //return first in a list as default value
                activePicklistValues.get(0);
        
    }
    
    
    
    /**
    * Determine whehter object has a self reference, e.g. may refer to object of the same type via one of its fields
    */
    public static Boolean hasObjectSelfReference(String objectName) {
    	
    	String normalizedObjectName = objectName.trim().toLowerCase();
    	
    	
    	// try to resolve from cache first
    	if (objectNameToSelfReference.containsKey(normalizedObjectName)) {
    		
    		return 
    			objectNameToSelfReference.get(
    				normalizedObjectName
    			)
    		;
    		
    	}
    	
    	
    	Schema.DescribeSObjectResult objectDescribe = getObjectDescribe(normalizedObjectName);
    	
		Schema.SObjectType objectType = objectDescribe.getSObjectType();
		
		
		Boolean hasSelfReference = false;
		
		
		// loop through child relationships for current object to check whether there is a 'self-reference' back
		for (Schema.ChildRelationship childRel : objectDescribe.getChildRelationships()) {
			
			if (childRel.getChildSObject() == objectType) {
				
				hasSelfReference = true;
				
				break;
				
			}
			
		}
		
		
		// put into cache for further hits
		objectNameToSelfReference.put(
			normalizedObjectName,
			hasSelfReference
		);
		
		
		return hasSelfReference;
    	
    }
	
	
    
    /**
    * Get object describe by incoming name (works with fully qualified and local names).
    */
    public static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
        
        // check cache first
        Schema.DescribeSObjectResult describeResult = objectNameToDescribeResult.get(objectName);
        
        if (describeResult <> null) {
            return describeResult;
        }
        
        
        Schema.SObjectType objectType = getObjectType(objectName);
        
        
        if (objectType <> null) {
            
            describeResult = objectType.getDescribe();
            
            objectNameToDescribeResult.put(
                objectName,
                describeResult
            );
            
        }
        
        
        return describeResult;
        
    }
    
    
    
    /**
    * Get object describe by incoming type
    */
    public static Schema.DescribeSObjectResult getObjectDescribe(SObjectType objectType) {
        
        return
        	getObjectDescribe(
        		String.valueOf(
        			objectType
        		)
        	)
        ;
        
    }
    
    
    
    /**
    * Get object type by incoming name (works with fully qualified and local names).
    */
    public static Schema.SObjectType getObjectType(String objectName) {
        
        String normalizedObjectName = objectName.toLowerCase();
        
        Map<String, Schema.SObjectType> fullyQualifiedNameToObject = Schema.getGlobalDescribe();
        
        
        // prepend namesapce to object name and search for it
        Schema.SObjectType objectType =
            fullyQualifiedNameToObject.get(
                PackageUtilities.addNamespacePrefixToObjectField(
                    normalizedObjectName
                )
            )
        ;
        
        // early exit: stop searching if found
        if (objectType <> null) {
            return objectType;
        }
        
        
        // search for object by originally provided name and returns what has been found (since no more alternatives)
        return 
            fullyQualifiedNameToObject.get(
                normalizedObjectName
            )
        ;
        
    }
    
    
    
    /**
    * Check whether incoming object type has relationship with provided name
    */
    public static Boolean doesObjectHaveRelationship(SObjectType objectType, String relationshipName) {
    	
    	return
    		getChildRelationshipsIndexedByName(
    			objectType
    		).containsKey(
    			relationshipName
    		)
    	;
    	
    }
    
    
    
	/**
	* Get child relationships indexed by fully qualified name
	*/
	public static Map<String, Schema.ChildRelationship> getChildRelationshipsIndexedByName(SObjectType objectType) {
		
		Map<String, Schema.ChildRelationship> nameToRelationship = new Map<String, Schema.ChildRelationship>();
		
		
		for (Schema.ChildRelationship childRelationship : getObjectDescribe(objectType).getChildRelationships()) {
			
			nameToRelationship.put(
				childRelationship.getRelationshipName(),
				childRelationship
			);
			
		}
		
		
		return nameToRelationship;
		
	}
    
    
    
    /**
    * Wipe describe results cache
    */
    public static void wipeObjectDescribeResultCache() {
        
        objectNameToDescribeResult.clear();
        
    }
    

    /**
     * Return fieldName by relationship 
     */
    public static String getFieldNameByRelationship (String fieldName) {
        return ( fieldName.endsWithIgnoreCase('__r') ) ? fieldName.removeEndIgnoreCase('__r') + '__c' : fieldName + 'Id';
    }
    
    
    /**
    * Check whether provided field path segment referes to children collections of incoming sobject
    */
    public static Boolean isChildrenCollections(SObject source, String fieldPathSegment) {
        if(source == null){
            return false;
        }
        for (Schema.ChildRelationship childRelationship : source.getSObjectType().getDescribe().getChildRelationships()) {
            
            if (
                BaseUtilities.isEquivalent(
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
    * Get fields from sobjects
    */
    public static Set<String> getFieldsFromSobject(Sobject obj) {
        
        if (obj == null) return new Set<String>();
        
        Set<String> fields = ((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj))).keySet();
        
        fields.remove('attributes');
        
        Set<String> result = new Set<String>(fields);
        
        // remove related sobjects
        for (String field: fields) {
            
            if (doesObjectHaveRelationship(obj.getSobjectType(), field)) {
                
                result.remove(field);
            
            }
        
        }
        
        if (result.contains('RecordType')) {
            
            result.remove('RecordType');
        }
        
        return result;
    }
    
    /**
    * Get read allowed fields from sobjects
    */
    public static Set<String> getReadAllowedFieldsFromSobject(Sobject obj) {
        
        Set<String> result = new Set<String>();
        
        for (String field: getFieldsFromSobject(obj)) {
            
            if (
                PermissionDao.isFieldReadAllowed(
                    UserInfo.getUserId(), 
                    String.valueOf( obj.getSobjectType() ), 
                    field
                )
            ) {
                
                result.add(field);
            }
        
        }
        
        return result;

    }
    
    
    
    /**
    * Get sobject field value by field path
    */
    public static Object getValueByFieldPath(SObject actualObject, String fieldPath) {
                
        SObject intermediateRecord = actualObject;
        Object value = null;
        
        String[] fieldPathSegments = 
            fieldPath.split(
                BaseUtilities.DOT_REGEXP,
                -1
            )
        ;
        
        
        for (Integer i = 0; i < fieldPathSegments.size(); i++) {
            
            String fieldPathSegmentWithoutCollectionIndex = fieldPathSegments[i].substringBefore('[').trim();
            
            
            // field path segment just refers to field name
            if (isField(intermediateRecord, fieldPathSegmentWithoutCollectionIndex)) {
                
                // fetch value directly from intermediate record based on field name
                value = 
                    intermediateRecord.get(
                        fieldPathSegmentWithoutCollectionIndex
                    )
                ;
                
                
                // if field token is present, it should be the last in field path
                break;
                
            
            // field path segment refers to children collections (with optional index) and it also could be the last segment in field path 
            } else if (isChildrenCollections(intermediateRecord, fieldPathSegmentWithoutCollectionIndex)) {
                
                SObject[] childrenCollections =
                    intermediateRecord.getSObjects(
                        fieldPathSegmentWithoutCollectionIndex
                    )
                ;
                
                // fetch collection index (if any), e.g. Contacts[2].Name => 2
                String fieldPathSegmentCollectionIndexRaw =
                    BaseUtilities.extract(
                        fieldPathSegments[i],
                        '\\[\\s*(\\d+)\\s*\\]'
                    )
                ;
                
                
                   Integer fieldPathSegmentCollectionIndex =
                    BaseUtilities.parseNumber(
                        fieldPathSegmentCollectionIndexRaw
                    )
                ;
                
                
                // just one element of collections should be considered
                if (fieldPathSegmentCollectionIndex <> null) {
                        
                    intermediateRecord =
                        intermediateRecord.getSObjects(
                            fieldPathSegmentWithoutCollectionIndex
                        )
                        [
                            fieldPathSegmentCollectionIndex
                        ]
                    ;
                    
                    
                    value = (Object)intermediateRecord;
                    
                
                // all collection should be considered    
                } else {
                    
                    value = (Object)childrenCollections;
                    
                    // if all collection is considered, it should be the last token in field path
                    break;
                    
                }
                
                
            // suppose that field path segment refers to parent record    
            } else if(intermediateRecord != null) {              
                intermediateRecord = 
                    intermediateRecord.getSObject(
                        fieldPathSegmentWithoutCollectionIndex
                    )
                ;
                
                
                value = (Object)intermediateRecord;
                
            }
            
        }
        
        
        return value;
        
    }
    
    /*
    * define if dispalyType is boolean
    */    
    public static Boolean isBoolean( Schema.DisplayType dispalyType ){
        return BOOLEAN_TYPES.contains( dispalyType );
    }    

    /*
    * define if dispalyType is numeric type (any number)
    */  
    public static Boolean isNumeric( Schema.DisplayType dispalyType ){
        return DOUBLE_TYPES.contains( dispalyType )
            || dispalyType == Schema.DisplayType.Integer;
    }

    /*
    * define if dispalyType is Date type
    */  
    public static Boolean isDate( Schema.DisplayType dispalyType ){
        return dispalyType == Schema.DisplayType.Date;
    }

    /*
    * define if dispalyType is Date/Time type
    */ 
    public static Boolean isDateTime( Schema.DisplayType dispalyType ){
        return dispalyType == Schema.DisplayType.DateTime;
    }

    /*
    * define if dispalyType is text type (any string placed between "", except Blob)
    */ 
    public static Boolean isString( Schema.DisplayType dispalyType ){
        return STRING_TYPES.contains( dispalyType )
            ||  ID_TYPES.contains( dispalyType );
    }
    
    
    // normalize date time, e.g.
    //    from:    2014-11-20T14:23:44.000+0000
    //    to:        2014-11-20 14:23:44    
    public static String normalizeDateTime(String stringifiedDateTime) {
        
        return 
            stringifiedDateTime
                .substringBefore(
                    BaseUtilities.DOT
                )
                .replaceAll(
                    BaseUtilities.CASE_INSENSITIVE_REGEXP_OPTION_ON + 't', 
                    BaseUtilities.SPACE
                )
        ;
        
    }
	
	
	
    /**
    * Copy incoming set of fields from source object into empty clone
    */
    public static SObject copyFields(SObject source, List<Schema.SObjectField> fieldsToCopy) {
    	
    	return
    		copyFields(
    			source,
    			newSobjectInstance(source),
    			fieldsToCopy
    		)
    	;
    	
    }
	
	
	
    /**
    * Copy incoming set of fields from one object (source) to another (destination)
    */
    public static SObject copyFields(SObject source, SObject destination, List<Schema.SObjectField> fieldsToCopy) {
		
		// loop through fields and copy one by one applying some reasonable type conversion
		for (Schema.SObjectField fieldToCopy : fieldsToCopy) {
			
			// get source field value
			Object value = source.get(fieldToCopy);
			
			
			// convert double with scale 0 to integer
			{
				
				Schema.DescribeFieldResult fieldDescribe = fieldToCopy.getDescribe();
				
				
				if (
					fieldDescribe.getType() == Schema.DisplayType.Double
					&&
					fieldDescribe.getScale() == 0
				) {
					
					value = Integer.valueOf(value);
					
				}
				
			}
						
			
			// copy field value to destination
			destination.put(
	            String.valueOf(
	            	fieldToCopy
	            ),
	            value
			);
			
		}
			
		
   		return destination;
    	
    }
    
    
    
    /**
    * Copy incoming set of fields and values (source) to another object (destination)
    */
	public static SObject copyFields(Map<String, Object> fieldToValue, SObject destination) {
		
		for (String fieldName : fieldToValue.keySet()) {
			
			destination.put(
				fieldName,
				fieldToValue.get(fieldName)
			);
			
		}
		
		
		return destination;
		
	}
    
    
    
    /**
    * Copy incoming set of fields and values (source) to another object (destination) filtering to custom only in advance
    */
	public static SObject copyCustomFields(Map<String, Object> fieldToValue, SObject destination) {
		
		for (String fieldName : fieldToValue.keySet()) {
			
			if (PackageUtilities.isCustomObjectField(fieldName)) {
				
				destination.put(
					fieldName,
					fieldToValue.get(fieldName)
				);
				
			}
			
		}
		
		
		return destination;
		
	}
    
    
    
    /**
    * Clone incoming sobject excluding some fields along the way
    */
    public static SObject clone(SObject original) {
    
    	return clone(original, false, false, false, false);
    	
    }
    
    
    
    /**
    * Clone incoming sobject excluding some fields along the way
    */
    public static SObject clone(SObject original, Boolean preserveId) {
    
    	return clone(original, preserveId, false, false, false);
    	
    }
    
    
    
    /**
    * Clone incoming sobject excluding some fields along the way
    */
    public static SObject clone(SObject original, Boolean preserveId, Boolean isDeepClone) {
    
    	return clone(original, preserveId, isDeepClone, false, false);
    	
    }
    
    
    
    /**
    * Clone incoming sobject excluding some fields along the way
    */
    public static SObject clone(SObject original, Boolean preserveId, Boolean isDeepClone, Boolean preserveReadonlyTimestamps) {
    
    	return clone(original, preserveId, isDeepClone, false);
    	
    }
    
    
    
    /**
    * Clone incoming sobject excluding some fields along the way
    */
    public static SObject clone(SObject original, Boolean preserveId, Boolean isDeepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumber) {
    	
    	SObject cloned = original.clone(preserveId, isDeepClone, preserveReadonlyTimestamps, preserveAutonumber);
    	
    	
    	// loop through fields excluded from cloning and wipe them (if present on object)
    	for (String fieldName : FIELD_NAMES_TO_EXCLUDE_FROM_CLONING) {
    		
    		// check first if field is available on object
    		if (isField(original, fieldName)) {
    			
    			cloned.put(
    				fieldName,
    				null
    			);
    			
    		}
    		
    	}
    	
    	
    	return cloned;
    	
    }
    
	
	
    /*
    * return formula fields Map: Field Name => Formula, by Type of Formula
    */
    public static Map<String, String> getFormulaFieldsByDisplayType(Schema.SObjectType objectType, Schema.DisplayType displayType) {

        Map<String, String> toReturn = new Map<String, String>();


        for ( Schema.DescribeFieldResult fieldDescription :
                ObjectUtilities.getObjectFieldsDescribes(
                        String.valueOf(
                                objectType
                        )
                )
        ){

            if ( fieldDescription.isCalculated()
                    &&
                    fieldDescription.getType() == displayType
                    ){

                toReturn.put(
                        fieldDescription.getName(),
                        fieldDescription.getCalculatedFormula()
                );
            }

        }

        return toReturn;
    }
	
	
    /**
     * @param String objectName: which SObject types have to be checked
     * @param String recordDevName : which record name have to be unique
     * @param String namespace : namespace in which record name should be unique
     * @description Method to check  uniqueness of Metadata DeveloperName
     * @return Boolean true if it is unique
     */

    public static Boolean checkNameUniqueness (String objectName, String recordDevName, String namespace) {

        Map<Object, Object> uniqueFields = new Map<Object, Object> {
            FIELD_NAME_DEVELOPER_NAME => recordDevName,
            FIELD_NAME_NAMESPACE_PREFIX => namespace
        };

        return checkRecordUniqueness(objectName, uniqueFields);
    }

    /**
     * @param String objectName: which SObject types have to be checked
     * @param String recordTabName : which record name have to be unique
     * @param String namespace : namespace in which record name should be unique
     * @description Method to check  uniqueness of Metadata TabName__c
     * @return Boolean true if it is unique
     */

    public static Boolean checkTabNameUniqueness (String objectName, String recordTabName, String namespace) {

        Map<Object, Object> uniqueFields = new Map<Object, Object> {
            FIELD_TAB_NAME => recordTabName,
            FIELD_NAME_NAMESPACE_PREFIX => namespace,
            FIELD_TYPE_NAME => TAB_NAME
        };

        return checkRecordUniqueness(objectName, uniqueFields);
    }


    /**
     * @param String objectName: which SObject types have to be checked
     * @param Map<Object, Object> uniqueFields: which record name have to be unique
     * @description Universal method to check  uniqueness of Object fieldName
     * @return Boolean true if it is unique
     */

    public  static Boolean checkRecordUniqueness(String objectName, Map<Object, Object> uniqueFields) {
        AndCondition condition = new AndCondition();
        for (Object key : uniqueFields.keySet()) {
            Object value = uniqueFields.get(key);
            condition.add(
                new FieldCondition(
                    key,
                    value
                )
            );
        }
        return
            (
                Database.countQuery(
                    new SoqlBuilder()
                    .selectCount()
                    .fromx(objectName)
                    .wherex(condition)
                    .toSoql()
                                )
                                >
                                0
                        )
                        ?
                                false
                                :
                                true
                ;
    }
	
	
	
    /**
    * Get custom setting names
    */
    public static Set<String> getCustomSettingNames() {
		
		Set<String> settingNames = new Set<String>();
    	
		
		// loop through object types picking up only hierarchical custom settings	
    	for (SObjectType objectType : Schema.getGlobalDescribe().values()) {
    	
    		DescribeSObjectResult objectDescribe = objectType.getDescribe();
    		
    		if (
    			objectDescribe.isCustomSetting()
    		) {
    			
    			settingNames.add(
    				objectDescribe.getName()
    			);
    			
    		}
    		
    	}
    	
    	
    	return settingNames;
    	
    }
    
    
    
    /**
    * Check whether provided object is list custom settings
    */
    public static Boolean isListCustomSettings(String objectName) {
    	
    	Schema.DescribeSObjectResult objectDescribe = getObjectDescribe(objectName);
    	
    	
    	return
    		// is custom settings
    		objectDescribe.isCustomSetting()
    		&&
    		// name is not nillable (to differ hierarchical vs custom)
    		!objectDescribe.fields.getMap().get('Name').getDescribe().isNillable()
    	;
    	
    }    
    
    
    
    /**
    * Get all field names for sobject provided by name
    */
    public static Set<String> getAllFieldNames(String objectName) {
    	
    	Set<String> fieldNames = new Set<String>();
    	
    	
    	for (Schema.SObjectField objectField : getSObjectFieldsMap(objectName).values()) {
    		
			fieldNames.add(
				String.valueOf(
					objectField
				)
			);
    	}
		
		
    	return fieldNames;
		
    }
    
    
    
    /**
    * Get createable field names for sobject provided by name
    */
    public static Set<String> getCreateableFieldNames(String objectName) {
    	
    	Set<String> fieldNames = new Set<String>();
    	
    	
    	for (Schema.SObjectField objectField : getSObjectFieldsMap(objectName).values()) {
    		
    		Schema.DescribeFieldResult fieldDescribe = objectField.getDescribe();
    		
    		
    		if (fieldDescribe.isCreateable()) {
    			
    			fieldNames.add(
    				fieldDescribe.getName()
    			);
    			
    		}
    		
    	}
		
		
    	return fieldNames;
		
    }

    /**
     * Build path to parent field from field tokens
     *
     * @param relationshipField - relationship field on child - token
     * @param parentField - token field on parent
     *
     * @return String - path to the parent field from child
     * getParentFieldPath(AccountTerritoryFields__c.PreferredAddress__c, AccountAddress__c.FullAddress__c)
     * will result in 'PreferredAddress__r.FullAddress__c' - namespace safe
     */
    public static String getParentFieldPath(SObjectField relationshipField, SObjectField parentField) {
        return BaseUtilities.getRelationshipName(String.valueOf(relationshipField))
                + BaseUtilities.DOT
                + String.valueOf(parentField);
    }

    /**
     * Convert set of Strings into Set of Ids.
     * It keeps only valid ID.
     * @param strIds Set of origin strings
     * @return Set of valid ID
     */
    public static Set<Id> getValidIds(Set<String> strIds) {
        Set<Id> ids = new Set<Id>();
        for (String s: strIds) {
            try {
                ids.add(Id.valueOf(s));
            } catch(Exception ex) {}
        }
        return ids;
    }
    
    /**
    * Check whether object has specified fieldpath
    */
    public static Boolean objectHasFieldPath(String objName, String fieldPath) {

        if(fieldPath.contains('.')) {

            String relationName = fieldPath.substringBefore('.');

            fieldPath = fieldPath.substringAfter('.');

            SObjectType soType = Schema.getGlobalDescribe().get(objName);

            if (soType == null) {

                return false;
            }

            Schema.DescribeSObjectResult descSobjResult = soType.getDescribe();

            for (Schema.SObjectField soField : descSobjResult.fields.getMap().values()) {

                Schema.DescribeFieldResult desFieldResult = soField.getDescribe();

                String relationshipName = desFieldResult.getRelationshipName();

                if (relationshipName == relationName) {

                    return objectHasFieldPath(String.valueOf(desFieldResult.getReferenceTo()[0]),
                            fieldPath);
                }
            }

            for (Schema.ChildRelationship childRelationship : descSobjResult.getChildRelationships()) {


                if(childRelationship.getRelationshipName() == relationName) {

                    return objectHasFieldPath(String.valueOf(childRelationship.getChildSObject()),
                            fieldPath);
                }


            }

            return false;
        } else {

            return isField(objName, fieldPath);

        }
    }

    public static Map<Permission, Boolean> getSObjectPermissions(SObjectType sObjType) {
        Schema.DescribeSObjectResult objectDescribe = ObjectUtilities.getObjectDescribe(sObjType);

        return new Map<Permission, Boolean> {
            Permission.CREATE => objectDescribe.isCreateable(),
            Permission.EDIT => objectDescribe.isUpdateable(),
            Permission.REMOVE => objectDescribe.isDeletable()
        };
    }

    public static Map<String, Boolean> getObjectLevelPermissions(SObjectType sObjType) {
        Map<String, Boolean> result = new Map<String, Boolean>();

        Map<Permission, Boolean> permissions = getSObjectPermissions(sObjType);
        for (Permission permission : permissions.keySet()) {
            result.put(permission.name().toLowerCase(), permissions.get(permission));
        }

        return result;
    }
}