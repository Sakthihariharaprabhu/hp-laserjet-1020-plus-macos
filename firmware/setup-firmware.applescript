-- HP LaserJet 1020 Plus helper app: firmware setup, status, alignment and removal.
-- Everything a user needs is here so nobody has to open Terminal.
property projectURL : "https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos"
property firmwareHelpURL : "https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos#get-the-firmware-file"
property alignmentHelpURL : "https://github.com/Sakthihariharaprabhu/hp-laserjet-1020-plus-macos#page-is-shifted-or-cut-off"
property appTitle : "HP LaserJet 1020 Plus"

on run
	set appPath to POSIX path of (path to me)
	set actionChoices to {"Set Up Firmware", "Check Status", "Print Alignment Test Page", "Adjust Print Position", "Open Help Page", "Uninstall Driver"}
	set actionChoice to choose from list actionChoices with title appTitle with prompt "What would you like to do?" default items {"Set Up Firmware"} OK button name "Continue" cancel button name "Close" without multiple selections allowed
	if actionChoice is false then return
	set action to item 1 of actionChoice
	if action is "Set Up Firmware" then
		setUpFirmware(appPath)
	else if action is "Check Status" then
		checkStatus(appPath)
	else if action is "Print Alignment Test Page" then
		printTestPage(appPath)
	else if action is "Adjust Print Position" then
		adjustPosition(appPath)
	else if action is "Open Help Page" then
		open location projectURL
	else if action is "Uninstall Driver" then
		uninstallDriver(appPath)
	end if
end run

-- Returns the queue name, or "" if none / cancelled. Skips the question when only one queue exists.
on chooseQueue(promptText)
	set queueOutput to do shell script "/usr/bin/lpstat -p 2>/dev/null | /usr/bin/sed -n 's/^printer \\([^ ]*\\).*/\\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' || true"
	set queueChoices to paragraphs of queueOutput
	if (count of queueChoices) is 0 then
		display alert "Printer not set up yet" message "No HP LaserJet 1020 printer queue from this driver was found." & return & return & "1. Connect the printer by USB and switch it on." & return & "2. Open the installer package (.pkg) again." as critical
		return ""
	end if
	if (count of queueChoices) is 1 then return item 1 of queueChoices
	set picked to choose from list queueChoices with title appTitle with prompt promptText OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
	if picked is false then return ""
	return item 1 of picked
end chooseQueue

on setUpFirmware(appPath)
	set firmwareHelper to appPath & "Contents/Resources/firmware/setup-firmware.sh"
	set fetchHelper to appPath & "Contents/Resources/firmware/fetch-firmware.sh"
	set selectedQueue to chooseQueue("Choose the printer to set up:")
	if selectedQueue is "" then return

	set sourceChoices to {"Download and verify firmware automatically", "Select an existing firmware file"}
	set sourceChoice to choose from list sourceChoices with title "Firmware source" with prompt "The printer needs HP's firmware file (sihp1020.dl). It is not inside the installer." & return & return & "Automatic download needs internet. Or choose a sihp1020.dl you already downloaded. Either way the app checks the file's SHA-256 before installing it." default items {"Download and verify firmware automatically"} OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
	if sourceChoice is false then return

	set downloadedFirmware to false
	set cleanupDirectory to ""
	set firmwarePath to ""
	if item 1 of sourceChoice is "Download and verify firmware automatically" then
		try
			set firmwarePath to do shell script "/bin/sh " & quoted form of fetchHelper
			set cleanupDirectory to do shell script "/usr/bin/dirname " & quoted form of firmwarePath
			set downloadedFirmware to true
		on error errText
			set reply to display dialog "Firmware download was not completed." & return & return & errText buttons {"Open Instructions", "Select a File Now", "Close"} default button "Select a File Now" cancel button "Close" with title "Firmware download" with icon caution
			if button returned of reply is "Open Instructions" then
				open location firmwareHelpURL
				return
			end if
			set firmwarePath to ""
		end try
	end if
	if firmwarePath is "" then
		try
			set firmwareFile to choose file with prompt "Select your HP LaserJet firmware file (sihp1020.dl). It is checked before it is installed and is not uploaded anywhere."
		on error
			return
		end try
		set firmwarePath to POSIX path of firmwareFile
	end if

	try
		set resultText to do shell script "/bin/sh " & quoted form of firmwareHelper & " " & quoted form of firmwarePath & " " & quoted form of selectedQueue with administrator privileges
		display dialog resultText & return & return & "You only need to do this once. A background service reloads the firmware every time the printer is switched on." buttons {"OK"} default button "OK" with title "Firmware setup complete"
	on error errText
		display alert "Firmware setup was not completed" message errText as critical
	end try
	if downloadedFirmware then
		try
			do shell script "/bin/rm -rf " & quoted form of cleanupDirectory
		end try
	end if
end setUpFirmware

on checkStatus(appPath)
	set statusHelper to appPath & "Contents/Resources/firmware/status.sh"
	set queueOutput to do shell script "/usr/bin/lpstat -p 2>/dev/null | /usr/bin/sed -n 's/^printer \\([^ ]*\\).*/\\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' | /usr/bin/head -n 1 || true"
	set reportText to do shell script "/bin/sh " & quoted form of statusHelper & " " & quoted form of queueOutput
	set reply to display dialog reportText buttons {"Open Help Page", "OK"} default button "OK" with title "Printer status"
	if button returned of reply is "Open Help Page" then open location projectURL
end checkStatus

on printTestPage(appPath)
	set testPage to appPath & "Contents/Resources/a4-alignment-test.pdf"
	set selectedQueue to chooseQueue("Choose the printer:")
	if selectedQueue is "" then return
	try
		do shell script "/usr/bin/lp -d " & quoted form of selectedQueue & " -o PageSize=A4 -o media=A4 -o fit-to-page=false " & quoted form of testPage
	on error errText
		display alert "The test page could not be sent" message errText as critical
		return
	end try
	set reply to display dialog "The alignment test page was sent to the printer (load plain A4 paper)." & return & return & "With a ruler, measure the gap from each paper edge to the thick frame line:" & return & "A = left, B = right, C = top, D = bottom. Perfect = 10 mm each." & return & return & "Horizontal correction = (B − A) ÷ 2" & return & "Vertical correction = (D − C) ÷ 2" & return & return & "Then choose Adjust Print Position." buttons {"Adjust Now", "Done"} default button "Done" with title "Alignment test page"
	if button returned of reply is "Adjust Now" then adjustPosition(appPath)
end printTestPage

on adjustPosition(appPath)
	set setHelper to appPath & "Contents/Resources/firmware/set-offset.sh"
	set selectedQueue to chooseQueue("Choose the printer:")
	if selectedQueue is "" then return
	set confPath to "/Library/Printers/hp-legacy-mac-plus/queues/" & selectedQueue & ".conf"
	set currentH to do shell script "/usr/bin/sed -n 's/^HORIZONTAL_OFFSET_MM=//p' " & quoted form of confPath & " 2>/dev/null || true"
	set currentV to do shell script "/usr/bin/sed -n 's/^VERTICAL_OFFSET_MM=//p' " & quoted form of confPath & " 2>/dev/null || true"
	if currentH is "" then set currentH to "0"
	if currentV is "" then set currentV to "0"
	try
		set hReply to display dialog "Horizontal correction in millimetres (from -10 to 4)." & return & "Negative = move the print LEFT, positive = move it RIGHT." & return & return & "Current value: " & currentH & " mm. Type the NEW total value (current value + the correction from the test page)." default answer currentH buttons {"Cancel", "Next"} default button "Next" cancel button "Cancel" with title "Adjust print position (1 of 2)"
		set vReply to display dialog "Vertical correction in millimetres (from -10 to 4)." & return & "Negative = move the print UP, positive = move it DOWN." & return & return & "Current value: " & currentV & " mm." default answer currentV buttons {"Cancel", "Save"} default button "Save" cancel button "Cancel" with title "Adjust print position (2 of 2)"
	on error
		return
	end try
	set newH to text returned of hReply
	set newV to text returned of vReply
	try
		set resultText to do shell script "/bin/sh " & quoted form of setHelper & " " & quoted form of selectedQueue & " " & quoted form of newH & " " & quoted form of newV with administrator privileges
	on error errText
		display alert "Print position was not changed" message errText as critical
		return
	end try
	set reply to display dialog resultText buttons {"Print Test Page Again", "Done"} default button "Print Test Page Again" with title "Print position saved"
	if button returned of reply is "Print Test Page Again" then printTestPage(appPath)
end adjustPosition

on uninstallDriver(appPath)
	set uninstallHelper to appPath & "Contents/Resources/uninstall.sh"
	set queueOutput to do shell script "/usr/bin/lpstat -p 2>/dev/null | /usr/bin/sed -n 's/^printer \\([^ ]*\\).*/\\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' || true"
	set queueChoices to paragraphs of queueOutput
	if (count of queueChoices) is 0 then
		display alert "Nothing to remove" message "No HP LaserJet 1020 Plus printer queue from this driver is installed." as informational
		return
	end if
	set selectedQueues to choose from list queueChoices with title "Uninstall HP LaserJet 1020 Plus" with prompt "Choose the printer queue to remove:" OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
	if selectedQueues is false then return
	set selectedQueue to item 1 of selectedQueues
	set confirmation to display dialog "Remove this printer queue, its firmware service and this driver's files?" & return & return & "Other printers and any older HP driver are left alone. You can drag this app to the Trash afterwards." buttons {"Cancel", "Remove"} default button "Cancel" cancel button "Cancel" with icon caution
	if button returned of confirmation is not "Remove" then return
	try
		set resultText to do shell script "/bin/sh " & quoted form of uninstallHelper & " " & quoted form of selectedQueue & " REMOVE" with administrator privileges
		display dialog resultText buttons {"OK"} default button "OK" with title "Driver removed"
	on error errText
		display alert "Uninstall was not completed" message errText as critical
	end try
end uninstallDriver
