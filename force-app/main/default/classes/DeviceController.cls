public with sharing class DeviceController {
    @AuraEnabled(cacheable=true)
    public static List<Device__c> getDevices() {
        return [SELECT Id, Name, Type__c, SerialNumber__c, InstallationDate__c FROM Device__c];
    }
}