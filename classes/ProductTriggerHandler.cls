public class ProductTriggerHandler extends TriggerBase {
	/**
	* Handles the beforeInsert events
	* Functionality implemented:
	* - ... 
	*/
	protected override void beforeInsert() {
		List<Product2> listNewTrigger = this.sObjectList; 
		Map<Id, SObject> mapNewTrigger = this.sObjectMap;		
		
	}

	/**
	* Handles the afterInsert events
	* Functionality implemented:
	* - ...*/
	protected override void afterInsert() {
		List<Product2> listNewTrigger = this.sObjectList; 
		Map<Id, SObject> mapNewTrigger = this.sObjectMap;		
		
	}

	/**
	* Handles the beforeUpdate events
	* Functionality implemented:
	* - ...*/
	protected override void beforeUpdate() {
		List<Product2> listNewTrigger = this.sObjectList;
		Map<Id, SObject> mapOldTrigger = sObjectOldMap;
		
	}

	/**
	* Handles the afterUpdate events
	* Functionality implemented:
	* - ...*/
	protected override void afterUpdate() {
		List<Product2> listNewTrigger = this.sObjectList; 
		Map<Id, SObject> mapNewTrigger = this.sObjectMap;		
		
	}

	/**
	* Handles the beforeDelete events
	* Functionality implemented:
	* - ...
	*/
	/*protected override void beforeDelete() {
		}*/
	/**
	* Handles the afterDelete events
	* Functionality implemented:
	* - ...
	*/
	/*protected override void afterDelete() {
		}*/
	/**
	* Handles the afterUndelete events
	* Functionality implemented:
	* - ...
	*/
	/*protected override void afterUndelete() {
		}*/
	
}