public with sharing class AccountTriggerHandler extends TriggerHandler {

	public AccountTriggerHandler(SObjectType objectType) {
        super(objectType);
	}

    public override void beforeInsert() {
        //Do something
    }

    public override void beforeUpdate() {
        //Do something
    }

}