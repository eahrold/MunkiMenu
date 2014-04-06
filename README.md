## Introduction
MunkiMenu makes Managed Software Update easily accessible.  It lives in the status bar and is simply a wrapper for the MSU.app in the Utilities folder. 

When pressing the command key It also shows some at a glance information that is useful to administrators when trying to diagnose client misconfiguration. It also brings up the Quit item.


[Visit the Release Page](https://github.com/eahrold/MunkiMenu/releases)

![default][default] Default  
![Command Key Pressed][commandKey] Command Key Pressed  
![Option Key Pressed][optionKey] Option Key Pressed  


### Technical Details 
Munki menu includes a helper app for accessing ManagedInstalls preferences that may exist in the root domain.  When using MunkiMenu to configure it writes to /var/root/Library/ManagedInstalls.plist.

It uses NSXPC to communicate between the main app and the helper app so this will only run on 10.8 or greater.

It's coded to use SMJobBless to install the helper app and by default will prompt the user for authorization as admin. 

However, if you want to install MunkiMenu in a way that will not require user interaction (i.e using munki) you should create a copy-file dmg with only the MunkiMenu.app then add these Pre-Install, Post-Install and Pre-Uninstall script to the pkginfo.  

__Also you'll want to have a single string in blocking_applications array if "none" (no quotes)__

####Pre-Install
preinstall quits MunkiMenu and dose some clean up in order to proceed with installation.  It also fixes possible previous release issues.
```shell
#!/bin/bash
PRE_INSTALL="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${PRE_INSTALL} ]] && ${PRE_INSTALL} --preinstall
```

####Post-Install
postinstall copies the helper tool to the /Library/PrivilegedHelperTools/ folder,
registers it with LaunchD and creates an application launcher launchd.plist to start MunkiMenu at login.  

_ *note It uses the same SMJobBless mechanism as the GUI to insure that the applicaiton is properly codesigned which could potentially affect communication with the helper tool._
```shell
#!/bin/bash
POST_INSTALL="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${POST_INSTALL} ]] && ${POST_INSTALL} --postinstall
```
or if you do not want to have MunkiMenu automatically launch at login 
```
#!/bin/bash
POST_INSTALL="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${POST_INSTALL} ]] && ${POST_INSTALL} --postinstall-no-launch
```
####Pre-Uninstall
preuninstall unloads and removes helper tool, Unloads and uninstalls lpplication launcher
```shell
#!/bin/bash
PRE_UNINSTALL="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${PRE_UNINSTALL} ]] && ${PRE_UNINSTALL} --preuninstall
```

If you prefere to custom script the pre/post install there are some examples 
in the [scripts directory][scripts]  at the project's root, written in pyton
  
#### Manual Uninstalling
To uninstall the helper tool and associated files, click the option key while the menu is selected, it will prompt for admin privilidges.



[default]:./docs/default.png
[commandKey]:./docs/commandKey.png
[optionKey]:./docs/optionKey.png
[scripts]:./Scripts