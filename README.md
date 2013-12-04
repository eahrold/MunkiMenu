## Introduction
MunkiMenu makes Managed Software Update easily accessible.  It lives in the status bar and is simply a wrapper for the MSU.app in the Utilities folder. 

When pressing the command key It also shows some at a glance information that is useful to administrators when trying to diagnose client misconfiguration. It also brings up the Quit item.

[Visit the Release Page](https://github.com/eahrold/MunkiMenu/releases)

----
### Technical Details 
Munki menu includes a helper app for accessing ManagedInstalls preferences that may exist in the root domain.  

It uses NSXPC to communicate between the main app and the helper app so this will only run on 10.8 or greater.

It uses SMJobBless to install the helper app so if building this yourself you will need to adjust the Code Signing components. Please refer to [https://developer.apple.com/library/mac/samplecode/SMJobBless/Listings/ReadMe_txt.html  Apple's SMJobBless example code]

however if you want to install this in a way that will not require user interaction (i.e using munki) you can do one of two things.  

1. Create a copy-file dmg with only the MunkiMenu.app and add this Post-Install script  to the munki pkginfo

```
#!/usr/bin/python
import subprocess

app_path = '/Applications/MunkiMenu.app'
helper_id = 'com.googlecode.MunkiMenu.helper'

def writeHelperLaunchD():
    import plistlib
    
    #write out the LaunchDaemon Plist
    launchd_file = '/Library/LaunchDaemons/'+helper_id+'.plist'
    
    mach_service = {helper_id:True}
    prog_args = ['/Library/PrivilegedHelperTools/'+helper_id ]
    
    launchd_plist = {'Label':helper_id,'MachServices':mach_service,'ProgramArguments':prog_args}
    plistlib.writePlist(launchd_plist,launchd_file )

    #fix the permissions 
    subprocess.call(['/usr/sbin/chown','root:wheel',launchd_file])
    subprocess.call(['/bin/chmod','0644',launchd_file])
    
    #load the launchD job
    subprocess.call(['/bin/launchctl','load',launchd_file])

def copyHelper():
    import shutil
    import os
    src = os.path.join(app_path,'Contents/Library/LaunchServices',helper_id)
    dst = os.path.join('/Library/PrivilegedHelperTools/',helper_id)
    shutil.copyfile(src, dst)
    
    subprocess.call(['/usr/sbin/chown','root:wheel',dst])
    subprocess.call(['/bin/chmod','544',dst])
    
def launchApp():
    from SystemConfiguration import SCDynamicStoreCopyConsoleUser
    from AppKit import NSWorkspace
    
    #if there is a logged in user launch MunkiMenu
    cfuser = SCDynamicStoreCopyConsoleUser( None, None, None )
    if cfuser[0]:
        wksp = NSWorkspace.sharedWorkspace()
        wksp.launchApplication_(app_path)
    
def main():
    writeHelperLaunchD()
    copyHelper()
    launchApp()
    
if __name__ == '__main__':
    main()
```

2. make a package that installs the launchD file and the helper tool and loads the launchD in it's postflight script, You can download this type of installer package, ready for deployment [https://github.com/eahrold/MunkiMenu/releases/download/1.1/MunkiMenu.dmg here.] 

### Other Info 
To uninstall the helper tool and associated files, click the option key while the menu is selected.
