public with sharing class InstancesController {
    public String message_type_out{get;set;}
    public String message_out{get;set;}
    public String message{get;set;}
    public String message_type{get;set;}

    List<Instance__c> instances;
    QualityCloudsApiSettings__c settings;
    public String id_inst{get;set;}
    public boolean showPopup {get;set;}
    public String description {get;set;}
    final static String ORG_URL = URL.getSalesforceBaseUrl().toExternalForm();
    final static String ORG_ID =  UserInfo.getOrganizationId();
    final static String RS_NAME = 'This_ORG_Temp_URL';
    final static String RS_DESCRIPTION = 'Temporary Remote Setting required to use Metadata API from Apex'; 

    public InstancesController() {
        message = ApexPages.currentPage().getParameters().get('message');
        message_type = ApexPages.currentPage().getParameters().get('message_type');
        showPopup = false;
        description = '';
    }
    public QualityCloudsApiSettings__c getSettings(){        
        if (!Schema.sObjectType.QualityCloudsApiSettings__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'QualityCloudsApiSettings__c is not accessible for current user.'));
        } else if (settings == null ){
            try{
                settings = [SELECT username__c, API_Endpoint__c, API_Version__c, CallbackURL__c, OAuth_expire_time__c, OAuth_refresh_token__c, OAuth_refresh_token_2__c, OAuth_refresh_token_3__c, OAuth_refresh_token_4__c, OAuth_refresh_token_5__c, OAuth_token_2__c, OAuth_token_3__c, OAuth_token_4__c, OAuth_token_5__c, OAuth_token__c, password__c FROM QualityCloudsApiSettings__c LIMIT 1];
            }catch (QueryException e){
                settings = new QualityCloudsApiSettings__c();                
            }
        }
        return settings;
    }
    public List<Instance__c> getInstances(){
        if (!Schema.sObjectType.Instance__c.isAccessible()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Instance__c is not accessible for current user.'));
        } else if (instances == null) {
            instances = [SELECT url__c, Description__c, ID__c, Is_Featured_Banch__c FROM Instance__c ORDER BY CreatedDate DESC LIMIT 100];            
        }   
        return instances;
    }
    public PageReference updateInstances(){
        if (!Schema.sObjectType.Instance__c.isUpdateable() || !Schema.sObjectType.Instance__c.isCreateable()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Current user has no create/update permission for Instance__c object.'));
            return null;
        }
        HttpRequest req = new HttpRequest();
        settings = getSettings();
        req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/salesforce-instance');
        req.setMethod('GET');
        req.setHeader('Accept', '*/*');
        req.setHeader('client-name', 'Salesforce');
        req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 200){
            jsoninstancecontent.Jsoninstancecontent_c results =  jsoninstancecontent.Jsoninstancecontent_c.parse(res.getBody());
            List<Instance__c> fetched_instances = new List<Instance__c>();
            for (jsoninstancecontent.Data result : results.data) {
                	fetched_instances.add( new Instance__c(url__c=result.attributes.url, Description__c=result.attributes.description, Environment_Type__c=result.attributes.environment,ID__c=result.id, Instance_Type__c=result.attributes.service_name, Is_Featured_Banch__c=result.attributes.is_feature_branch, Inst_Org_Id__c=result.attributes.org_id));
            }
            if (fetched_instances?.isEmpty()){
                message_type_out = 'warning';
                message_out = 'No instances found on the Quality Clouds portal for this account.';                              
            } else {
                    upsert fetched_instances ID__c;
                    message_type_out = 'confirm';
                    message_out = 'Instances are imported/updated.';                
            }
        } else {
            message_type_out = 'error';
            message_out = res.getBody();
        }

        PageReference tempPage = new PageReference('/apex/instances');
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference openDetail(){
        PageReference tempPage = new PageReference('/apex/InstanceDetail');
        tempPage.getParameters().put('id', id_inst);
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference go_settings(){
        PageReference tempPage = new PageReference('/apex/OAuth');
        tempPage.setRedirect(true);
        return tempPage;
    }    
    public PageReference openPopup(){
        PageReference instUpdateResult =  updateInstances();
        if (instUpdateResult.getParameters().get('message_type') == 'error'){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, instUpdateResult.getParameters().get('message'))); 
            return null;
        }
        if (! ConnectedAppService.checkIfNoQCConnectedApp()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'QualityClouds connected app exists in this org. If you need help with configuring the app, please contact QualityClouds support.')); 
            return null;
        }

        if (ControllerHelperQC.checkIfOrgConnected()) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'The instance for current org ID exists already, but QualityClouds connected app not found. If you need help with configuring the app, please contact QualityClouds support.')); 
            return null;
        }

        showPopup = true;
        return null;
    }
    public PageReference connectOrgToPortal(){ 
        if (String.isBlank(description)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Please enter instance description.'));            
            return null;
        }

        try {            
            if ( ConnectedAppService.checkIfNoQCConnectedApp()) {
                ConnectedAppService.createRemoteSiteSetting( RS_NAME, RS_DESCRIPTION, ORG_URL);
                Map<String, String> keys = ConnectedAppService.createConnectedApp(settings.CallbackURL__c);
                if (!createPortalInstance(keys)){
                    ConnectedAppService.deleteConnectedApp('QualityClouds');
                    ConnectedAppService.deleteRemoteSiteSetting(RS_NAME);
                    message_type_out = 'error';
                    message_out = 'Error creating instance in the portal. QualityClouds connected app is deleted.';
                }else {
                    ConnectedAppService.deleteRemoteSiteSetting(RS_NAME);
                    updateInstances();
                    PageReference tempPage = new PageReference('/apex/instances');
                    tempPage.getParameters().put('message_type', 'confirm');
                    tempPage.getParameters().put('message', 'New instance "' + description + '" created on the portal. Please click "Refresh connection" to authorize the instance.');
                    tempPage.setRedirect(true);
                    return tempPage;
                }
            }else{
                message_type_out = 'info';
                message_out = 'QualityClouds connected app exists. If you need help with configuring the app, please contact QualityClouds support.';
            }        
        } catch (Exception e) {
            System.debug(LoggingLevel.Error, e.getStackTraceString()); 
            message_type_out = 'error';
            message_out = e.getMessage();
        }
        PageReference tempPage = new PageReference('/apex/instances');
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }    
    public PageReference Cancel(){
        showPopup = false;
        return null;
    }     

    public Boolean createPortalInstance(Map<String, String> keys){
        try {
            Map<String, Object> attributes = new Map<String, Object>();
            attributes.put('url', ORG_URL);
            attributes.put('description', description);
            attributes.put('login-url', ORG_URL);
            attributes.put('client-id', keys.get('consumKey'));
            attributes.put('client-secret', keys.get('consumSecret'));
            attributes.put('go-live', '');
            attributes.put('environment-id', 1);
            attributes.put('customer-id', 1);
            attributes.put('target', 'org');
            attributes.put('org-id', ORG_ID);

            Map<String, Object> data = new Map<String, Object>();
            data.put('type', 'salesforce-instance');
            data.put('attributes', attributes);
            Map<String, Object> jsonObj = new Map<String, Object>();
            jsonObj.put('data', data);
            String jsonStr = JSON.serialize(jsonObj);        
            HttpRequest req = new HttpRequest();
            QualityCloudsApiSettings__c settings = getSettings();
            req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/salesforce-instance');
            req.setMethod('POST');
            req.setHeader('Accept', 'application/vnd.api+json');
            req.setHeader('Content-Type', 'application/vnd.api+json');
            req.setHeader('client-name', 'Salesforce');
            req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
            req.setBody(jsonStr); 
            Http http = new Http();
            HTTPResponse res = http.send(req);
            if (res.getStatusCode() == 201){
                return true;
            } 
        } catch (Exception e) {
            System.debug(LoggingLevel.Error, e.getStackTraceString()); 
            System.debug('Error creating the instance on the portal: ' + e.getMessage());
            return false;            
        }
        return false;
    }

    public PageReference authorize(){
        HttpRequest req = new HttpRequest();
        QualityCloudsApiSettings__c settings = getSettings();
        req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/salesforce-instance/' + id_inst);
        req.setMethod('GET');
        req.setHeader('Accept', '*/*');
        req.setHeader('client-name', 'Salesforce');
        req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        String oauthURL;
        if (res.getStatusCode() == 200){
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> data = (Map<String, Object>) results.get('data');
            Map<String, Object> attributes = (Map<String, Object>) data.get('attributes');
            oauthURL = (String) attributes.get('salesforce-login-url');           
            PageReference tempPage = new PageReference(oauthURL?.replaceAll('&scope=api%20refresh_token',''));         
            tempPage.setRedirect(true);
            return tempPage;            
        }
        message_out = 'Error getting authorization URL. Please close this tab and get authorization token on Quality Clouds portal';    
        PageReference tempPage = new PageReference('/apex/instances');
        tempPage.getParameters().put('message_type', 'error');
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }

    public Boolean getCheckIfTokenValid (){       
        return ControllerHelperQC.checkIfTokenValid();
    }
}