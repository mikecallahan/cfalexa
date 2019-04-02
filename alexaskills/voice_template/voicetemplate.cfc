<!--- 
	This is the starting point.  Set the endpoint in amazon developer dashboard to: 
	https://{your web address}/alexaskills/{foldername}/{filename containing your skill}.cfc?method=start  
	
	The start method resides up one folder level in cfalexa.cfc.  The "extends" 
	attribute below defines the location.  The ".cfc" is implied and therefore not 
	necessary to put at the end of cfalexa.  The use of "extends" allows this 
	component to inherit functions from the parent (cfalexa.cfc). 
--->


<cfcomponent extends="/alexaskills/cfalexa" >
	<!--- define your intents and function names here. 
	The AMAZON intents are required, DO NOT REMOVE. --->
	<!--- "{intent name}" = "{function name}" --->
	<cfset this.intents = {
		"exampleIntent"  = "exampleintent",
		"AMAZON.HelpIntent" = "Help",
		"AMAZON.CancelIntent" = "Cancel",
		"AMAZON.StopIntent" = "Stop",
		"AMAZON.FallbackIntent" = "Fallback",
		"AMAZON.RepeatIntent" = "Repeat",
		"AMAZON.StartOverIntent" = "Startover"
	}>

	<!--- replace the value of skillID with the applicationID of YOUR skill 
	from the developers portal.  Do not include the curly braces! --->
	<cfset this.skillID = "{put your skill id here}">

	<!--- launchRequest is required and does not need to be identified above, 
	DO NOT REMOVE --->
	<cffunction name="launchRequest" access="public" returntype="void">

        <!--- initialize your skill and set any session variables here --->
        <!--- example: <cfset setSessionVariable("name", "value")> --->
		
		<!--- what do you want Alexa to say when the skill is first launched --->
		<cfset say("Welcome to the alexa skill template for ColdFusion. 
		This template has one custom intent. Say, example, to activate the intent.")>
		
		<!---if the user is silent for more than 8 seconds, this is what Alexa will say --->
		<cfset reprompt("Please tell me what you would like to do.")>

		<!--- set title, text and images for the card in the Alexa phone app --->
		<!--- images need to have full URL path and must use https --->
		<cfset setTitle("Title for the card goes here")>
		<cfset setText("Text for the card goes here")>
		<cfset setImage("https://lorempixel.com/780/420/sports/","https://lorempixel.com/1200/800/technics/")>
	
	</cffunction>

	<!--- put your custom intents here --->
	<cffunction name="exampleintent" access="public" returntype="void">
        <!--- put your logic here.  things like queries, conditional logic, etc. --->
		<!--- you will probably have multiple intents and therefore multiple functions --->
		<cfset say("This is the example intent.  You can also say, stop, cancel, help, repeat, or start over, as those are all intents defaulted in the template.")>
        <cfset reprompt("This is the reprompt.  It will be read if the user fails to respond after 8 seconds.")>
	</cffunction>


	<!--- copy the below function template, insert your intent name and add your logic --->
	<!---
	<cffunction name="{your intent name}" access="public" returntype="void">
		<cfargument name="sessionInfo" required="yes">
		<!--- put your logic here --->
		<cfset say("This is the example intent.")>
        <cfset reprompt("This is the reprompt for my custom intent.  It will be read if the user fails to respond after 8 seconds.")>
	</cffunction>
	--->

	<!--- end of custom intents --->


    <!--- Help, Cancel and Stop intents are required, DO NOT REMOVE. change the text in say() and reprompt()to fit your skill --->

	<cffunction name="Help" access="public" returntype="void">
		<cfset say("Besides example, you can say, stop, cancel, help, repeat or start over, as those are all intents in the template.")>
		<cfset reprompt("You can also say, repeat.  Or say, start over, to begin a new session.")>
	</cffunction>

	<cffunction name="Cancel" access="public" returntype="void">
		<cfset say("Ok, we can stop.  Have a good day.")>
		<cfset endsession()>
	</cffunction>

	<cffunction name="Stop" access="public" returntype="void">
		<cfset say("Ok, talk to ya later.  Have a good day.")>
		<cfset endsession()>
	</cffunction>


	<!--- Fallback, Repeat and Startover are recommended intents for every skill --->

	<cffunction name="Fallback" access="public" returntype="void">
		<cfargument name="sessionData" required="yes">
		<cfset say("I didn't get that.  Let me repeat. ")>
		<cfset say(sessionData.lastresponse)>
		<cfset say("Or say, stop, to quit.")>
		<cfset reprompt("Say, help, if you want some hints to get you going.")>
	</cffunction>

	<cffunction name="Repeat" access="public" returntype="void">
		<cfargument name="sessionData" required="yes">
		<cfset say(sessionData.lastresponse)>
	</cffunction>

	<cffunction name="Startover" access="public" returntype="void">
		<cfargument name="sessionData" required="no">

		<cfset clearSession()>
		<cfset launchRequest()>
	</cffunction>

</cfcomponent>
