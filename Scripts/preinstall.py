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
bundle_id   = 'com.googlecode.MunkiMenu'
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
        print "unloading %s for %s" %  (launch_plist,cfuser[0])
        try:
            subprocess.call(['/bin/launchctl','unload', launch_plist])
        except:
            pass


def main():
    app_path = os.path.join(install_dir,app_name+'.app')

    launcher = bundle_id+'.launcher'

    unloadJob(launcher)
    quitRunningApp(app_name)


if __name__ == "__main__":
    main()
