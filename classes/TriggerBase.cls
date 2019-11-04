public virtual with sharing class TriggerBase {
	public enum DmlOperations {DML_BEFORE_INSERT, DML_AFTER_INSERT, DML_BEFORE_UPDATE,
		DML_AFTER_UPDATE, DML_BEFORE_DELETE, DML_AFTER_DELETE, DML_AFTER_UNDELETE}
/**
* Public constructor. It sets the trigger context.
*/
public TriggerBase() {
	determineOperations();
	sObjectMap = Trigger.newMap;
	sObjectOldMap = Trigger.oldMap; 
	this.sObjectList = Trigger.new;
}
/**
* Public constructor used for testing purposes
*/
@TestVisible
private TriggerBase(DmlOperations dmlOperation) {
	this.dmlOperation = dmlOperation;
}
private DmlOperations dmlOperation;
/**
* Maps for storing the maps related to the trigger context
*/
public Map<Id, sObject> sObjectMap {get; private set;}
public Map<Id, sObject> sObjectOldMap {get; private set;}
/**
* List for storing the values
*/
public List<sObject> sObjectList {get; private set;}
/**
* Determine the operations involved in this trigger context
*/
private void determineOperations() {
	if (Trigger.isBefore) {
		if (Trigger.isInsert) {
			dmlOperation = DmlOperations.DML_BEFORE_INSERT;
			} else if (Trigger.isUpdate) {
				dmlOperation = DmlOperations.DML_BEFORE_UPDATE;
				} else if (Trigger.isDelete) {
					dmlOperation = DmlOperations.DML_BEFORE_DELETE;
				}
				} else if (Trigger.isAfter) {
					if (Trigger.isInsert) {
						dmlOperation = DmlOperations.DML_AFTER_INSERT;
						} else if (Trigger.isUpdate) {
							dmlOperation = DmlOperations.DML_AFTER_UPDATE;
							} else if (Trigger.isDelete) {
								dmlOperation = DmlOperations.DML_AFTER_DELETE;
								} else if (Trigger.isUndelete) {
									dmlOperation = DmlOperations.DML_AFTER_UNDELETE;
								}
							}
						}
/**
* Main method to call to process the trigger
*/
public void processTrigger() {
	if (dmlOperation == DmlOperations.DML_BEFORE_INSERT) {
		beforeInsert();
		} else if (dmlOperation == DmlOperations.DML_BEFORE_UPDATE) {
			beforeUpdate();
			} else if (dmlOperation == DmlOperations.DML_BEFORE_DELETE) {
				beforeDelete();
				} else if (dmlOperation == DmlOperations.DML_AFTER_INSERT) {
					afterInsert();
					} else if (dmlOperation == DmlOperations.DML_AFTER_UPDATE) {
						afterUpdate();
						} else if (dmlOperation == DmlOperations.DML_AFTER_DELETE) {
							afterDelete();
							} else if (dmlOperation == DmlOperations.DML_AFTER_UNDELETE) {
								afterUndelete();
							}
						}
/**
* Handles the beforeInsert events
*/
protected virtual void beforeInsert() {}
/**
* Handles the afterInsert events
*/
protected virtual void afterInsert() {}
/*
* Handles the beforeUpdate events
*/
protected virtual void beforeUpdate() {}
/**
* Handles the afterUpdate events
*/
protected virtual void afterUpdate() {}
/**
* Handles the beforeDelete events
*/
protected virtual void beforeDelete() {}
/**
* Handles the afterDelete events
*/
protected virtual void afterDelete() {}
/**
* Handles the afterUndelete events
*/
protected virtual void afterUndelete() {}
}