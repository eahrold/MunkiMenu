### Technical Details 
Munki menu includes a helper app for accessing ManagedInstalls preferences that may exist in the root domain.  When using MunkiMenu to configure it writes to 
```
/var/root/Library/ManagedInstalls.plist.
```

It uses NSXPC to communicate between the main app and the helper app so this will only run on 10.8 or greater.

It's coded to use SMJobBless to install the helper app and by default will prompt the user for authorization as admin. 

## Building From Source
You need to have a code signing DeveloperID to build from source.  Make sure you set Both the App and Helper to use the same code signed ID.  It's currently setup to use the wildcard developerID so you may not neet to change anything. 

The HelperTool_CodeSign_RunScript.py should work to set up the configure the info.plist of both MunkiMenu and the helper tool, you may need to build once, clean and build again to insure it got the correct information.  If it doesn't work please [create an issue](https://github.com/eahrold/MunkiMenu/issues)

it uses the AHLaunchCtl framework, which is set up as a git submodule so to grab everything you'll need
```
git clone https://github.com/eahrold/MunkiMenu.git
cd MunkiMenu
git submodule update --init --recursive
``` 

## Location of Other Installed items
MunkiMenu uses a helper tool to to perform privileged operations, here are the locations of those components.

* MunkiMenu's app launcher launch agent 
	```
	/Library/LaunchAgents/com.googlecode.MunkiMenu.launcher.plist
	```  
* Helper tool executable is installed at 
```
/Library/PrivilegedHelperTools/com.googlecode.MunkiMenu.heper
```  
* Helper too's launched 
```
/Library/LaunchDaemons/com.googlecode.MunkiMenu.heper.plist
```