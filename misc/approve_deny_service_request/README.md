# Call previous method

We can call this method using the CF Rest API.


```
curl -X POST -u admin:smartvm -H "Content-type: application/json" -d '
{
    "version": "1.1",
    "uri_parts": {
        "namespace": "System",
        "class": "Request",
        "instance": "ApproveServiceRequest",
        "message": "create"
    },
    "parameters": {
        "request_id": "<request_id>",
        "reason": "This is the reason of the approval",
        "operation": "approve"
    },
    "requester": {
        "auto_approve": true
    }
}'  https://<cf_host>/api/automation_requests
```

The previous request creates an automate instance placed in /System/Request/ApproveServiceRequest
We could create that instance either using the API or the automate simulator
 
