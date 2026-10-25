-- Double-clickable GUI for firmware setup and safe candidate-driver removal.
set actionChoices to {"Set Up Firmware", "Uninstall Candidate Driver"}
set actionChoice to choose from list actionChoices with title "HP LaserJet 1020 Plus" with prompt "Choose an action:" OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
if actionChoice is false then return

set appPath to POSIX path of (path to me)
set firmwareHelper to appPath & "Contents/Resources/firmware/setup-firmware.sh"
set fetchHelper to appPath & "Contents/Resources/firmware/fetch-firmware.sh"
set uninstallHelper to appPath & "Contents/Resources/uninstall.sh"

if item 1 of actionChoice is "Set Up Firmware" then
  set queueOutput to do shell script "/usr/bin/lpstat -p | /usr/bin/sed -n 's/^printer \\([^ ]*\\).*/\\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' || true"
  set queueChoices to paragraphs of queueOutput
  if (count of queueChoices) is 0 then
    display alert "No candidate printer queue found" message "Install the HP LaserJet 1020 Plus driver and connect the printer first." as critical
    return
  end if
  set selectedQueues to choose from list queueChoices with title "HP LaserJet firmware setup" with prompt "Choose the USB queue for the HP LaserJet 1020 Plus:" OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
  if selectedQueues is false then return
  set selectedQueue to item 1 of selectedQueues

  set sourceChoices to {"Download and verify firmware automatically", "Select an existing firmware file"}
  set sourceChoice to choose from list sourceChoices with title "Firmware source" with prompt "The proprietary firmware is not stored in the installer. Automatic download retrieves the source image over HTTPS from the community mirror referenced by OpenPrinting foo2zjs, converts it locally and verifies its exact SHA-256 before installation. Internet access is required. You can instead select a local firmware file." OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
  if sourceChoice is false then return

  set downloadedFirmware to false
  set cleanupDirectory to ""
  if item 1 of sourceChoice is "Download and verify firmware automatically" then
    try
      set firmwarePath to do shell script "/bin/sh " & quoted form of fetchHelper
      set cleanupDirectory to do shell script "/usr/bin/dirname " & quoted form of firmwarePath
      set downloadedFirmware to true
    on error errText number errNum
      display alert "Firmware download was not completed" message errText as critical
      return
    end try
  else
    set firmwareFile to choose file with prompt "Select your existing HP LaserJet firmware file (sihp1020.dl). The file is checked before it is installed and is not uploaded."
    set firmwarePath to POSIX path of firmwareFile
  end if

  try
    set resultText to do shell script "/bin/sh " & quoted form of firmwareHelper & " " & quoted form of firmwarePath & " " & quoted form of selectedQueue with administrator privileges
    display dialog resultText buttons {"OK"} default button "OK" with title "HP LaserJet firmware setup"
  on error errText number errNum
    if downloadedFirmware then
      try
        do shell script "/bin/rm -rf " & quoted form of cleanupDirectory
      end try
    end if
    display alert "Firmware setup was not completed" message errText as critical
    return
  end try
  if downloadedFirmware then
    try
      do shell script "/bin/rm -rf " & quoted form of cleanupDirectory
    end try
  end if
else
  set queueOutput to do shell script "/usr/bin/lpstat -p | /usr/bin/sed -n 's/^printer \\([^ ]*\\).*/\\1/p' | /usr/bin/grep '^HP_LaserJet_1020_Plus_Candidate' || true"
  set queueChoices to paragraphs of queueOutput
  if (count of queueChoices) is 0 then
    display alert "No candidate printer queue found" message "No HP LaserJet 1020 Plus candidate queue appears to be installed." as informational
    return
  end if
  set selectedQueues to choose from list queueChoices with title "Uninstall HP LaserJet 1020 Plus" with prompt "Choose the candidate queue to remove:" OK button name "Continue" cancel button name "Cancel" without multiple selections allowed
  if selectedQueues is false then return
  set selectedQueue to item 1 of selectedQueues
  set confirmation to display dialog "Remove only the selected candidate printer queue and its associated candidate driver files? Your original HP legacy driver and other printer queues will be left alone." buttons {"Cancel", "Remove Candidate"} default button "Cancel" cancel button "Cancel" with icon caution
  if button returned of confirmation is not "Remove Candidate" then return
  try
    set resultText to do shell script "/bin/sh " & quoted form of uninstallHelper & " " & quoted form of selectedQueue & " REMOVE" with administrator privileges
    display dialog resultText buttons {"OK"} default button "OK" with title "HP LaserJet candidate removal"
  on error errText number errNum
    display alert "Uninstall was not completed" message errText as critical
  end try
end if
