##Installing with Munki

download the DMG from the [release page][releases] and run a munkiimport on it as you would with any munki package.  

Add an array with a single string of "none" (no quotes) to the "blocking_applications" key of the pkginfo.

Then add the following script items to MunkiMenu's pkginfo.  

_** if you plan to install MunkiMenu in a directory other than the Applications folder change the script accordingly **_

####Pre-Install

preinstall quits MunkiMenu and performs some clean up in order to proceed with installation.  
It also trys to fix any known previous release issues.

_*this is for the "preinstall_script" key in the pkginfo.plist_

```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --preinstall
```
_**the --preinstall function was first implemented in MunkiMenu v0.2.6 do not use this if upgrading from 0.2.5 or earlier it will cause managedsoftwareupdate to hang.  Use the [pre-install script found here][scripts]._


####Post-Install

postinstall copies the helper tool to the /Library/PrivilegedHelperTools/ folder,
registers it with LaunchD and creates an LaunchAgent to start MunkiMenu at login.

_*this is for the "postinstall_script" key in the pkginfo.plist_
```shell
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --postinstall
```
or if you do not want to have MunkiMenu automatically launch at login 
```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --postinstall-no-launch
```
####Pre-Uninstall
preuninstall unloads and removes helper tool, Unloads and uninstalls the application launcher  

_*this is for the "preuninstall_script" key in the pkginfo.plist_
```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --preuninstall
```
_**the --preuninstall function was first implemented in MunkiMenu v0.2.6 do not use this if uninstaling v0.2.5 or earlier it will
cause managedsoftwareupdate to hang use the [pre-uninstall script found here][scripts]_



#### Custom Script Example
If you prefere to custom script the pre/post install there are some examples 
in the [scripts directory][scripts]  at the project's root, written in pyton
  
#### Manual Uninstalling
To uninstall the helper tool and associated files, click the option key while the menu is selected, it will prompt for admin privilidges.

#### [Other Tech Notes][tech_notes]
[releases]:https://github.com/eahrold/MunkiMenu/releases
[scripts]:../Scripts
[tech_notes]:./technotes.md

