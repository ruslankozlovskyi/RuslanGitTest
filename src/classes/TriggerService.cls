/**
* Service provides functionality to control handling of objects on trigger executions
* @author Maksym Yakymenko
*/
public abstract class TriggerService {
	

	// special type to denote handlers which should be executed for any sobject with trigger set up, e.g. to check permissions, log audit info etc.
	public static final String ALL_OBJECT_TYPES = 'ALL';
	
	// permission levels
	public static final String PERMISSION_LEVEL_DEFAULT = 'default';				// applies to everyone (user, profile) unless 'ignore' is specified
	public static final String PERMISSION_LEVEL_IGNORE = 'ignore';					// suppress all handlers at all
	public static final String PERMISSION_LEVEL_SECURITY_ONLY = 'security-only';	// suppress all handlers except security related ones
	
	
	// global scope
	private static final Map<String, Object> GLOBAL_SCOPE = new Map<String, Object>();
	
	
	
	@TestVisible
    private static List<HandlerWrapper> allHandlerWrappers {

        get {

            if (allHandlerWrappers == null) {
            	
                Set<String> handlerPermissions = getHandlerPermissions();
                
                allHandlerWrappers = 
                	wrapHandlerConfigs(
                		filterOutDuplicates(
		                    [
		                    	SELECT 
		                    		Id, 
		                     		HandlerName__c, 
		                     		IsActive__c, 
		                     		Description__c, 
		                     		Order__c, 
		                     		Type__c,
		                     		PermissionLevel__c,
		                     		IsAsync__c,
		                     		Params__c
		                     	FROM 
		                     		TriggerHandler__mdt
		                     	WHERE
		                    		PermissionLevel__c IN :handlerPermissions
		                        ORDER BY 
		                        	Order__c ASC
		                    ]
                    	)
                	)
                ;
                
            }
            
            return allHandlerWrappers;
        }

        private set;
    }
    
    
    
    private static List<HandlerWrapper> allActiveHandlerWrappers {
    	
        get {
        	
            if (allActiveHandlerWrappers == null) {
            	
                allActiveHandlerWrappers = 
                	(List<HandlerWrapper>)
                	CollectionUtilities.filterTo(
                		allHandlerWrappers,
                		'active',
                		true
                	)
                ;
                
            }
            
            return allActiveHandlerWrappers;
        }

        private set;
        
    }
    
    
    
    /**
    * After count (virtual) - fetched records count is passed as incoming param and returned back. Object type should also be passed explicitly in this flow.
    */
    public static Integer onAfterCount(Integer count, SObjectType objectType) {
    	
    	Context ctx = new Context(count, objectType);
    	
    	executeActions(ctx);
    	
    	return ctx.count;
    	
    }
    
    
    
    /**
    * After aggregate (virtual) - fetched aggregated records are passed as incoming param and returned back
    */
    public static List<SObject> onAfterAggregate(List<SObject> records) {
    	
    	Context ctx = getAfterAggregateVirtualContext(records);
    	
    	executeActions(ctx);
    	
    	return ctx.records;
    	
    }
    
    
    
    /**
    * Before select (virtual) - query to be executed is passed as incoming param and returned back (potentially could be modified already or completely different query)
    */
    public static String onBeforeSelect(String query) {
    	
    	Context ctx = new Context(query);
    	
    	executeActions(ctx);
    	
    	return ctx.query;
    	
    }
    
    
    
    /**
    * After select (virtual) - fetched records is passed as incoming param and returned back (potentially records could be modified, added/removed etc.)
    */
    public static List<SObject> onAfterSelect(List<SObject> records) {
    	
    	Context ctx = new Context(records);
    	
    	executeActions(ctx);
    	
    	return ctx.records;
    	
    }
    
    
    
    /**
    * Before insert (virtual)
    */
    public static List<SObject> onBeforeInsert(List<SObject> records) {
    	
    	Context ctx = getBeforeInsertVirtualContext(records);
    	
    	executeActions(ctx);
    	
    	return ctx.newList;
    	
    }
    
    
    
    /**
    * After insert (virtual)
    */
    public static List<SObject> onAfterInsert(List<SObject> records) {
    	
    	Context ctx = getAfterInsertVirtualContext(records);
		
    	executeActions(ctx);
    	
    	return ctx.newList;
    	
    }
    
    
    
    public static void onTrigger() {
    	
        if (Trigger.isExecuting) { 
        	
            executeActions(
            	new Context(
            		Trigger.old, 
					Trigger.oldMap, 
					Trigger.new, 
					Trigger.newMap, 
					Trigger.isBefore, 
					Trigger.isAfter, 
					Trigger.isInsert, 
					Trigger.isUpdate, 
					Trigger.isDelete, 
					Trigger.isUndelete
				)
			);
			
        } else {
        	 
        	throw 
        		new TriggerServiceException(
        			Label.Error_Not_Trigger_Context
        		)
        	;
        
        }
        
    }
    
    

    @TestVisible
    private static void executeActions(Context ctx) {
    	
    	SObjectType objectType = ctx.getSObjectType();
    	
    	if (objectType == null) {
    		return;
    	}
    	
    	
        List<Handler> handlers = 
        	createHandlers(
        		ctx
        	)
        ;
		
		
        for (Handler h : handlers) {
			
			// skip handler execution if requested
        	if (h.skipExecution(ctx)) {
        		continue;
			}
			
			
			// async handler - run as blocking if no capacity for doing async
			if (
				h.isAsyncMode(ctx) == true
				&&
				System.isQueueable() == false
				&&
				Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()
			) {
				
				System.enqueueJob(
					new HandlerRunnerAsync(
						ctx, 
						h
					)
				);
				
				
			// sync/blocking handler	
			} else {
			
				callHandler(
					ctx, 
					h
				);
				
			}
			
        }
    
    }
    
    
    
    /**
    * Call handler
    */
    public static void callHandler(Context ctx, Handler h) {
    	
		if (ctx.isBefore) {
            
            if (ctx.isSelect) {
            	
            	h.beforeSelect(ctx);
            	
            } else if (ctx.isInsert) {
            
                h.beforeInsert(ctx);
            
            } else if (ctx.isUpdate) {
            
                h.beforeUpdate(ctx);
            
            } else if (ctx.isDelete) {
            
                h.beforeDelete(ctx);
            
            } else if (ctx.isUndelete) {
            
                h.beforeUndelete(ctx);
            
            }
            
        } else if (ctx.isAfter) {
            
            if (ctx.isSelect) {
            	
            	if (ctx.isCount) {
            		
            		h.afterCount(ctx);
            		
            	} else if (ctx.isAggregate) {
            		
            		h.afterAggregate(ctx);
            		
            	} else {
            		
            		h.afterSelect(ctx);
            		
            	}
            	
            } else if (ctx.isInsert) {
            
                h.afterInsert(ctx);
            
            } else if (ctx.isUpdate) {
            
                h.afterUpdate(ctx);
            
            } else if (ctx.isDelete) {
            
                h.afterDelete(ctx);
            
            } else if (ctx.isUndelete) {
            
                h.afterUndelete(ctx);
            
            }
        
        }
    	
    }
    
    
    
	/**
    * Determines type of the provided object from the trigger context.
    * @return Object type name
    */
    private static String getSObjectType(Context cont) {
        return (cont.isDelete ? cont.oldList : cont.newList).getSObjectType().getDescribe().getName();
    }
    
    
    
    /**
    * Returns configured permission values. User defined settings have the highest priority,   
    * the Profie settings go on the second place and finally if nothing is found 
    * method will return org default permission values.
    * @return Set<String> Permission values
    */
    @TestVisible
    private static Set<String> getHandlerPermissions() {
    	
    	return
    		evaluatePermissions(
    			TriggerPermission__c.getInstance()
    		)
    	;
    	
    }
	
	
	
    /**
    * Evaluate permissions based on configured comma separated list of values along with some system rules being applied (e.g. default, ignore).
    */
    private static Set<String> evaluatePermissions(TriggerPermission__c triggerPermission) {
    	
        Set<String> resultPermissions = new Set<String>();
        
        String permissionLevel = triggerPermission.PermisionLevel__c;
        
        
        if (String.isNotBlank(permissionLevel)) {
        
            for (String permissionValue : permissionLevel.split(BaseUtilities.COMMA)) {
        
                if (String.isNotBlank(permissionValue)) {
        
                    resultPermissions.add(
                    	permissionValue.trim()
                    );
        
                }
        
            }
        
        }
		
		
		// ignore level - wiping permissions since no handlers should be executed at all
		if (resultPermissions.contains(PERMISSION_LEVEL_IGNORE)) {
			
			resultPermissions.clear();
		
		
		// security-only level - wiping permissions and put back only security one, since only secuirty related handlers should be executed
		} else if (resultPermissions.contains(PERMISSION_LEVEL_SECURITY_ONLY)) {
			
			resultPermissions.clear();
			
			resultPermissions.add(
				PERMISSION_LEVEL_SECURITY_ONLY
			);
			
		
		// in test mode - go with original levels
		} else if (
			Test.isRunningTest() 
		) {
			
			// doing nothing - are good with levels already defined
			
		
		// otherwise - presume default level for everyone
		} else {
			
			resultPermissions.add(
				PERMISSION_LEVEL_DEFAULT
			);
			
		}
		
		
        return resultPermissions;
		
    }
	
	
	
    /**
    * Get all the available trigger handler configurations in appropriate order to be applied to incoming object type
    * @param sType - Object type name
    * @return All active handler configurations
    */
    private static List<HandlerWrapper> getHandlersPerObjectType(Context ctx) {
		
		List<HandlerWrapper> handlerWrappers =
			(List<HandlerWrapper>)
			CollectionUtilities.filterTo(
				allActiveHandlerWrappers,
				'sType',
				new Set<String> {
					String.valueOf(
						ctx.getSObjectType()
					),
					ALL_OBJECT_TYPES
				}
			)
		;
		
		// sort handler configs by order asc, i.e. 0-10-20... - lowest should be executed first
		handlerWrappers.sort();
		
		
        return handlerWrappers;
        
    }
    
    
    
	/**
    * Create handlers to be applied to incoming object type
    * @param sType Object type name
    * @return All active handlers
    */
    @TestVisible
    private static List<Handler> createHandlers(Context ctx) {
        
        List<Handler> handlers = new List<Handler>();
		
		
        for ( HandlerWrapper hw : getHandlersPerObjectType(ctx) ) {
            
            try {
            
                Type handlerType = Type.forName(hw.name);
                
                if (handlerType != null) {
                	
                	Handler instance = (Handler)handlerType.newInstance();
                	
                	instance.init(hw);
                	
                	
                    handlers.add(
                    	instance
                    );
                    
                } else {
                	
                    System.debug(
                    	LoggingLevel.ERROR, 
                    	'TriggerService::onTrigger can\'t instantiate handler for setting: ' + hw
                    );
                    
                }
            
            } catch (Exception exp) {
            	
                System.debug(
                	LoggingLevel.ERROR, 
                	'TriggerService::onTrigger exception instantiating handler for setting: ' + hw + ' Exception: ' + exp.getMessage()
                );
                
            }
            
        }
		
		
        return handlers;
		
    }
	
	
	
	/**
	* Filter out duplicate handlers (higher order has priority), i.e. only the first handler instance in the execution chain among duplicates is considered.
	* Case insensitive comparison of hander names (i.e. class names) is used as duplication criteria.
	*/
	public static List<TriggerHandler__mdt> filterOutDuplicates(List<TriggerHandler__mdt> handlers) {
		
		Set<String> handlerNames = new Set<String>();
		
		List<TriggerHandler__mdt> uniqueHandlers = new List<TriggerHandler__mdt>();
		
		
		for (TriggerHandler__mdt handler : handlers) {
			
			// normalize handler name
			String normalizedHandlerName = 
				BaseUtilities.coalesce(handler.HandlerName__c).trim().toLowerCase()
			;
			
			
			// early exit - duplicate handler
			if (handlerNames.contains(normalizedHandlerName)) {
				continue;
			}
			
			
			// collect unique handler
			{
				
				uniqueHandlers.add(handler);
				
				handlerNames.add(normalizedHandlerName);
				
			}
			
		}
		
		
		return uniqueHandlers;
		
	}
	
	
	
    /**
    * Wraps handler configuration objects for more flexible usage
    * @param handlerSObjs Original handler configuration objects
    * @return Handler configuration wrappers
    */
    @TestVisible
    private static List<HandlerWrapper> wrapHandlerConfigs(List<TriggerHandler__mdt> handlerConfigs) {
        
        List<HandlerWrapper> handlerConfigWrappers = new List<HandlerWrapper>();
		
		
        for (TriggerHandler__mdt handlerConfig : handlerConfigs) {
            
            handlerConfigWrappers.add(
            	new HandlerWrapper(
            		handlerConfig.HandlerName__c, 
					handlerConfig.IsActive__c, 
					handlerConfig.Description__c, 
					(Integer)handlerConfig.Order__c, 
					handlerConfig.Type__c, 
					handlerConfig.PermissionLevel__c,
					handlerConfig.IsAsync__c,
					handlerConfig.Params__c
				)
			);
			
        }

        return handlerConfigWrappers;
        
    }
    
    
    
    /**
    * Class provides entry points for object handling logic implementation
    */
    public virtual class Handler {
		
		protected Map<String, Object> params = new Map<String, Object>();
		
		protected String objectName;
		
		private Boolean asyncMode;
		
		
		public void init(HandlerWrapper config) {
			
			this.params =
				BaseUtilities.isNullOrEmpty(
					config.params
				)
				?
					new Map<String, Object>()
					:
					JsonUtilities.toObject(
						config.params
					)
			;
			
			this.objectName = config.sType;
			
			this.asyncMode = config.isAsync;
			
		}
		
		
		public virtual Boolean skipExecution(Context cont) {
			return false; // do not skip by default
		}
		
		
		public virtual Boolean isAsyncMode(Context cont) {
			return asyncMode;
		}
		
		
		public Map<String, Object> getParams() {
			return params;
		}
		
		
		public String getStringParam(String paramName) {
			
			return
				(
					params <> null
					&&
					params.containsKey(paramName)
				)
				?
					String.valueOf(
						params.get(paramName)
					)
					:
					null
			;
			
		}
		
		
		public Integer getIntegerParam(String paramName) {
				
			return
				(
					params <> null
					&& 
					params.containsKey(paramName)
				)
				?
					NumberUtilities.toInteger(
						params.get(
							paramName
						),
						null
					)
					:
					null
			;
			
		}
		
		
		
		public virtual void beforeSelect(Context cont) {}
		public virtual void afterSelect(Context cont) {}
		public virtual void afterCount(Context cont) {}
		public virtual void afterAggregate(Context cont) {}
        public virtual void beforeInsert(Context cont) {}
        public virtual void afterInsert(Context cont) {}
        public virtual void beforeUpdate(Context cont) {}
        public virtual void afterUpdate(Context cont) {}
        public virtual void beforeDelete(Context cont) {}
        public virtual void afterDelete(Context cont) {}
        public virtual void beforeUndelete(Context cont) {}
        public virtual void afterUndelete(Context cont) {}
		
    }
	
	
    /**
    * Class contains all the available data from the trigger context scope
    */
    public class Context {
		
		public Integer count { get; set; }
		public SObjectType sourceType { get; set; }
		
		public String query { get; set; }
		public List<SObject> records { get; set; }
		
        public List<SObject> oldList { get; set; }
        public Map<Id, SObject> oldMap { get; set; }

        public List<SObject> newList { get; set; }
        public Map<Id, SObject> newMap { get; set; }

        public Boolean isBefore { get; set; }
        public Boolean isAfter { get; set; }
        public Boolean isSelect { get; set; }
        public Boolean isInsert { get; set; }
        public Boolean isUpdate { get; set; }
        public Boolean isDelete { get; set; }
        public Boolean isUndelete { get; set; }
        
        
        // additional modifiers for 'select' flow
        public Boolean isCount { get; set; }
        public Boolean isAggregate { get; set; }
        
        
        // indicator of virtual mode, i.e. not in trigger context
        public Boolean isVirtual { get; set; }
        
        
        // global scope
        public Map<String, Object> globalScope { get; set; }
        
        
        // select count query (only after phase is supported)
        public Context(Integer count, SObjectType sourceType) {
        	
        	this();
        	
        	this.isSelect = true;
        	this.isCount = true;
        	this.isAfter = true;
        	
        	this.isVirtual = true;
        	
        	this.count = count;
        	this.sourceType = sourceType;
        	
        }
        
        
       	// select query - text version (mainly for before phase)
        public Context(String query) {
        	
        	this();
        	
        	this.isSelect = true;
        	this.isBefore = true;
        	
        	this.isVirtual = true;
        	
        	this.query = query;
        	
        }
        
        
        // select query - fetched records (sort of after phase)
        public Context(List<SObject> records) {
        	
        	this();
        	
        	this.isSelect = true;
        	this.isAfter = true;
        	
        	this.isVirtual = true;
        	
        	this.records = records;
        	
        }
        

        public Context(
        	List<SObject> oldList, Map<Id, SObject> oldMap,
            List<SObject> newList, Map<Id, SObject> newMap,
            Boolean isBefore, Boolean isAfter,
            Boolean isInsert, Boolean isUpdate,
            Boolean isDelete, Boolean isUndelete
		) {
			
			this();
			
            this.oldList = oldList;
            this.oldMap = oldMap;
            this.newList = newList;
            this.newMap = newMap;
            this.isBefore = isBefore;
            this.isAfter = isAfter;
            this.isInsert = isInsert;
            this.isUpdate = isUpdate;
            this.isDelete = isDelete;
            this.isUndelete = isUndelete;
            
        }
		
		
        public Context() {
			            
            this.isBefore = false;
            this.isAfter = false;
            this.isInsert = false;
            this.isUpdate = false;
            this.isDelete = false;
            this.isUndelete = false;
            this.isSelect = false;
            this.isCount = false;
            this.isAggregate = false;
            
            this.isVirtual = false;
            
			this.count = 0;
			this.sourceType = null;
			
            this.query = '';            
            this.records = new List<SObject>();
			
            this.oldList = new List<SObject>();
            this.oldMap = new Map<Id, SObject>();
            
            this.newList = new List<SObject>();
            this.newMap = new Map<Id, SObject>();
            
            this.globalScope = GLOBAL_SCOPE;
            
        }
		
		
	    public SObjectType getSObjectType() {
	    	
	    	if (this.isSelect) {
	    		
	    		if (this.isBefore) {
	    			
	    			// figure out object name from query
	    			return 
	    				ObjectUtilities.getObjectType(
	    					SoqlUtilities.getFromObjectName(
	    						this.query
	    					)
	    				)
	    			;
	    			
	    			
	    		} else if (this.isAfter) {
	    			
	    			if (this.isCount) {
	    				
	    				return this.sourceType;
	    				
	    			} else {
	    				
	    				return records.getSObjectType();
	    				
	    			}
	    			
    			}
	    	
	    		
    		} else if (this.isDelete) {
    			
    			return this.oldList.getSObjectType();
    		
    			
    		} else {
    			
    			return this.newList.getSObjectType();
    			
    		}
	    	
	    	
	    	return null;
	    	
    	}
		
    }
    
    
    
    // build 'after aggregate' virtual context
    private static Context getAfterAggregateVirtualContext(List<SObject> records) {
		
		Context ctx = new Context();
		
    	ctx.isSelect = true;
    	ctx.isAggregate = true;
    	ctx.isAfter = true;
    	
    	ctx.isVirtual = true;
    	
		ctx.records = records;
		
    	
    	return ctx;
    	
    }
    
    
    
    // build 'before insert' virtual context
    private static Context getBeforeInsertVirtualContext(List<SObject> records) {
	
		Context ctx = new Context();
		
    	ctx.isInsert = true;
    	ctx.isBefore = true;
    	
    	ctx.isVirtual = true;
    	
    	ctx.newList = records;
    	ctx.newMap = new Map<Id, SObject>(records);
    	
    	
    	return ctx;
    	
    }
    
    
    
    // build 'before insert' virtual context
    private static Context getAfterInsertVirtualContext(List<SObject> records) {
	
		Context ctx = new Context();
		
    	ctx.isInsert = true;
    	ctx.isAfter = true;
    	
    	ctx.isVirtual = true;
    	
    	ctx.newList = records;
    	ctx.newMap = new Map<Id, SObject>(records);
    	
    	
    	return ctx;
    	
    }
	
	
	
    /**
    * Trigger handler configuration wrapper class for more flexible usage of the provided configuration
    */
    public class HandlerWrapper implements Comparable {

        public String name { get; set; }
        public Boolean active { get; set; }
        public String description { get; set; }
        public Integer order { get; set; }
        public String sType { get; set; }
        public String permission { get; set; }
		public Boolean isAsync { get; set; }
		public String params { get; set; }
		
		
		
		public HandlerWrapper(String name, Boolean active, String description, Integer order, String sType, String permission) {
			
			this(name, active, description, order, sType, permission, false);
			
		}
		
		
		
        public HandlerWrapper(String name, Boolean active, String description, Integer order, String sType, String permission, Boolean isAsync) {
        	
        	this(name, active, description, order, sType, permission, false, null);
        	
        }
		
		
		
        public HandlerWrapper(String name, Boolean active, String description, Integer order, String sType, String permission, Boolean isAsync, String params) {
        
            this.name = name;
            this.active = active;
            this.description = description;
            this.order = order;
            this.sType = sType;
            this.permission = permission;
        	this.isAsync = isAsync;
        	this.params = params;
        	
        }
        
        
        
        /**
        * Compare handlers based on order
        */
        public Integer compareTo(Object other) {
        	
        	return 
        		this.order 
        		- 
        		((HandlerWrapper)other).order
        	;
        	
        }
        


        /**
        * Returns the stringified wrapped handler cofiguration in more readable format
        */
        public override String toString() {
        	
            return 
            	String.format(
            		'Handler Wrapper: <<HandlerName__c: {0}, IsActive__c: {1}, Description__c: {2}, Order__c: {3}, Type__c: {4}, PermissionLevel__c: {5}, IsAsync__c: {6}>>', 
					new List<String> {
						name, 
						String.valueOf(active), 
						description, 
						String.valueOf(order), 
						sType, 
						permission,
						String.valueOf(isAsync)
					}
				)
			;
			
        }

    }
    
    
        
	/**
    * Custom exception for handling trigger service execution faults
    */
    private class TriggerServiceException extends Exception {  }
    
    
    
	
	/**
	* Async handler runner
	*/
    public class HandlerRunnerAsync implements Queueable, Database.AllowsCallouts {
    	
    	private Context ctx;
    	private Handler hnd;
    	
    	
    	
    	public HandlerRunnerAsync(Context ctx, Handler hnd) {
    		
    		this.ctx = ctx;
    		
    		this.hnd = hnd;
    		
    	}
    	
    	
    	public void execute(QueueableContext asyncContext) {
    		
    		callHandler(ctx, hnd);
    		
    	}
    	
    }
    

}