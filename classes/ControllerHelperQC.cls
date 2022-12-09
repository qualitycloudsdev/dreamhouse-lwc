public with sharing class ControllerHelperQC {

    public class NoPermissionException extends Exception {}

    public static Boolean checkIfOrgConnected(){
        String currentOrgId = UserInfo.getOrganizationId();
        Integer orgInstances = [SELECT Count() FROM Instance__c WHERE Inst_Org_Id__c =: currentOrgId];
        return (orgInstances > 0) ? true : false;         
    }

    public static Boolean checkIfTokenValid (){
        QualityCloudsApiSettings__c settings = ControllerHelperQC.getSettings();
        if (settings.OAuth_expire_time__c != null && settings.OAuth_expire_time__c > System.now()) {
            return true;
        }
        return false;
    }
    
    public static QualityCloudsApiSettings__c getSettings(){
        PermissionChecker.exceptionIfNotAccessible(QualityCloudsApiSettings__c.getSObjectType());
        QualityCloudsApiSettings__c  settings;        
        if (settings == null ){
            try{
                settings = QualityCloudsApiSettings__c.getOrgDefaults(); 
            }catch (Exception e){
                System.debug(LoggingLevel.Error, e.getStackTraceString()); 
                settings = new QualityCloudsApiSettings__c();                
            }
        }
        return settings;
    }

    public static String generateRandomString(Integer stringLength, Boolean allCaps) {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        if (allCaps){
            chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        }
        String randStr = '';
        while (randStr.length() < stringLength) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    public static boolean updateScannsPolling(Integer pollsLeft){
        boolean done = true;
        Scann__c scan = [SELECT  State__c, ID__c, Scan_Type__c, CreatedDate, Id FROM Scann__c WHERE State__c = 'RUNNING' ORDER BY CreatedDate DESC LIMIT 1 ];
        if (pollsLeft < 1) {
            if (Schema.SObjectType.Scann__c.fields.State__c.isUpdateable()){
                scan.State__c = 'FAIL';                
            }else {
                throw new NoPermissionException('Current user does not have enough permissions to update Scann__c object or its State__c field.');
            }
            if (Schema.sObjectType.Scann__c.isUpdateable()) {
                update scan;
                System.debug('Scan failed. Polling limit reached.');
            }else {
                throw new NoPermissionException('Current user does not have enough permissions to update Scann__c object.');
            }
            return done;
        }
        System.debug('Polls left:' + pollsLeft);
            HttpRequest req = new HttpRequest();
            QualityCloudsApiSettings__c settings = getSettings();
            if (scan.Scan_Type__c == 'feature-branch-scan') {
                req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/feature-branch-scan/' + scan.ID__c);
            } else {
                req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/scan/' + scan.ID__c);
            }
            req.setMethod('GET');
            req.setHeader('Accept', '*/*');
            req.setHeader('client-name', 'GenericHttpClient');
            req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
            req.setTimeout(120000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            if (res.getStatusCode() == 200){
                jsontoscan.Jsontoscan_c result =  jsontoscan.Jsontoscan_c.parse(res.getBody());
                if (Schema.SObjectType.Scann__c.fields.State__c.isUpdateable()){
                   scan.State__c = result.data.attributes.status;
                }
                if (Schema.SObjectType.Scann__c.fields.Configuration_Elements__c.isUpdateable()){
                   scan.Configuration_Elements__c = result.data.attributes.scanned_configuration_elements;
                }
                if (Schema.SObjectType.Scann__c.fields.Technical_Debt_hours__c.isUpdateable()){
                   scan.Technical_Debt_hours__c = result.data.attributes.technical_debt;
                }
                if (Schema.SObjectType.Scann__c.fields.Quality_of_Cloud__c.isUpdateable()){
                   scan.Quality_of_Cloud__c = result.data.attributes.quality_of_cloud;
                }
                if (Schema.SObjectType.Scann__c.fields.Duration__c.isUpdateable()){
                   scan.Duration__c = result.data.attributes.process_time;
                }
                if (Schema.SObjectType.Scann__c.fields.Total_Issues__c.isUpdateable()){
                   scan.Total_Issues__c = result.data.attributes.number_of_issues;
                }
                if (Schema.SObjectType.Scann__c.fields.Quality_Gate_Result__c.isUpdateable()){
                   scan.Quality_Gate_Result__c = result.data.attributes.quality_gate_result;
                }
                if (Schema.SObjectType.Scann__c.fields.Quality_Gate_Message__c.isUpdateable()){
                    scan.Quality_Gate_Message__c = result.data.attributes.quality_gate_message; 
                }                

                String message_type_out = 'confirm';
                if (result.data.attributes.status == 'SUCCESS') {
                    Integer page = 1, total_pages = 1;
                    List<QCIssue__c> fetched_issues = new List<QCIssue__c>();
                    do {
                        HttpRequest req2 = new HttpRequest();
                        if (scan.Scan_Type__c == 'feature-branch-scan') {
                            req2.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/feature-branch-issue?filter[scan_uuid]=' + scan.ID__c + '&page[size]=1000&page[number]=' + page);
                            req2.setMethod('GET');
                            req2.setHeader('Accept', '*/*');
                            req2.setHeader('client-name', 'GenericHttpClient');
                            req2.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
                            req2.setTimeout(120000);
                            Http http2 = new Http();
                            HTTPResponse res2 = http2.send(req2);
                            if (res2.getStatusCode() == 200){

                                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res2.getBody());
                                Map<String, Object> meta_x = (Map<String, Object>) results.get('meta');
                                total_pages = (Integer) meta_x.get('last-page');
                                List< Object> data = (List<Object>) results.get('data');
                                for (Object d : data) {                                        
                                        QCIssue__c issue = ControllerHelperQC.jsonDataToIssue((map<String,Object>) d);
                                        issue.Scan__c = scan.id; 
                                        fetched_issues.add(issue);
                                }                               

                                message_type_out = 'confirm';

                            } else {
                                message_type_out = 'error';
                            }
                        } else {
                            //req2.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/issue?filter[scan]=' + scan.ID__c + '&page[size]=1000&page[number]=' + page);
                        }
                    } while (message_type_out != 'error' && page++ < total_pages);

                    if (Schema.sObjectType.Scann__c.isUpdateable() && Schema.sObjectType.Scann__c.isAccessible() && scan.Scan_Type__c == 'feature-branch-scan') {
                        scan.Total_Issues__c = fetched_issues.size();
                    }

                    if (checkIfUserCanUpsertQCIssue()) {
                        upsert fetched_issues ID__c;
                    } else {
                        throw new NoPermissionException('Current user does not have enough permissions to create/update QCIssue__c object or its fields.');
                    }
                }
                if (result.data.attributes.status == 'RUNNING'){
                    done = false;
                }

                if (Schema.sObjectType.Scann__c.isUpdateable()) {
                   update scan;
                }else {
                    throw new NoPermissionException('Current user does not have enough permissions to update Scann__c object.');
                }

            }else {
                done = false;
        }


        return done;
    } 
                    
    public static Datetime stringToDate(String dateStr){
        if (dateStr != null) {
            String txt_date2 = dateStr.replace('T', ' ');
            txt_date2 = txt_date2.substring(0, 19);
            return Datetime.valueOf(txt_date2);     
        }
        return null;
    }

    public static QCIssue__c jsonDataToIssue(map<String,Object> data){
        Map<String,Object> attributes = (map<String,Object>) data.get('attributes');
        
        QCIssue__c issue = new QCIssue__c();
        issue.Created_By__c = (String) attributes.get('created-by'); 
        issue.Updated_On__c = ControllerHelperQC.stringToDate((String) attributes.get('updated-on'));
        issue.Created_On__c = ControllerHelperQC.stringToDate((String) attributes.get('created-on'));
        issue.Updated_By__c =  (String) attributes.get('updated-by'); 
        issue.Severity__c = (String) attributes.get('severity'); 
        issue.Impact_Area__c = (String) attributes.get('impact-area'); 
        issue.Issue__c = (String) attributes.get('issue-type'); 
        issue.Line_Number__c = (Integer) attributes.get('line-number'); 
        issue.Link_to_Element__c = (String) attributes.get('affected-element-sys-id');
        issue.Element_Name__c = (String) attributes.get('affected-element-name'); 
        issue.Element_Type__c = (String) attributes.get('configuration-element-type'); 
        issue.ID__c = (String) data.get('id'); 
        issue.Documentation__c = (String) attributes.get('best-practice-link');
        issue.Baseline__c = (String) attributes.get('reference-status');

        map<String,Object> writeoffs = (map<String,Object>) attributes.get('write-off');
        String writeOffStatus = (String) writeoffs?.get('write-off-status');
        if (writeOffStatus == 'APPROVED') {
            issue.Write_off__c = true;
        } else {
            issue.Write_off__c = false;
        }
        issue.Write_Off_Requested_Date__c = ControllerHelperQC.stringToDate((String) writeoffs?.get('requested-date'));
        issue.Write_Off_Requester__c = (String) writeoffs?.get('requester');
        issue.Write_Off_Request_Reason__c = (String) writeoffs?.get('request-reason-nameid');
        issue.Write_Off_Request_Description__c = (String) writeoffs?.get('request-description');
        issue.Write_Off_Validation_Date__c = ControllerHelperQC.stringToDate((String) writeoffs?.get('validation-date'));
        issue.Write_Off_Validator__c = (String) writeoffs?.get('validator');
        issue.Write_Off_Validation_Reason__c = (String) writeoffs?.get('validation-reason');
        issue.Write_Off_Status__c = (String) writeoffs?.get('write-off-status');

        return issue;
    }

    public static Boolean checkIfUserCanUpsertQCIssue (){
        if (Schema.sObjectType.QCIssue__c.fields.Scan__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Scan__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Created_By__c.isCreateable() 
            && Schema.sObjectType.QCIssue__c.fields.Created_By__c.isUpdateable()  
            && Schema.sObjectType.QCIssue__c.fields.Updated_On__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Updated_On__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Created_On__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Created_On__c.isUpdateable()
            && Schema.sObjectType.QCIssue__c.fields.Updated_By__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Updated_By__c.isUpdateable()
            && Schema.sObjectType.QCIssue__c.fields.Severity__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Severity__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Impact_Area__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Impact_Area__c.isUpdateable()
            && Schema.sObjectType.QCIssue__c.fields.Issue__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Issue__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Line_Number__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Line_Number__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Link_to_Element__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Link_to_Element__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Element_Name__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Element_Name__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Element_Type__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Element_Type__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.ID__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.ID__c.isUpdateable()
            && Schema.sObjectType.QCIssue__c.fields.Documentation__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Documentation__c.isUpdateable()
            && Schema.sObjectType.QCIssue__c.fields.Baseline__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Baseline__c.isUpdateable()
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Requested_Date__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Requested_Date__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_off__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_off__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Requester__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Requester__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Request_Reason__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Request_Reason__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Request_Description__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Request_Description__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Validation_Date__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Validation_Date__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Validation_Reason__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Validation_Reason__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Validator__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Validator__c.isUpdateable() 
            && Schema.sObjectType.QCIssue__c.fields.Write_Off_Status__c.isCreateable() && Schema.sObjectType.QCIssue__c.fields.Write_Off_Status__c.isUpdateable()
        ) {
            return true;
        } else {
            return false;
        }
    }
}