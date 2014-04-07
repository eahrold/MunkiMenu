## Introduction
MunkiMenu makes Managed Software Update easily accessible.  It lives in the status bar and is simply a wrapper for the MSU.app in the Utilities folder. 

When pressing the command key It also shows some at a glance information that is useful to administrators when trying to diagnose client misconfiguration. It also brings up the Quit item.


[Visit the Release Page][releases]

![default][default] Default  
![Command Key Pressed][commandKey] Command Key Pressed  
![Option Key Pressed][optionKey] Option Key Pressed  


### Technical Details 
Munki menu includes a helper app for accessing ManagedInstalls preferences that may exist in the root domain.  When using MunkiMenu to configure it writes to /var/root/Library/ManagedInstalls.plist.

It uses NSXPC to communicate between the main app and the helper app so this will only run on 10.8 or greater.

It's coded to use SMJobBless to install the helper app and by default will prompt the user for authorization as admin. 

However, if you want to install MunkiMenu in a way that will not require user interaction (i.e using munki) you can create a copy-file dmg, or use the one avaliable on the [Release Page][releases], then add these Pre-Install, Post-Install and Pre-Uninstall script to the munki pkginfo.  

__Also you'll want to have a single string in blocking_applications array set as "none" (no quotes)__


### THESE ARE NOT CURRENTLY WORKING BUT WILL SHROTLY
#### USE THE SCRIPTS LOCATED [HERE][scripts] UNTIL V0.2.6

####Pre-Install
preinstall quits MunkiMenu and dose some clean up in order to proceed with installation.  
It also fixes possible previous release issues.

_*!! this preinstall script is first implemented in v0.2.5 do not use this if upgrading from 0.2.4 or earlier it will
cause the ManagedSoftwareUpdate to hang. use the [pre-install script found here][scripts] (this has no effect on the post-install script)_
```shell
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --preinstall
```

####Post-Install
postinstall copies the helper tool to the /Library/PrivilegedHelperTools/ folder,
registers it with LaunchD and creates an application launcher launchd.plist to start MunkiMenu at login.

_*note It uses the same SMJobBless mechanism as the GUI to insure that the applicaiton is properly codesigned which, if not, could potentially affect communication with the helper tool._
```shell
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --postinstall
```
or if you do not want to have MunkiMenu automatically launch at login 
```
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --postinstall-no-launch
```
####Pre-Uninstall
preuninstall unloads and removes helper tool, Unloads and uninstalls the application launcher  

_*this preuninstall script is first implemented in v0.2.5 do not use this if uninstaling 0.2.4 or earlier it will
cause the application to hang use the [pre-install script found here][scripts]_
```shell
#!/bin/bash

MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --preuninstall
```

#### Custom Script Example
If you prefere to custom script the pre/post install there are some examples 
in the [scripts directory][scripts]  at the project's root, written in pyton
  
#### Manual Uninstalling
To uninstall the helper tool and associated files, click the option key while the menu is selected, it will prompt for admin privilidges.



[default]:./docs/default.png
[commandKey]:./docs/commandKey.png
[optionKey]:./docs/optionKey.png
[scripts]:./Scripts
[releases]:https://github.com/eahrold/MunkiMenu/releases
