<!---
This is the engine that drives Amazon Alexa skill building with ColdFusion.  This file
handles the incoming JSON from Amazon and routes processing to your custom skills
functions.  It manages the proper JSON output formatting, maintains session variables
you want to track, stores the last response to be used for the "repeat" function,
manages info for cards (what gets displayed on the  mobile app and devices with screens),
and provides randomization functions for use in your skills to help keep things
from being static and routine.

Special thanks to Steve Drucker who created the original version of this file that
can be found at https://github.com/sdruckerfig/CF-Alexa/blob/master/Alexa.cfc.  
--->

<cfcomponent>

	<!--- retrieve the json packet that Amazon sent us --->
	<cfset this.jsonInput = deserializeJson(toString(getHttpRequestData().content))>
	
	<!--- create an output response template --->
	<cfsavecontent variable="this.responseTemplate">
		{
		  "version" : "1.0",
		  "sessionAttributes" : {},
		  "response" : {
		  	"outputSpeech" : {
		  	  "type" : "SSML",
		  	  "ssml" : ""
		  	},
		  	"card" : {
		  	  "type" : "Simple",
		  	  "title"  : "",
		  	  "content"  : ""
		  	},
		  	"reprompt" : {
		  		"outputSpeech" : {
		  		   "type" : "SSML",
		  		   "ssml" :  "<speak>For assistance, say, help.</speak>"
		  		}
		  	},
		  	"shouldEndSession" : false
		  }
		}
	</cfsavecontent>
	<!--- convert the output json into structures --->
	<cfset this.jsonOutput = deserializeJson(this.responseTemplate)>
	
	<!--- 
	This is the starting point.  Set the endpoint in amazon developer dashboard to: 
	https://{your web address}/cfalexa/{foldername}/{filename containing your skill}.cfc?method=start  
	Example: https://www.yoursite.com/alexaskills/voice-template/voicetemplate.cfc?method=start    
	--->
	<cffunction name="start" access="remote" returntype="struct" returnformat="json">
		<!--- pull in the json input packet sent from Alexa into a variable called jsonInput --->
		<cfset local.jsonInput = this.jsonInput>
		
		<!--- verify the request is coming from YOUR skill--->
		<cfif local.jsonInput.session.application.applicationid NOT EQUAL this.skillID>
			<cfset say("I'm sorry, the request is invalid.")>
			<cfset endsession()>
			<cfreturn getResponse()>
		</cfif>
		
		<!--- 
		pull session variables from the json input into this.jsonOutput.sessionAttributes 
		which will be used in the json output that is sent back to Alexa 
		--->		
		<cfif structkeyexists(local.jsonInput.session,"attributes")>	
			<cfloop collection="#local.jsonInput.session.attributes#" item="local.thisItem">
				<cfset setSessionVariable(local.thisItem,local.jsonInput.session.attributes[local.thisItem])>
			</cfloop>
		<cfelse>
			<cfset setSessionVariable("","")>
		</cfif>

		<!--- there are 3 primary types of requests: LaunchRequest, IntentRequest, SessionEndedRequest --->
   		<cfswitch expression="#local.jsonInput.request.type#">
			<cfcase value="LaunchRequest">
				
				<!--- run the launchRequest intent and send session variables --->
				<cfset launchRequest()>

				<!--- send a properly formated json response back to Alexa --->
				<cfreturn getResponse()>

			</cfcase>

   	  		<cfcase value="IntentRequest">
				 <!--- get the name of the intent from the request info sent by Alexa --->
				 <cfset local.methodName = local.jsonInput.request.intent.name>

				<!--- check to see if Alexa sent any slots --->
				<cfif structkeyexists(local.jsonInput.request.intent,"slots")>
					<cfset local.slots = local.jsonInput.request.intent.slots>
				</cfif>

				<!--- set target method name from this.intents --->
				<cfset cfcMethod = variables[this.intents[local.methodName]]>
				
				<!--- run the intent/method --->
				<cfif isDefined("local.jsonInput.session.attributes")>
					<cfif isDefined("local.slots")>
						<cfset cfcMethod(sessionData=local.jsonInput.session.attributes, slot=local.slots)>
					<cfelse>
						<cfset cfcMethod(sessionData=local.jsonInput.session.attributes)>
					</cfif>
				<cfelse>
					<cfif isDefined("local.slots")>
						<cfset cfcMethod(slot=local.slots)>
					<cfelse>
						<cfset cfcMethod()>
					</cfif>
				</cfif>
				<!--- send a properly formated json response back to Alexa --->
				<cfreturn getResponse()>	
			</cfcase>

			<!--- 
			If the skill session ends for any reason other than your code 
			closing the session. 
			--->
			<cfcase value="SessionEndedRequest">
				<cfreturn {}>
			</cfcase>
		</cfswitch>
	</cffunction>

	<!--- most used functions --->
	<cffunction name="say" access="public" returntype="void">
		<cfargument name="text" required="yes">
		<cfset this.jsonOutput.response.outputSpeech.ssml = this.jsonOutput.response.outputSpeech.ssml & arguments.text>
	</cffunction>

	<cffunction name="reprompt" access="public" returntype="void">
		<cfargument name="text" required="yes">
		<cfset this.jsonOutput.response.reprompt.outputSpeech.text =  arguments.text>
	</cffunction>

	<cffunction name="getResponse" access="public" returntype = "struct">
		<cfset local.jsonOutput = duplicate(this.jsonOutput)>

		<!--- automatically set the lastresponse which is used by the repeat intent --->
		<cfif this.jsonInput.request.type IS "LaunchRequest">
			<cfset local.jsonOutput.sessionAttributes["lastresponse"] = local.jsonOutput.response.outputSpeech.ssml>
		<cfelseif isDefined("this.jsonInput.request.intent.name") AND this.jsonInput.request.intent.name IS NOT "AMAZON.HelpIntent">
			<cfset local.jsonOutput.sessionAttributes["lastresponse"] = local.jsonOutput.response.outputSpeech.ssml>
		</cfif>

		<!--- automatically wrap the response with <speak> to always allow SSML. --->		
		<cfset local.jsonOutput.response.outputSpeech.ssml = "<speak>" & local.jsonOutput.response.outputSpeech.ssml & "</speak>">
		<cfreturn local.jsonOutput>
	</cffunction>

	<cffunction name="endSession" access="public" returntype="void">
		<cfset this.jsonOutput.response.shouldEndSession = true>
	</cffunction>

	<!--- for cards --->
	<cffunction name="setTitle" access="public" returntype="void">
		<cfargument name="title" required="yes">
		<cfset this.jsonOutput.response.card.title = arguments.title>
	</cffunction>

	<cffunction name="setText" access="public" returntype="void">
		<cfargument name="content" required="yes">
		<cfif structKeyExists(this.jsonOutput.response.card,"image")>
			<cfset this.jsonOutput.response.card.text = arguments.content>
		<cfelse>
			<cfset this.jsonOutput.response.card.content = arguments.content>
		</cfif>
	</cffunction>

	<cffunction name="setImage" access="public" returntype="void">
		<cfargument name="smallImageUrl" required="yes" hint="720w x 480h">
		<cfargument name="largeImageUrl" required="no" hint="1200w x 800h" default="">
		<cfset this.jsonOutput.response.card.type="Standard">
		<cfset this.jsonOutput.response.card["image"] = {"smallImageUrl" = arguments.smallImageUrl}>
		<cfif arguments.largeImageUrl is not "">
			<cfset this.jsonOutput.response.card["image"]["largeImageUrl"] = arguments.largeImageUrl>
		</cfif>
		<cfset this.jsonOutput.response.card["text"] = this.jsonOutput.response.card["content"]>
		<cfset structDelete(this.jsonOutput.response.card,"content")>
	</cffunction>

	<!--- for maintaining session --->
	<cffunction name="setSessionVariable" access="public" returntype="void">
		<cfargument name="key" type="string" required="yes">
		<cfargument name="value" type="string" reqired="yes">
		<cfset this.jsonOutput.sessionAttributes[arguments.key] = arguments.value>
	</cffunction>

	<cffunction name="clearSession" access="public" returntype="void">
		<cfset structClear(this.jsonOutput.sessionAttributes)>
	</cffunction>

	<!--- 
		random functions returns two things:
		randomItem.number - the random number that was selected
		randomItem.text - the text from the list corresponding to the random number
	--->
	<cffunction name="randomFromList" access="public" returntype="struct">
		<cfargument name="picklist" type="string" required="yes">
		<cfargument name="filterduplicates" type="string" required="no" default="no">

		<cfif arguments.filterduplicates IS "yes">
			<cfset isGood = 0>
			<cfif isDefined("this.jsonOutput.sessionAttributes.duplicatesinlist") AND listlen(arguments.picklist,";") EQUALS listlen(this.jsonOutput.sessionAttributes.duplicatesinlist)> 
				<cfset structDelete(this.jsonOutput.sessionAttributes,"duplicatesinlist")>
			</cfif>
			<cfloop condition = "isGood LESS THAN 1">
				<cfset randomItem.number=randRange(1,listlen(arguments.picklist,";"))>
				<cfif isDefined("this.jsonOutput.sessionAttributes.duplicatesinlist") and len(this.jsonOutput.sessionAttributes.duplicatesinlist)>
					<cfif listContains(this.jsonOutput.sessionAttributes.duplicatesinlist, "#randomItem.number#") IS "0">
						<cfset isGood = 1>
						<cfset setSessionVariable("duplicatesinlist","#listAppend(this.jsonOutput.sessionAttributes.duplicatesinlist,randomItem.number)#")>
					<cfelse>
						<cfset setSessionVariable("inlistcontains","loop again")>
					</cfif>
				<cfelse>
					<cfset isGood = 1>
					<cfset setSessionVariable("duplicatesinlist","#randomItem.number#")>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset randomItem.number=randRange(1,listlen(arguments.picklist,";"))>
		</cfif>
		<cfset randomItem.text=listGetAt(arguments.picklist,randomItem.number,";")>
		<cfreturn randomItem>
	</cffunction>

	<cffunction name="randomFromArray" access="public" returntype="struct">
		<cfargument name="picklist" type="array" required="yes">
		<cfargument name="filterduplicates" type="string" required="no" default="no">

		<cfif arguments.filterduplicates IS "yes">
			<cfset isGood = 0>
			<cfif isDefined("this.jsonOutput.sessionAttributes.duplicatesinarray") AND arraylen(arguments.picklist) EQUALS listlen(this.jsonOutput.sessionAttributes.duplicatesinarray)> 
				<cfset structDelete(this.jsonOutput.sessionAttributes,"duplicatesinarray")>
			</cfif>
			<cfloop condition = "isGood LESS THAN 1">
				<cfset randomItem.number=randRange(1,arraylen(arguments.picklist))>
				<cfif isDefined("this.jsonOutput.sessionAttributes.duplicatesinarray") and len(this.jsonOutput.sessionAttributes.duplicatesinarray)>
					<cfif listContains(this.jsonOutput.sessionAttributes.duplicatesinarray, "#randomItem.number#") IS "0">
						<cfset isGood = 1>
						<cfset setSessionVariable("duplicatesinarray","#listAppend(this.jsonOutput.sessionAttributes.duplicatesinarray,randomItem.number)#")>
					<cfelse>
						<cfset setSessionVariable("inlistcontains","loop again")>
					</cfif>
				<cfelse>
					<cfset isGood = 1>
					<cfset setSessionVariable("duplicatesinarray","#randomItem.number#")>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset randomItem.number=randRange(1,arraylen(arguments.picklist))>
		</cfif>
		<cfset randomItem.text=arguments.picklist[randomItem.number]>
		<cfreturn randomItem>
	</cffunction>

</cfcomponent>