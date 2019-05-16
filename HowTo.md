# How To Write your own modules.

Writing your own tracking module can be done in a few easy steps.

First thing to do is to determine what you want to track.
Then figure out how to capture the data, and how to store the data.
Should it be

* Create a new LUA file.
* Write a function to be called to init the data.
	- Either to init the data structure
	- Or to call code after VARIABLES_LOADED event is fired.
	- The data should be stored in the table ```Rested.me```
* Assign the function to the InitCallback
	- ```Rested.InitCallback( Rested.<FunctionName> )```
* Write a function to update the data. This can be called at events
* Assign the update function to an event
	- ```Rested.EventCallback( "EVENT", Rested.<FunctionName> )```
	- Note that the callback function will be given all of the event payload
* Write a function to create reminders
	- The function will be given 3 parameters ( realm, name, struct )
	- struct is the table where all the gathered data for realm-name has been stored
	- For each struct returned, return a table:
		```{ [timestamp] = { "msg1", "msg2", "msg3"}, [timestamp2] = { "msg4"}. ...}```
	- reminder messages will be posted once the timestamp key has passed
* Register the function to be called for creating reminders
	- ```Rested.ReminderCallback( Rested.<functionName> )```
* Write a function to show a report.
	- The function will be called for each character tracked
	- The function will be given ( realm, name, charStruct )
		- realm and name can be concatinated and colored using ```rn = Rested.FormatName( realm, name )```
	- Use the data to format a report line, and caluculate a sort value.
		- The sort value will also be used to show the length of the bar
		- The sort value should be between 0 and 150, inclusive.
		- It is probably best to put the realm-name at the right side of the report line
	- Insert the contents of the sort value, and report string to the table ```Rested.charList```
		- ```table.insert( Rested.charList( { sortValue, report_str } ) )```
	- Return 1 if a line is inserted
	- Return 0 or nil if no line is inserted
* Create a command to show the report.
	- Assign the command to ```Rested.commandList```, providing help strings, and a command function to call.
	- report functions should set ```Rested.reportName``` to a name, and pass the report function name to ```Rested.UIShowReport()```
		- ```Rested.commandList["commandName"] = {["help"] = {"<optional paremter>","<help string>"}, ["func"] = function() Rested.reportName = "<name>"; Rested.UIShowReport( <reportFunction> ); end }```
