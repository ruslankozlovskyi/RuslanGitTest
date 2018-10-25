/**
* Data layer to wrap standard DML operations, trigger callbacks etc.
* NOTE: 'sharing' keyword is deliberately omitted here to let methods be executed with caller class sharing model
*/
public class DataLayer {
	
	
	/**
	* Get records count
	*/
	public static Integer queryCount(Integer count, String objectName) {
		
		return
			queryCount(
				count,
				ObjectUtilities.getObjectType(
					objectName
				)
			)
		;
		
	}
	
	
	
	/**
	* Get records count
	*/
	public static Integer queryCount(Integer count, SObjectType objectType) {
		
		return
			fireAfterCount(
				count,
				objectType
			)
		;
		
	}
	
	
	
	/**
	* Get aggregate records
	*/
	public static List<SObject> queryAggregate(List<SObject> records) {
		
		return
			fireAfterAggregate(
				records
			)
		;
		
	}
	
	
	
	/**
	* Get aggregate records
	*/
	public static List<SObject> queryAggregate(String query) {
		
		checkForSoqlQueryLimit();
		
		return
			queryAggregate(
				Database.query(
					query
				)
			)
		;
		
	}
	
	
	
	/**
	* Get single record from the incoming collection
	*/
	public static SObject querySingle(List<SObject> records) {
		
		return
			BaseUtilities.isNullOrEmpty(records)
			?
				null
				:
				querySingle(
					records[0]
				)
		;
		
	}
	
	
	
	/**
	* Get single record
	*/
	public static SObject querySingle(SObject record) {
		
		return
			(SObject)
			BaseUtilities.getFirstIfAny(
				queryAll(
					new List<SObject> {
						record
					}
				)
			)
		;
		
	}
	
	
	
	/**
	* Alias to get all records from incoming collection
	*/
	public static List<SObject> queryAll(List<SObject> records) {
		
		return query(records);
		
	}


	/**
	* Execute incoming query to get single record
	*/
	public static SObject querySingle(String query) {
		
		return
			(SObject)
			BaseUtilities.getFirstIfAny(
				queryAll(
					query
				)
			)
		;
		
	}
	
	
	
	/**
	* Execute incoming query to get all records
	*/
	public static List<SObject> queryAll(String query) {
		
		checkForSoqlQueryLimit();
		
		return
			query(
				Database.query(
					fireBeforeSelect(query)
				)
			)
		;
		
	}
	
	
	
	/**
	* Insert single incoming record
	*/
	public static SObject insertSingle(SObject record) {
		
		return
			(SObject)
			BaseUtilities.getFirstIfAny(
				insertAll(
					new List<SObject> {
						record
					}
				)
			)
		;
		
	}
	
	
	
	/**
	* Insert single incoming record with 'allOrNone' option
	*/
	public static Database.SaveResult insertSingle(SObject record, Boolean allOrNone) {
		
		return
			(Database.SaveResult)
			BaseUtilities.getFirstIfAny(
				insertAll(
					new List<SObject> {
						record
					},
					allOrNone
				)
			)
		;
		
	}
	
	
	
	/**
	* Insert single incoming record with DML options
	*/
	public static Database.SaveResult insertSingle(SObject record, Database.DMLOptions dmlOptions) {
		
		return
			(Database.SaveResult)
			BaseUtilities.getFirstIfAny(
				insertAll(
					new List<SObject> {
						record
					},
					dmlOptions
				)
			)
		;
		
	}
	
	
	
	/**
	* Insert incoming collection of records
	*/
	public static List<SObject> insertAll(List<SObject> records) {
		
		insert records;
		
		return records;
		
	}
	
	
	
	/**
	* Insert incoming collection of records with 'allOrNone' option
	*/
	public static List<Database.SaveResult> insertAll(List<SObject> records, Boolean allOrNone) {
		
		return
			Database.insert(
				records,
				allOrNone
			)
		;
		
	}
	
	
	
	/**
	* Insert incoming collection of records with DML options
	*/
	public static List<Database.SaveResult> insertAll(List<SObject> records, Database.DMLOptions dmlOptions) {
		
		return
			Database.insert(
				records,
				dmlOptions
			)
		;
		
	}
	
	
	
	/**
	* Update single incoming record
	*/
	public static SObject updateSingle(SObject record) {
		
		return
			(SObject)
			BaseUtilities.getFirstIfAny(
				updateAll(
					new List<SObject> {
						record
					}
				)
			)
		;
		
	}
	
	
	
	/**
	* Update single incoming record with 'allOrNone' option
	*/
	public static Database.SaveResult updateSingle(SObject record, Boolean allOrNone) {
		
		return
			(Database.SaveResult)
			BaseUtilities.getFirstIfAny(
				insertAll(
					new List<SObject> {
						record
					},
					allOrNone
				)
			)
		;
		
	}
	
	
	
	/**
	* Update single incoming record with DML options
	*/
	public static Database.SaveResult updateSingle(SObject record, Database.DMLOptions dmlOptions) {
		
		return
			(Database.SaveResult)
			BaseUtilities.getFirstIfAny(
				updateAll(
					new List<SObject> {
						record
					},
					dmlOptions
				)
			)
		;
		
	}
	
	
	
	/**
	* Update incoming collection of records
	*/
	public static List<SObject> updateAll(List<SObject> records) {
		
		update records;
		
		return records;
		
	}
	
	
	
	/**
	* Update incoming collection of records with 'allOrNone' option
	*/
	public static List<Database.SaveResult> updateAll(List<SObject> records, Boolean allOrNone) {
		
		return
			Database.update(
				records,
				allOrNone
			)
		;
		
	}
	
	
	
	/**
	* Update incoming collection of records with DML options
	*/
	public static List<Database.SaveResult> updateAll(List<SObject> records, Database.DMLOptions dmlOptions) {
		
		return
			Database.update(
				records,
				dmlOptions
			)
		;
		
	}
	
	
	/**
	* Upsert single incoming record
	*/
	public static SObject upsertSingle(SObject record) {
		
		return
			(SObject)
			BaseUtilities.getFirstIfAny(
				upsertAll(
					new List<SObject> {
						record
					}
				)
			)
		;
		
	}
	
	
	
	/**
	* Upsert single incoming record using default external id (i.e. id field itself) with 'allOrNone' option
	*/
	public static Database.UpsertResult upsertSingle(SObject record, Boolean allOrNone) {
		
		return
			(Database.UpsertResult)
			BaseUtilities.getFirstIfAny(
				upsertAll(
					new List<SObject> {
						record
					},
					allOrNone
				)
			)
		;
		
	}
	
	
	
	/**
	* Upsert incoming collection of records
	*/
	public static List<SObject> upsertAll(List<SObject> records) {
		
		upsert 
			CollectionUtilities.cloneToConcreteType(
				records
			)
		;
		
		return records;
		
	}
	
	
	
	/**
	* Upsert incoming collection of records using default external id (i.e. id field itself) with 'allOrNone' option
	*/
	public static List<Database.UpsertResult> upsertAll(List<SObject> records, Boolean allOrNone) {
		
		return
			Database.upsert( 
				CollectionUtilities.cloneToConcreteType(
					records
				),
				allOrNone
			)
		;
		
	}
	
	
	
	/**
	* Delete single incoming record
	*/
	public static void deleteSingle(SObject record) {
		
		deleteAll(
			new List<SObject> {
				record
			}
		);
		
	}
	
	
	
	/**
	* Delete single incoming record with 'allOrNone' option
	*/
	public static Database.DeleteResult deleteSingle(SObject record, Boolean allOrNone) {
		
		return
			(Database.DeleteResult)
			BaseUtilities.getFirstIfAny(
				deleteAll(
					new List<SObject> {
						record
					},
					allOrNone
				)
			)
		;
		
	}
	
	
	
	/**
	* Delete single incoming record provided by id ('allOrNone' option set to true)
	*/
	public static Database.DeleteResult deleteSingle(Id recordId) {
		
		return
			deleteSingle(
				recordId,
				true
			)
		;
		
	}
	
	
	
	/**
	* Delete single incoming record provided by id with 'allOrNone' option
	*/
	public static Database.DeleteResult deleteSingle(Id recordId, Boolean allOrNone) {
		
		return
			(Database.DeleteResult)
			BaseUtilities.getFirstIfAny(
				deleteAll(
					new List<Id> {
						recordId
					},
					allOrNone
				)
			)
		;
		
	}
	
	
	
	/**
	* Delete incoming collection of records
	*/
	public static void deleteAll(List<SObject> records) {
		
		delete records;
		
	}
	
	
	
	/**
	* Delete incoming collection of records with 'allOrNone' option
	*/
	public static List<Database.DeleteResult> deleteAll(List<SObject> records, Boolean allOrNone) {
		
		return
			Database.delete(
				records,
				allOrNone
			)
		;
		
	}
	
	
	
	/**
	* Delete incoming collection of records provided by ids ('allOrNone' option set to true)
	*/
	public static List<Database.DeleteResult> deleteAll(List<Id> recordIds) {
		
		return
			deleteAll(
				recordIds,
				true
			)
		;
		
	}
	
	
	
	/**
	* Delete incoming collection of records provided by ids with 'allOrNone' option
	*/
	public static List<Database.DeleteResult> deleteAll(List<Id> recordIds, Boolean allOrNone) {
		
		return
			Database.delete(
				recordIds,
				allOrNone
			)
		;
		
	}
	
	
	
	private static List<SObject> query(List<SObject> records) {
		
		return fireAfterSelect(records);
		
	}
	
	
	// fire 'after count' virtual event
	private static Integer fireAfterCount(Integer count, SObjectType objectType) {
		
		return 
			TriggerService.onAfterCount(
				count, 
				objectType
			)
		;
		
	}
	
	
	// fire 'after aggregate' virtual event
	private static List<SObject> fireAfterAggregate(List<SObject> records) {
		
		return 
			TriggerService.onAfterAggregate(
				records
			)
		;
		
	}
	
	
	// fire 'before select' virtual event
	private static String fireBeforeSelect(String query) {
		
		return TriggerService.onBeforeSelect(query);
		
	}
	
	
	// fire 'after select' virtual event
	private static List<SObject> fireAfterSelect(List<SObject> records) {
		
		return TriggerService.onAfterSelect(records);
		
	}
	
	
	// fire 'before insert' virtual event
	private static List<SObject> fireBeforeInsert(List<SObject> records) {
		
		return TriggerService.onBeforeInsert(records);
		
	}
	
	
	// fire 'after insert' virtual event
	private static List<SObject> fireAfterInsert(List<SObject> records) {
		
		return TriggerService.onAfterInsert(records);
		
	}
	
	
	
	// check for soql query limit - just logging error message if detected
	private static void checkForSoqlQueryLimit() {
		
		// early exit - limit has not reached yet
		if (Limits.getQueries() < Limits.getLimitQueries()) {
			return;
		}
		
		BaseUtilities.log(
			new SoqlQueryLimitException(
				'SOQL Query Limit detected by DataLayer'
			),
			'DataLayer.checkForSoqlQueryLimit'
		);
		
	}
	
	
	
	public class SoqlQueryLimitException extends Exception {
		
	}
	
	
}