# edge-app-repeated-value-notification
Edge app for IoT Open with notification after consecutive values.

This app sends a notification when some function exceed a certain value for a number of consecutive times.

Example notification message.

```
Installation: {{.installation.Name}}
Value: {{.payload.value}}
Function: {{.payload.func.meta.name}}
Action: {{.payload.action}} (over or under)
```
.payload.func is the complete function object. 
