/**
 * @description Class where we Execute the Scan
 */
global with sharing class globalCallsToQC {
    global globalCallsToQC() {

    } 

    /**
     * @description Deprecated method whitout the Manual variable
     */
    global boolean execute_scann(Instance__c instance, String gitBranch ){
       return null;
    }

    /**
     * @description New method whit the Manual variable
     */
    global boolean execute_scann(Instance__c instance, String gitBranch, Boolean manual){
      
        HttpRequest req = new HttpRequest();
        QualityCloudsApiSettings__c settings = ControllerHelperQC.getSettings();

        req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/feature-branch-scan');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', '*/*');
        req.setHeader('client-name', 'GenericHttpClient');
        req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
        
        //If manual is diferent than null send it in the body
        if(manual != null){
            req.setBody('{"data": {"type": "feature-branch-scan","attributes": {"url-id": ' + instance.ID__c + ',"scan-type": 5,"feature-branch": "' + gitBranch + '", "manual": ' + manual + '}}}');
        }else{
            req.setBody('{"data": {"type": "feature-branch-scan","attributes": {"url-id": ' + instance.ID__c + ',"scan-type": 5,"feature-branch": "' + gitBranch + '" }}}');
        }
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);

        if (res.getStatusCode() == 202){
            jsontoscan.Jsontoscan_c result =  jsontoscan.Jsontoscan_c.parse(res.getBody());
            String txt_date = result.data.attributes.scan_date.replace('T', ' ');
            txt_date = txt_date.substring(0, 19);
            Datetime scan_date = Datetime.valueOf(txt_date);
			if (Schema.sObjectType.Scann__c.isCreateable()){
               insert new Scann__c(Date__c = scan_date, State__c = result.data.attributes.status, ID__c = result.data.id, Scan_Type__c = result.data.type_Z, Branch_Name__c = gitBranch, Instance__c = instance.Id) ;
                return true;
            }else {
                throw new ControllerHelperQC.NoPermissionException('Current user does not have enough permissions to create Scann__c object.');
            }

        }
        return false;
    }

    /**
     * @description Update scan method
     */
     global boolean update_scanns(){        
        return true;
    }
}