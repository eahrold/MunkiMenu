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