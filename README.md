# edge-app-repeated-value-notification
Edge app for IoT Open with notification after consecutive values.

This app sends a notification when some function exceed a certain value for a number of consecutive times.

Example notification message.

```
Installation: {{.installation.Name}}
Device: {{.payload.device.meta.name}}
Function: {{.payload.func.meta.name}}
Value: {{.payload.value}}
Action: {{.payload.action}} (over or under)
```
.payload.func  and payload.device are the complete function and device objects. 
