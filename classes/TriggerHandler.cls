/**********************************************************************
 Name: TriggerHandler.cls
 Other classes used: -
 Tested in class: TriggerHandler_Test.cls
======================================================
Description:
    Base class for trigger framework by Kevin O'Hara (https://github.com/kevinohara80/sfdc-trigger-framework).

    This trigger framework bundles a single TriggerHandler base class that you can inherit from in all of your trigger handlers.
    The base class includes context-specific methods that are automatically called when a trigger is executed.

    The base class also provides a secondary role as a supervisor for Trigger execution. It acts like a watchdog, monitoring trigger
    activity and providing an api for controlling certain aspects of execution and control flow.
======================================================
History
-------
VERSION         AUTHOR                DATE              DETAIL
    1.0        Saritha.anumandla     11/4/2019        Intital version
***********************************************************************/

public virtual class TriggerHandler {

    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;

    // the current context of the trigger, overridable in tests
    @TestVisible
    private Boolean isTriggerExecuting;

    // For caching RecordTypes
    private static Set<Schema.SObjectType> rtObjectTypes;
    private static Boolean byPassAll = false;
    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
        rtObjectTypes = new Set<Schema.SObjectType>();
    }

    // constructor
    public TriggerHandler() {
        this.setTriggerContext();
    }

    /***************************************
    * public instance methods
    ***************************************/

    // main method that will be called during execution
    public void run() {

        if(!validateRun()) return;

        addToLoopCount();

        // cache RecordTypes
        this.cacheRecordTypes();

        // dispatch to the correct handler method
        if(this.context == TriggerContext.BEFORE_INSERT) {
            this.beforeInsert();
        } else if(this.context == TriggerContext.BEFORE_UPDATE) {
            this.beforeUpdate();
        } else if(this.context == TriggerContext.BEFORE_DELETE) {
            this.beforeDelete();
        } else if(this.context == TriggerContext.AFTER_INSERT) {
            this.afterInsert();
        } else if(this.context == TriggerContext.AFTER_UPDATE) {
            this.afterUpdate();
        } else if(this.context == TriggerContext.AFTER_DELETE) {
            this.afterDelete();
        } else if(this.context == TriggerContext.AFTER_UNDELETE) {
            this.afterUndelete();
        }

    }

    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if(!TriggerHandler.loopCountMap.containsKey(handlerName)) {
            TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }

    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }

    /***************************************
    * public static methods
    ***************************************/

    public static void bypass(String handlerName) {
        TriggerHandler.bypassedHandlers.add(handlerName);
    }
    public static void bypassAll() {
        byPassAll = true;
    }

    public static void clearBypass(String handlerName) {
        TriggerHandler.bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return TriggerHandler.bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        TriggerHandler.bypassedHandlers.clear();
        byPassAll = false;
    }

    /***************************************
    * Methods for caching RecordTypes
    ***************************************/

    // Add list of Objects for RecordTypes to be cached
    public static void addRecordTypeObjects( List<Schema.SObjectType> objTypes ) {
        for ( Schema.SObjectType objType : objTypes ) {
            TriggerHandler.rtObjectTypes.add( objType );
        }
    }

    // Cache RecordTypes
    private void cacheRecordTypes() {
        if ( !TriggerHandler.rtObjectTypes.isEmpty() ) {
           // Utils.cacheRecordTypes( TriggerHandler.rtObjectTypes );
        }
    }

    /***************************************
    * private instancemethods
    ***************************************/

    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }

    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } else {
            this.isTriggerExecuting = true;
        }

        if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) ||
                (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) ||
                (ctx != null && ctx == 'before update')){
            this.context = TriggerContext.BEFORE_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) ||
                (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) ||
                (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) ||
                (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) ||
                (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) ||
                (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }

    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if(TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = TriggerHandler.loopCountMap.get(handlerName).increment();
            if(exceeded) {
                Integer max = TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }

    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
        if(!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        if (byPassAll) return false;
        if(TriggerHandler.bypassedHandlers.contains(getHandlerName())) {
            System.debug('Bypassing ' + getHandlerName());
            return false;
        }
        return true;
    }

    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }

    /***************************************
    * context methods
    ***************************************/

    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}

    /***************************************
    * inner classes
    ***************************************/

    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }

        public Boolean exceeded() {
            if(this.max < 0) return false;
            if(this.count > this.max) {
                return true;
            }
            return false;
        }

        public Integer getMax() {
            return this.max;
        }

        public Integer getCount() {
            return this.count;
        }

        public void setMax(Integer max) {
            this.max = max;
        }
    }

    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE,
        AFTER_UNDELETE
    }

    // exception class
    public class TriggerHandlerException extends Exception {}

}