public with sharing class IssueDetailController {

    public IssueDetailController() {
        message = ApexPages.currentPage().getParameters().get('message');
        message_type = ApexPages.currentPage().getParameters().get('message_type');
    }

    public String message_type_out{get;set;}
    public String message_out{get;set;}
    public String message{get;set;}
    public String message_type{get;set;}
    public String id_issue = ApexPages.currentPage().getParameters().get('id');
    public String id_scan = ApexPages.currentPage().getParameters().get('id_scan');
    public String id_instance = ApexPages.currentPage().getParameters().get('id_instance');

    QCIssue__c issue;


    public String getId_issue(){
        return id_issue;
    }
    public QCIssue__c getIssue(){
        if (issue == null && Schema.sObjectType.QCIssue__c.isAccessible())
            issue = [SELECT Created_By__c, 
                            Created_On__c, 
                            Element_Name__c, 
                            Link_to_Element__c, 
                            Documentation__c, 
                            Element_Type__c, 
                            ID__c, 
                            Impact_Area__c, 
                            Issue__c, 
                            Line_Number__c, 
                            Link__c, 
                            Scan__c, 
                            Severity__c, 
                            Updated_By__c, 
                            Updated_On__c, 
                            Id, 
                            Baseline__c,
                            Write_off__c,
                            Write_Off_Requested_Date__c,
                            Write_Off_Requester__c,
                            Write_Off_Request_Reason__c, 
                            Write_Off_Request_Description__c,
                            Write_Off_Validation_Date__c,
                            Write_Off_Validation_Reason__c,
                            Write_Off_Validator__c,
                            Write_off_Status__c
                    FROM QCIssue__c 
                    WHERE ID__c = :id_issue 
                    ORDER BY CreatedDate DESC];
        return issue;
    }


    public PageReference go_back(){
        PageReference tempPage = new PageReference('/apex/ScanDetail');
        tempPage.getParameters().put('id', id_scan);
        tempPage.getParameters().put('id_instance', id_instance);
        tempPage.setRedirect(true);
        return tempPage;
    }
}