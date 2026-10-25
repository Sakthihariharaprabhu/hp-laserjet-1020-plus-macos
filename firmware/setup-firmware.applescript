-- Double-clickable GUI setup source. Built into an .app on macOS by the packaging workflow.
set firmwareFile to choose file with prompt "Select your existing HP LaserJet 1020 firmware file (sihp1020.dl). It will be checksum-verified and copied locally; it will not be uploaded to the internet."
set queueOutput to do shell script "/usr/bin/lpstat -p | /usr/bin/sed -n 's/^printer \\([^ ]*\\).*/\\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' || true"
set queueChoices to paragraphs of queueOutput
if (count of queueChoices) is 0 then
  display alert "No printer queues found" message "Install the HP LaserJet 1020 Plus driver and connect the printer first." as critical
  return
end if
set selectedQueues to choose from list queueChoices with title "HP LaserJet firmware setup" with prompt "Choose the USB queue for the HP LaserJet 1020 Plus:" OK button name "Set Up" cancel button name "Cancel" without multiple selections allowed
if selectedQueues is false then return
set selectedQueue to item 1 of selectedQueues
set appPath to POSIX path of (path to me)
set helperPath to appPath & "Contents/Resources/firmware/setup-firmware.sh"
set firmwarePath to POSIX path of firmwareFile
try
  set resultText to do shell script "/bin/sh " & quoted form of helperPath & " " & quoted form of firmwarePath & " " & quoted form of selectedQueue with administrator privileges
  display dialog resultText buttons {"OK"} default button "OK" with title "HP LaserJet firmware setup"
on error errText number errNum
  display alert "Firmware setup was not completed" message errText as critical
end try
