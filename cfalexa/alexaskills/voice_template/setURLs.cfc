component {

	public void function run() {
		tPath = GetDirectoryFromPath(GetCurrentTemplatePath());
		
		//  open share.txt, find the url and set to a variable
		sharelocation = replaceNoCase("#tPath#", "alexaskills/voice_template/", "");
		sharecontent = fileRead("#sharelocation#share.txt");
		tStart = find("https://",sharecontent);
		tEnd = find(".io",sharecontent);
		ngrokurl = mid(sharecontent, tStart, tEnd-tStart+3);
		
		//  open .ask/config, get skillID, and then find location of url and replace ngrokurl  
		configcontent = fileRead("#tPath#.ask/config");
		tStart = find("https://",configcontent);
		if (tStart GT 0) {
			tEnd = find("/alexa",configcontent);
			replacethis = mid(configcontent, tStart, tEnd-tStart);
			newfile = replacenocase(configcontent,replacethis,ngrokurl);
		}
		else {
			newfile = replacenocase(configcontent,"ask-custom-cfalexa-default",ngrokurl & "/alexaskills/voice_template/voicetemplate.cfc?method=start");
		}
		
		fileWrite("#tPath#.ask/config", newfile);

		//  open skill.json, find location of url and replace with ngrokurl 
		shareurl = fileRead("#tPath#skill.json");
		tStart = find("https://",shareurl);
		tEnd = find("/alexa",shareurl);
		replacethis = mid(shareurl, tStart, tEnd-tStart);
		newfile1 = replacenocase(shareurl,replacethis,ngrokurl);
		newfile = replacenocase(newfile1,'"cfalexa",', '"voicetemplate",');
		fileWrite("#tPath#skill.json", newfile);

	}
}
