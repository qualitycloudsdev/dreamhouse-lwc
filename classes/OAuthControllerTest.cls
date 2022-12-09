@isTest
class OAuthControllerTest {
    @isTest
    static void testSave() {
        OAuthController oAuth = new OAuthController();
        oAuth.getSettings();
        PageReference page = oAuth.save();
        System.assertEquals('Settings updated', oAuth.message_out);
        System.assertEquals('confirm', oAuth.message_type_out);

    }
    @isTest
    static void testGetTokenOK() {
        OAuthController oAuth = new OAuthController();
        oAuth.getSettings();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('authtokenok');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
		oAuth.username = 'user';
        oAuth.password = 'pass';
        oAuth.get_token();

        System.assertEquals('New token added', oAuth.message_out);
        System.assertEquals('confirm', oAuth.message_type_out);
    }
    @isTest
    static void testGetTokenError() {
        OAuthController oAuth = new OAuthController();
        oAuth.getSettings();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('authtokenerror');
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
		oAuth.username = 'user';
        oAuth.password = 'pass';
        oAuth.get_token();

        System.assertEquals('error', oAuth.message_type_out);
    }
    @isTest
    static void testRefreshTokenOK() {
        OAuthController oAuth = new OAuthController();
        oAuth.getSettings();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('authtokenrok');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        oAuth.refresh_token();

        System.assertEquals('Token refreshed', oAuth.message_out);
        System.assertEquals('confirm', oAuth.message_type_out);
    }
    @isTest
    static void testRefreshTokenError() {
        OAuthController oAuth = new OAuthController();
        oAuth.getSettings();
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('authtokenrerror');
        mock.setStatusCode(401);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        oAuth.refresh_token();

        System.assertEquals('error', oAuth.message_type_out);
    }
}