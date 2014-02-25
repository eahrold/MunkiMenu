## Introduction
MunkiMenu makes Managed Software Update easily accessible.  It lives in the status bar and is simply a wrapper for the MSU.app in the Utilities folder. 

When pressing the command key It also shows some at a glance information that is useful to administrators when trying to diagnose client misconfiguration. It also brings up the Quit item.


[Visit the Release Page](https://github.com/eahrold/MunkiMenu/releases)

![default][default] Default  
![Command Key Pressed][commandKey] Command Key Pressed  
![Option Key Pressed][optionKey] Option Key Pressed  



### Technical Details 
Munki menu includes a helper app for accessing ManagedInstalls preferences that may exist in the root domain.  

It uses NSXPC to communicate between the main app and the helper app so this will only run on 10.8 or greater.

It's coded to use SMJobBless to install the helper app and by default will prompt the user for authorization as admin. 
However, if you want to install this in a way that will not require user interaction (i.e using munki) you can do one of two things.  

1. (Prefered) Create a copy-file dmg with only the MunkiMenu.app and add these Pre-Install and Post-Install script to the munki pkginfo.
    __Also you'll want to have a single item in blocking_applications array of the pkginfo.plist to "none"__

###Pre-Install
```python
#!/usr/bin/python

'''
Pre-Install Script for MunkiMenu or any other app
that has a global login managed by LaunchD.  It will quit the app
and attempt to unload the Launch Agent so installation can procede.
It assumes the launchd.plist file is in the form of the App's 
bundleID followed by a ".launcher" extension 
for example com.your.app.launcher.plist 
'''
##########################################################
########  Edit These Based on Installation ###############
##########################################################

app_name    = 'MunkiMenu'
install_dir = 'Applications'

##########################################################
########  End Editing ####################################
##########################################################

import os
import plistlib
import subprocess, signal

from SystemConfiguration import SCDynamicStoreCopyConsoleUser


def quitRunningApp(bundle_id):
    print("trying to quit MUM")
    p = subprocess.Popen(['ps', '-A'], stdout=subprocess.PIPE)
    out, err = p.communicate()    

    for line in out.splitlines():
        if app_name in line:
            pid = int(line.split(None, 1)[0])
            os.kill(pid, signal.SIGKILL)


def unloadJob(launcher):
    launch_plist = os.path.join('/Library','LaunchAgents',launcher)
        
    cfuser = SCDynamicStoreCopyConsoleUser( None, None, None )
    if cfuser[0]:
        os.seteuid(cfuser[1])
        print "unloading %s for %s" %  launch_plist,cfuser[0])
        try:
            subprocess.call(['/bin/launchctl','unload', launch_plist])
        except:
            pass

def getBundleID(app_path):
    info_plist = os.path.join(app_path,'Contents','Info.plist')
    p = plistlib.readPlist(info_plist)
    bundle_id = p['CFBundleIdentifier']
    return bundle_id
    
def main():
    app_path = os.path.join(install_dir,app_name+'.app')

    bundle_id = getBundleID(app_path)
    launcher = bundle_id+'.launcher'

    unloadJob(launcher)
    quitRunningApp(app_name)


if __name__ == "__main__":
    main()

```

###Post-Install
```python
#!/usr/bin/python

'''
Post Install Script to Install an app with embedded helper tool and register
the helper tool with LaunchD

'''

##########################################################
########  Edit These Based on Installation ###############
##########################################################

app_name    = 'MunkiMenu'
install_dir = 'Applications'

##########################################################
########  End Editing ####################################
##########################################################


import os
import subprocess
import shutil
import plistlib

from SystemConfiguration import SCDynamicStoreCopyConsoleUser
from AppKit import NSWorkspace

def writeLaunchAgent(launch_agent,app_path):
    #write out the LaunchDaemon Plist
    launchd_file = os.path.join('/Library','LaunchAgents',launch_agent+'.plist')

    prog_args = os.path.join(app_path,'Contents','MacOS',app_name
    )

    launchd_job = {'Label':launch_agent,
                    'Program':prog_args,
                    'RunAtLoad':True,
                    }
                    
    plistlib.writePlist(launchd_job,launchd_file )

    #fix the permissions 
    subprocess.call(['/usr/sbin/chown','root:wheel',launchd_file])
    subprocess.call(['/bin/chmod','0644',launchd_file])

def writeHelperLaunchD(helper_id):
    #write out the LaunchDaemon Plist
    launchd_file = os.path.join('/Library','LaunchDaemons',helper_id+'.plist')

    prog_args = [os.path.join('/Library','PrivilegedHelperTools',helper_id)]

    launchd_plist = {'Label':helper_id,
                     'MachServices':{helper_id:True},
                     'ProgramArguments':prog_args}

    plistlib.writePlist(launchd_plist,launchd_file)

    #fix the permissions 
    subprocess.call(['/usr/sbin/chown','root:wheel',launchd_file])
    subprocess.call(['/bin/chmod','0644',launchd_file])

    #load the launchD job
    subprocess.call(['/bin/launchctl','load',launchd_file])

def copyHelper(helper_id,app_path):
    src = os.path.join(app_path,'Contents','Library','LaunchServices',helper_id)

    dst = os.path.join('/Library/PrivilegedHelperTools/',helper_id)
    shutil.copyfile(src, dst)

    subprocess.call(['/usr/sbin/chown','root:wheel',dst])
    subprocess.call(['/bin/chmod','544',dst])

    ### try and kill the helper tool here in case it's still open
    subprocess.call(['/usr/bin/killall',helper_id])


def launchApp(app_path):
    #if there is a logged in user launch MunkiMenu
    cfuser = SCDynamicStoreCopyConsoleUser( None, None, None )
    if cfuser[0]:
        wksp = NSWorkspace.sharedWorkspace()
        wksp.launchApplication_(app_path)

def getBundleID(app_path):
    info_plist = os.path.join(app_path,'Contents','Info.plist')
    p = plistlib.readPlist(info_plist)
    bundle_id = p['CFBundleIdentifier']
    return bundle_id

def main():
    app_path = os.path.join('/',install_dir,app_name+'.app')

    bundle_id = getBundleID(app_path)
    helper_id = bundle_id+'.helper'
    launch_agent = bundle_id+'launcher'

    copyHelper(helper_id,app_path)
    writeHelperLaunchD(helper_id)
    writeLaunchAgent(launch_agent,app_path)
    launchApp(app_path)

if __name__ == "__main__":
    main()

 ```

2. make a package that includes the above code as a postflight script.

You can download either type on the [release page](https://github.com/eahrold/MunkiMenu/releases)

### Other Info 
To uninstall the helper tool and associated files, click the option key while the menu is selected, it will prompt for admin privilidges.

Also to remove the helper app using Munki, you'll want to add this as the Uninstall Scrip in the pkginfo
```python
#!/usr/bin/python
import subprocess
from os import remove

bundel_id = 'com.googlecode.MunkiMenu'

def removeHelperApp():
    helper_file = '/Library/PrivilegedHelperTools/'+helper_id
    try:
        remove(helper_file)
    except:
        print "helper app already removed"
        
def removeLaunchD():
    launchd_file = '/Library/LaunchDaemons/'+bundel_id+'.helper.plist'
    subprocess.call(['/bin/launchctl','unload',launchd_file])
    try:
        remove(launchd_file)
    except:
        print "Helper launchD file already removed"

def removeLauncher():
	launchd_file = '/Library/LaunchAgents/'+bundel_id+'.launcher.plist'
    try:
        remove(launchd_file)
    except:
        print "Launcher launchD file already removed"

def main():
    removeLaunchD()
    removeHelperApp()
    removeLauncher()


if __name__ == '__main__':
    main()
    
```


[default]:./docs/default.png
[commandKey]:./docs/commandKey.png
[optionKey]:./docs/optionKey.png
[examplePlist]:./docs/MunkiMenu-Example_Munki_Pkginfo.plist
