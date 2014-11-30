##Installing with Munki

1. Download the [latest release of MunkiMenu][releases] and run a munkiimport on it as you would with any munki package.  

1. Add an array with a single string of `None` to the "blocking_applications" key of the `pkginfo.plist`.

1. Then add the following script items to MunkiMenu's `pkginfo.plist`.  

__Note:__ if you plan to install MunkiMenu in a directory other than the Applications folder change the following script accordingly.

## Pre-Install Script

Quits MunkiMenu and perform some clean up in order to proceed with installation. Try to fix any known previous release issues.

* `preinstall_script` key in the pkginfo.plist

	```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --preinstall
```

__Note:__ the `--preinstall` function was first implemented in MunkiMenu v0.2.6 do not use this if upgrading from 0.2.5 or earlier it will cause `managedsoftwareupdate` to hang.  Use the [pre-install script found here][scripts].

## Post-Install Script

Copy the helper tool to the /Library/PrivilegedHelperTools/ folder, registers it with launchd and create a LaunchAgent to start MunkiMenu at login.

* `postinstall_script` key in the pkginfo.plist  

	```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --postinstall
```
Or if you do not want to have MunkiMenu automatically launch at login 
```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --postinstall-no-launch
```

## Pre-Uninstall Script
Unload and remove the helper tool. Unload and uninstall the application launcher.

- `preuninstall_script` key in the pkginfo.plist

	```bash
#!/bin/bash
MM_APPLICATION="/Applications/MunkiMenu.app/Contents/MacOS/MunkiMenu"
[[ -x ${MM_APPLICATION} ]] && ${MM_APPLICATION} --preuninstall
```

__Note:__ the `--preuninstall` function was first implemented in MunkiMenu v0.2.6 do not use this if uninstaling v0.2.5 or earlier it will cause `managedsoftwareupdate` to hang. Use the [pre-uninstall script found here][scripts].



## Custom Script Example
If you prefere to custom script the pre/post install there are some examples 
in the [scripts directory][scripts]  at the project's root, written in pyton
  
## Manual Uninstalling
To uninstall the helper tool and associated files, click the option key while the menu is selected, it will prompt for admin privilidges.

--
### [Other Tech Notes][tech_notes]
[releases]:https://github.com/eahrold/MunkiMenu/releases
[scripts]:../Scripts
[tech_notes]:./technotes.md

