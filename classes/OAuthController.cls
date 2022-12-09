public with sharing class OAuthController {

    QualityCloudsApiSettings__c settings;
    QualityCloudsSettings__mdt settings2;
    public boolean showPopup {get;set;}
    public String password {get;set;}
    public String username {get;set;}

    public OAuthController() {
        message = ApexPages.currentPage().getParameters().get('message');
        message_type = ApexPages.currentPage().getParameters().get('message_type');
        showPopup = false;
    }
    public String message_type_out{get;set;}
    public String message_out{get;set;}
    public String message{get;set;}
    public String message_type{get;set;}
    public QualityCloudsApiSettings__c getSettings(){
        if (settings == null && Schema.sObjectType.QualityCloudsApiSettings__c.isAccessible())
            try{
                settings = [SELECT  API_Endpoint__c, API_Version__c, OAuth_expire_time__c, OAuth_refresh_token__c, OAuth_refresh_token_2__c, OAuth_refresh_token_3__c, OAuth_refresh_token_4__c, OAuth_refresh_token_5__c, OAuth_token_2__c, OAuth_token_3__c, OAuth_token_4__c, OAuth_token_5__c, OAuth_token__c FROM QualityCloudsApiSettings__c LIMIT 1];
            }catch (QueryException e){
                settings = new QualityCloudsApiSettings__c();
            }
        return settings;
    }
    public QualityCloudsSettings__mdt getSettings2(){
        if (settings2 == null && Schema.sObjectType.QualityCloudsSettings__mdt.isAccessible())
            try{
                settings2 = [SELECT  client_secret__c, client_id__c FROM QualityCloudsSettings__mdt LIMIT 3];
            }catch (QueryException e){
                settings2 = new QualityCloudsSettings__mdt();
            }
        return settings2;
    }

    public PageReference save(){
        upsert settings;
        PageReference tempPage = new PageReference('/apex/OAuth');
        message_type_out = 'confirm';
        message_out = 'Settings updated';
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference refresh_token(){
        HttpRequest req = new HttpRequest();
        this.getSettings2();
        req.setEndpoint(settings.API_Endpoint__c + '/oauth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=refresh_token&client_id=' + settings2.client_id__c + '&client_secret=' + settings2.client_secret__c + '&scope=&refresh_token=' + (settings.OAuth_refresh_token__c != null ? settings.OAuth_refresh_token__c : '') + (settings.OAuth_refresh_token_2__c != null ? settings.OAuth_refresh_token_2__c : '') + (settings.OAuth_refresh_token_3__c != null ? settings.OAuth_refresh_token_3__c : '') + (settings.OAuth_refresh_token_4__c != null ? settings.OAuth_refresh_token_4__c : '') + (settings.OAuth_refresh_token_5__c != null ? settings.OAuth_refresh_token_5__c : ''));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 200){
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token__c.isUpdateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_2__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_3__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_4__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_5__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token__c.isCreateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_2__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_3__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_4__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_5__c.isCreateable()){

                settings.OAuth_token__c = string.valueOf(results.get('access_token')).mid(0,255);
                settings.OAuth_token_2__c = string.valueOf(results.get('access_token')).mid(255,255);
                settings.OAuth_token_3__c = string.valueOf(results.get('access_token')).mid(510,255);
                settings.OAuth_token_4__c = string.valueOf(results.get('access_token')).mid(765,255);
                settings.OAuth_token_5__c = string.valueOf(results.get('access_token')).mid(1020,255);
            }

            if (Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token__c.isUpdateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_2__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_3__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_4__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_5__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token__c.isCreateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_2__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_3__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_4__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_5__c.isCreateable()){

                settings.OAuth_refresh_token__c = string.valueOf(results.get('refresh_token')).mid(0,255);
                settings.OAuth_refresh_token_2__c = string.valueOf(results.get('refresh_token')).mid(255,255);
                settings.OAuth_refresh_token_3__c = string.valueOf(results.get('refresh_token')).mid(510,255);
                settings.OAuth_refresh_token_4__c = string.valueOf(results.get('refresh_token')).mid(765,255);
                settings.OAuth_refresh_token_5__c = string.valueOf(results.get('refresh_token')).mid(1020,255);
            }

            if (Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_expire_time__c.isUpdateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_expire_time__c.isCreateable()){
                settings.OAuth_expire_time__c = DateTime.newInstance(DateTime.now().getTime() + integer.valueOf(results.get('expires_in')) * 1000 );
            }

            if (Schema.sObjectType.QualityCloudsApiSettings__c.isUpdateable() && Schema.sObjectType.QualityCloudsApiSettings__c.isCreateable()) {
                upsert settings;
            } else {
                message_type_out = 'error at updating the settings';
            }

            message_type_out = 'confirm';
            message_out = 'Token refreshed';
        }else {
            message_type_out = 'error';
            message_out = res.getBody();
        }

        PageReference tempPage = new PageReference('/apex/OAuth');
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference get_token(){
        HttpRequest req = new HttpRequest();
        this.getSettings2();
        req.setEndpoint(settings.API_Endpoint__c + '/oauth/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		String codifiedUsername = EncodingUtil.urlEncode(username,'UTF-8');
		String codifiedPassword = EncodingUtil.urlEncode(password,'UTF-8');
        req.setBody('grant_type=password&client_id=' + settings2.client_id__c + '&client_secret=' + settings2.client_secret__c  + '&username=' + codifiedUsername  + '&password=' + codifiedPassword  + '&scope=');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 200){
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            if (Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token__c.isUpdateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_2__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_3__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_4__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_5__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token__c.isCreateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_2__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_3__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_4__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_token_5__c.isCreateable()){

                settings.OAuth_token__c = string.valueOf(results.get('access_token')).mid(0,255);
                settings.OAuth_token_2__c = string.valueOf(results.get('access_token')).mid(255,255);
                settings.OAuth_token_3__c = string.valueOf(results.get('access_token')).mid(510,255);
                settings.OAuth_token_4__c = string.valueOf(results.get('access_token')).mid(765,255);
                settings.OAuth_token_5__c = string.valueOf(results.get('access_token')).mid(1020,255);
            }

            if (Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token__c.isUpdateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_2__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_3__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_4__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_5__c.isUpdateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token__c.isCreateable() &&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_2__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_3__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_4__c.isCreateable()&&
               Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_refresh_token_5__c.isCreateable()){

                settings.OAuth_refresh_token__c = string.valueOf(results.get('refresh_token')).mid(0,255);
                settings.OAuth_refresh_token_2__c = string.valueOf(results.get('refresh_token')).mid(255,255);
                settings.OAuth_refresh_token_3__c = string.valueOf(results.get('refresh_token')).mid(510,255);
                settings.OAuth_refresh_token_4__c = string.valueOf(results.get('refresh_token')).mid(765,255);
                settings.OAuth_refresh_token_5__c = string.valueOf(results.get('refresh_token')).mid(1020,255);
            }

            if (Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_expire_time__c.isUpdateable() && Schema.SObjectType.QualityCloudsApiSettings__c.fields.OAuth_expire_time__c.isCreateable()){
                settings.OAuth_expire_time__c = DateTime.newInstance(DateTime.now().getTime() + (long)results.get('expires_in') * 1000 );
            }

            if (Schema.sObjectType.QualityCloudsApiSettings__c.isUpdateable() && Schema.sObjectType.QualityCloudsApiSettings__c.isCreateable()) {
                upsert settings;
            } else {
                message_type_out = 'error at updating the settings';
            }
            message_type_out = 'confirm';
            message_out = 'New token added';
        }else {
            message_type_out = 'error';
            message_out = res.getBody();
        }
        PageReference tempPage = new PageReference('/apex/OAuth');
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }

    public PageReference go_back(){
        PageReference tempPage = new PageReference('/apex/instances');
        tempPage.setRedirect(true);
        return tempPage;
    }

    public PageReference openPopup()
    {
        showPopup = true;
        return null;
    }

    public PageReference Cancel()
    {
        showPopup = false;
        return null;
    }
}