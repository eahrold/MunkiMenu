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
    launch_agent = bundle_id+'.launcher'

    copyHelper(helper_id,app_path)
    writeHelperLaunchD(helper_id)
    writeLaunchAgent(launch_agent,app_path)
    launchApp(app_path)

if __name__ == "__main__":
    main()
