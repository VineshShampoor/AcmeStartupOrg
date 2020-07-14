@isTest
global class MockHttpResponseGenerator implements HttpCalloutMock {
    // Implement this interface method
    
    private String contentBody;
    public MockHttpResponseGenerator(String content)
    {
        contentBody = content;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        res.setBody(contentBody);
        res.setStatusCode(201);
        return res;
    }
}