public with sharing class instanceDetailController {

    public instanceDetailController() {
        message = ApexPages.currentPage().getParameters().get('message');
        message_type = ApexPages.currentPage().getParameters().get('message_type');
    }
    public String message_type_out{get;set;}
    public String message_out{get;set;}
    public String message{get;set;}
    public String message_type{get;set;}
    public String id_instance = ApexPages.currentPage().getParameters().get('id');

    public String git_branch {get;set;}

    public String id_scan{get;set;}

    Instance__c instance;
    List<Scann__c> scanns;
    QualityCloudsApiSettings__c settings;
    List<QCIssue__c> fetched_issues = new List<QCIssue__c>();

    public QualityCloudsApiSettings__c getSettings(){
        if (settings == null && Schema.sObjectType.QualityCloudsApiSettings__c.isAccessible())
            try{
                settings = [SELECT username__c, API_Endpoint__c, API_Version__c, OAuth_expire_time__c, OAuth_refresh_token__c, OAuth_refresh_token_2__c, OAuth_refresh_token_3__c, OAuth_refresh_token_4__c, OAuth_refresh_token_5__c, OAuth_token_2__c, OAuth_token_3__c, OAuth_token_4__c, OAuth_token_5__c, OAuth_token__c, password__c FROM QualityCloudsApiSettings__c LIMIT 1];
            }catch (QueryException e){
                settings = new QualityCloudsApiSettings__c();
            }
        return settings;
    }
    public String getId_instance(){
        return id_instance;
    }
    public Instance__c getInstance(){
        if (instance == null && Schema.sObjectType.Instance__c.isAccessible())
            instance = [SELECT url__c, Description__c, ID__c, Environment_Type__c, Instance_Type__c, Is_Featured_Banch__c, Id FROM Instance__c WHERE ID__c = :id_instance ORDER BY CreatedDate DESC];
        return instance;
    }
    public List<Scann__c> getScanns(){
        if (scanns == null && Schema.sObjectType.Scann__c.isAccessible()){
            this.getInstance();
            scanns = [SELECT Date__c, State__c, ID__c, Scan_Type__c, Branch_Name__c, Id 
                        FROM Scann__c 
                        WHERE Instance__c = :instance.id 
                        ORDER BY CreatedDate DESC 
                        LIMIT 999];
        }
        return scanns;
    }
    public PageReference execute_scann(){
        HttpRequest req = new HttpRequest();
        this.getSettings();
        req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/feature-branch-scan');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', '*/*');
        req.setHeader('client-name', 'GenericHttpClient');
        req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
        req.setBody('{"data": {"type": "feature-branch-scan","attributes": {"url-id": ' + instance.ID__c + ',"scan-type": 5,"feature-branch": "' + git_branch + '"}}}');
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 202){
            jsontoscan.Jsontoscan_c result =  jsontoscan.Jsontoscan_c.parse(res.getBody());
            String txt_date = result.data.attributes.scan_date.replace('T', ' ');
            txt_date = txt_date.substring(0, 19);
            Datetime scan_date = Datetime.valueOf(txt_date);
			if (Schema.sObjectType.Scann__c.isCreateable()){
               insert new Scann__c(Date__c = scan_date, State__c = result.data.attributes.status, ID__c = result.data.id, Scan_Type__c = result.data.type_Z, Branch_Name__c = git_branch, Instance__c = instance.Id) ;
            }
            message_type_out = 'confirm';
            message_out = 'Scan launched';
        }else {
            message_type_out = 'error';
            message_out = res.getBody();
        }
        PageReference tempPage = ApexPages.currentPage();
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference execute_scann_full(){
        HttpRequest req = new HttpRequest();
        this.getSettings();
        req.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/scan');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/vnd.api+json');
        req.setHeader('Accept', '*/*');
        req.setHeader('client-name', 'GenericHttpClient');
        req.setHeader('Authorization', 'Bearer '+ (settings.OAuth_token__c != null ? settings.OAuth_token__c : '') + (settings.OAuth_token_2__c != null ? settings.OAuth_token_2__c : '') + (settings.OAuth_token_3__c != null ? settings.OAuth_token_3__c : '') + (settings.OAuth_token_4__c != null ? settings.OAuth_token_4__c : '') + (settings.OAuth_token_5__c != null ? settings.OAuth_token_5__c : ''));
        req.setBody('{"data": {"type": "scan","attributes": {"url-id": ' + instance.ID__c + ',"scan-type": 0}}}');
        req.setTimeout(120000);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if (res.getStatusCode() == 202){
            jsontoscan.Jsontoscan_c result =  jsontoscan.Jsontoscan_c.parse(res.getBody());
            String txt_date = result.data.attributes.scan_date.replace('T', ' ');
            txt_date = txt_date.substring(0, 19);
            Datetime scan_date = Datetime.valueOf(txt_date);
			if (Schema.sObjectType.Scann__c.isCreateable()){
               insert new Scann__c(Date__c = scan_date, State__c = result.data.attributes.status, ID__c = result.data.id, Scan_Type__c = result.data.type_Z, Instance__c = instance.Id) ;
            }
            message_type_out = 'confirm';
            message_out = 'Scan launched';
        }else {
            message_type_out = 'error';
            message_out = res.getBody();
        }
        PageReference tempPage = ApexPages.currentPage();
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference update_scanns(){
        Scann__c scan = [SELECT  State__c, ID__c, Scan_Type__c, Id FROM Scann__c WHERE ID__c = :id_scan ];
        if (scan.State__c == 'RUNNING'){
            HttpRequest req = new HttpRequest();
            this.getSettings();
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
                
                message_type_out = 'confirm';
                message_out = 'Scan status updated';
                if (result.data.attributes.status == 'SUCCESS') {
                    Integer page = 1, total_pages = 1;
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
                                message_out = 'Scan status updated and issues imported';

                            } else {
                                message_type_out = 'error';
                                message_out = res2.getBody();
                            }
                        } else {
                            //req2.setEndpoint(settings.API_Endpoint__c + '/api/'  + settings.API_Version__c + '/issue?filter[scan]=' + scan.ID__c + '&page[size]=1000&page[number]=' + page);
                        }
                    } while (message_type_out != 'error' && page++ < total_pages);
                    
                    if (Schema.sObjectType.Scann__c.isUpdateable() && Schema.sObjectType.Scann__c.isAccessible() && scan.Scan_Type__c == 'feature-branch-scan') {
                        scan.Total_Issues__c = fetched_issues.size();
                    }
                    
                    if (ControllerHelperQC.checkIfUserCanUpsertQCIssue()) {
                        upsert fetched_issues ID__c;
                    } else {
                        message_type_out = 'error'; 
                        message_out = 'error at updating the list of issues';
                    } 
                }
                
                if (Schema.sObjectType.Scann__c.isUpdateable()) {
                   update scan;
                } else {
                    message_type_out = 'error'; 
                    message_out = 'error at updating the Scan object'; 
                }
                
            }else {
            message_type_out = 'error';
            message_out = res.getBody();
        }
        }
        PageReference tempPage = ApexPages.currentPage();
        tempPage.getParameters().put('message_type', message_type_out);
        tempPage.getParameters().put('message', message_out);
        tempPage.setRedirect(true);
        return tempPage;
    }

    public PageReference go_back(){
        PageReference tempPage = new PageReference('/apex/Instances');
        tempPage.setRedirect(true);
        return tempPage;
    }
    public PageReference openDetail(){
        PageReference tempPage = new PageReference('/apex/ScanDetail');
        tempPage.getParameters().put('id', id_scan);
        tempPage.getParameters().put('id_instance', id_instance);
        tempPage.setRedirect(true);
        return tempPage;
    }
}