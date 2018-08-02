# SFDC trigger framework

## Overview

Triggers should (IMO) be logicless. Putting logic into your triggers creates un-testable, difficult-to-maintain code. It's widely accepted that a best-practice is to move trigger logic into a handler class.

This trigger framework bundles a single **TriggerHandler** base class that you can inherit from in all of your trigger handlers. The base class includes context-specific methods that are automatically called when a trigger is executed.

The base class also provides a secondary role as a supervisor for Trigger execution. It acts like a watchdog, monitoring trigger activity and providing an api for controlling certain aspects of execution and control flow.

But the most important part of this framework is that it's minimal and simple to use. 

This framework can also be integrated with an event logging framework to enable automated event logging for all trigger events.

**Deploy to SFDX Scratch Org:**
[![Deploy](https://deploy-to-sfdx.com/dist/assets/images/DeployToSFDX.svg)](https://deploy-to-sfdx.com)

## Installation Instructions
Make a temporary directory to convert your source
```
mkdir src
```
Convert project to metadata API format
```
sfdx force:source:convert -d src/ --packagename eventlogging
```

Authenticate to your org

Sandbox
```
sfdx force:auth:web:login --setalias <org_alias> --instanceurl https://test.salesforce.com
```
Production
```
sfdx force:auth:web:login --setalias <org_alias> --instanceurl https://login.salesforce.com
```
Custom Domain
```
sfdx force:auth:web:login --setalias <org_alias> --instanceurl https://mydomain.my.salesforce.com
```

Deploy to Org
```
sfdx force:mdapi:deploy -d src/ -l RunSpecifiedTests -r LogTest,SessionControllerTest --wait 30 -u "org_alias"
```

## Usage

To create a trigger handler, you simply need to create a class that inherits from **TriggerHandler.cls**. Here is an example for creating an Opportunity trigger handler, and add the constructor shown below.

```java
public class OpportunityTriggerHandler extends TriggerHandler {
  
  public OpportunityTriggerHandler(SObjectType objectType) {
    super(objectType);
  }

}
```

In your trigger handler, to add logic to any of the trigger contexts, you only need to override them in your trigger handler. Here is how we would add logic to a `beforeUpdate` trigger.

```java
public class OpportunityTriggerHandler extends TriggerHandler {

  public OpportunityTriggerHandler(SObjectType objectType) {
    super(objectType);
  }
  
  public override void beforeUpdate() {
    for(Opportunity o : (List<Opportunity>) Trigger.new) {
      // do something
    }
  }

  // add overrides for other contexts

}
```

**Note:** When referencing the Trigger statics within a class, SObjects are returned versus SObject subclasses like Opportunity, Account, etc. This means that you must cast when you reference them in your trigger handler. You could do this in your constructor if you wanted. 

```java
public class OpportunityTriggerHandler extends TriggerHandler {

  private Map<Id, Opportunity> newOppMap;

  public OpportunityTriggerHandler(SObjectType objectType) {
    super(objectType);
    this.newOppMap = (Map<Id, Opportunity>) Trigger.newMap;
  }
  
  public override void afterUpdate() {
    //
  }

}
```

To use the trigger handler, you only need to construct an instance of your trigger handler within the trigger handler itself, pass the object type of the records being processed by the trigger, and call the `run()` method. Here is an example of the Opportunity trigger.

```java
trigger OpportunityTrigger on Opportunity (before insert, before update) {
  new OpportunityTriggerHandler(Opportunity.getSObjectType()).run();
}
```

## Cool Stuff

### Integrate with Automated Event Logging

To integrate with the event logging module, you must first install the event logging application. Instructions to do that can be found [here](https://github.com/dmgerow/sfdc-event-logging). 

After this, uncomment the try/catch statement that contains the implementation of the event logging application:

```java
  public void run() {

    if(!validateRun()) return;

    addToLoopCount();
    // try { uncomment this if you want to enable event-logging: https://github.com/dmgerow/sfdc-event-logging
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
    // uncomment this code block if you want to enable event-logging: https://github.com/dmgerow/sfdc-event-logging
    // } catch(Exception e) { 
    //   String errorId = LogService.createErrorId();
    //   Log.push('TriggerHandler.run()');
    //   log.errorId(errorId);
    //   Log.message(objectType.getDescribe().getName() + '.' + this.context);
    //   Log.rootReason(objectType.getDescribe().getName() + ' : ' + this.context);
    //   Log.rootException(e);
    //   Log.pop();
    //   Log.emit(); 
    //   List<SObject> records = this.context == TriggerContext.BEFORE_DELETE 
    //       || this.context == TriggerContext.AFTER_DELETE ? trigger.old : trigger.new;
    //   for(SObject record : records) {
    //     record.addError(errorId + ': ' + e.getMessage()); 
    //   }
    // }
  }
```
Should be changed to:

```java
  public void run() {

    if(!validateRun()) return;

    addToLoopCount();
    try {
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
    } catch(Exception e) { 
      String errorId = LogService.createErrorId();
      Log.push('TriggerHandler.run()');
      log.errorId(errorId);
      Log.message(objectType.getDescribe().getName() + '.' + this.context);
      Log.rootReason(objectType.getDescribe().getName() + ' : ' + this.context);
      Log.rootException(e);
      Log.pop();
      Log.emit(); 
      List<SObject> records = this.context == TriggerContext.BEFORE_DELETE 
          || this.context == TriggerContext.AFTER_DELETE ? trigger.old : trigger.new;
      for(SObject record : records) {
        record.addError(errorId + ': ' + e.getMessage()); 
      }
    }
  }
```

### Max Loop Count

To prevent recursion, you can set a max loop count for Trigger Handler. If this max is exceeded, and exception will be thrown. A great use case is when you want to ensure that your trigger runs once and only once within a single execution. Example:

```java
public class OpportunityTriggerHandler extends TriggerHandler {

  public OpportunityTriggerHandler(SObjectType objectType) {
    super(objectType);
    this.setMaxLoopCount(1);
  }
  
  public override void afterUpdate() {
    List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Id IN :Trigger.newMap.keySet()];
    update opps; // this will throw after this update
  }

}
```

### Bypass API

What if you want to tell other trigger handlers to halt execution? That's easy with the bypass api:

```java
public class OpportunityTriggerHandler extends TriggerHandler {

  public OpportunityTriggerHandler(SObjectType objectType) {
    super(objectType);
  }
  
  public override void afterUpdate() {
    List<Opportunity> opps = [SELECT Id, AccountId FROM Opportunity WHERE Id IN :Trigger.newMap.keySet()];
    
    Account acc = [SELECT Id, Name FROM Account WHERE Id = :opps.get(0).AccountId];

    TriggerHandler.bypass('AccountTriggerHandler');

    acc.Name = 'No Trigger';
    update acc; // won't invoke the AccountTriggerHandler

    TriggerHandler.clearBypass('AccountTriggerHandler');

    acc.Name = 'With Trigger';
    update acc; // will invoke the AccountTriggerHandler

  }

}
```
If you need to check if a handler is bypassed, use the `isBypassed` method:

```java
if (TriggerHandler.isBypassed('AccountTriggerHandler')) {
  // ... do something if the Account trigger handler is bypassed!
}
```

If you want to clear all bypasses for the transaction, simple use the `clearAllBypasses` method, as in:

```java
// ... done with bypasses!

TriggerHandler.clearAllBypasses();

// ... now handlers won't be ignored!
```

### Trigger Deactivation
What if you would like to declaratively turn off your triggers in production without a deployment for a data migration? Follow these steps to deactivate your triggers:

* Create a custom metadata record of type `Trigger_Setting__mdt`
* Populate the Object API name field with the API Name of the Object for which you would like to bypass it triggers
* Check the `isInactive__c ` checkbox to deativate the trigger 

Note that if you do not make a custom metadata record that your trigger will not ever be bypassed via this logic.

## Overridable Methods

Here are all of the methods that you can override. All of the context possibilities are supported.

* `beforeInsert()`
* `beforeUpdate()`
* `beforeDelete()`
* `afterInsert()`
* `afterUpdate()`
* `afterDelete()`
* `afterUndelete()`
