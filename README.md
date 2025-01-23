#Build

Prerequisite:
1. need to install Go Lang

It is required to have an external build system for wireguard. To add it follow below steps:
1. Find Scripts/build_wireguard_go_bridge.sh inside TunnekKit package
2. Copy that file  somewhere in your project.
3. Open terminal in the directory in which the shell file reside. Make it executable by entering "chmod +x build_wireguard_go_bridge.sh" command in the terminal.                                                    
4. In Xcode, click File -> New -> Target. Switch to "Other" tab and choose "External Build System".
5. Type a name for your target.
6. Open the "Info" tab and replace /usr/bin/make with $(PROJECT_DIR)/path/to/build_wireguard_go_bridge.sh in "Build Tool".
7. Switch to "Build Settings" and find SDKROOT. Type in iphoneos if you target iOS.
8. Go to Wireguard tunnel extension target and switch to "Build Phases" tab.
9. Locate "Target Dependencies" section and hit "+" to add the external build target you have just created.
10. Repeat the process for each platform. (Optional)
