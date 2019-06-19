<#	
	.NOTES
	===========================================================================
	 Created on:   	1/31/2019 10:12 AM
	 Created by:   	rknight
	 Filename:     	VDI_Prep_Post.PS1
	======================================================================================================================================================
	.DESCRIPTION
		This script preps a machine for Post
			Prep Post
		Log file is located in c:\VDI_Logs

		-Pulls up user profiles with option to delete 1
		-Disable windows update service
		-Empty out Event Logs
		-Run ClientSideClonePrepTool.exe
		-Delete C:\Application Installation folder and all contents
		-Prompt to update image-ver.txt file on the C:\ drive
		-run "vietool.exe c: --generate" as a command
		-run Dsregcmd /leave to ensure the machine is not azure joined.
		-Delete all keys from C:/ProgramData/Microsoft/Crypto/keys/
		-Sysprep machine In admin cmd : C:\windows\system32\sysprep\sysprep.exe /generalize /oobe /shutdown /mode:vm
	CURRENTLY IN TESTING. THIS SCRIPT PROMPTS YOU AT EVERY STEP.
		To disable testing set Debug to False.
	======================================================================================================================================================
#>

# Elevate script to Admin
	if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

$debug = 1 # 0 = off, 1 = on

#Begin logging

#Peramiters
	$logPath = "C:\VDI_Logs" #where you want to store your logs
	$LogfileName = "VDI_PrePrep_" # name of log file (date will be appended to this)
#End Peramiters

	$filedate = get-date -format "MM-dd-yyyy HH:MM:ss"
	$Date = get-date -format yyyy-MM-dd
	$files = Get-ChildItem -Path $logPath -Recurse | Where-Object { -not $_.PsIsContainer }
	$log = $logPath + "\$LogfileName-$date.log"
	$logstr = $filedate + "  ----------Script Started----------"
	add-content $Log $logstr
	$logstr = $filedate + "Info to enter in log"
	add-content $Log $logstr

	$Comp = get-childitem -path env:computername

# Disable Windows Update Service
	net stop wuauserv / sc config wuauserv start= disabled
[System.Windows.Forms.MessageBox]::Show("Verify Windows update service is disabled", "SYSPREP", "Ok", "Warning")
# Delete User Profile -- Only deletes one.
	Get-WmiObject -ClassName Win32_UserProfile -Filter "Special=False AND Loaded=False" |
	Add-Member -MemberType ScriptProperty -Name UserName -Value { (New-Object System.Security.Principal.SecurityIdentifier($this.Sid)).Translate([System.Security.Principal.NTAccount]).Value } -PassThru |
	Out-GridView -Title "Select User Profile" -OutputMode Single |
	ForEach-Object {
		# uncomment the line below to actually remove the selected user profile!
		$_.Delete()
	}
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Win Update Service is disabled", "Image Notes", "Ok", "Warning")}

# Clearing Event Logs
	Get-EventLog -LogName * | ForEach { Clear-EventLog $_.Log }
	# Clear-EventLog -LogName (Get-EventLog -List).log
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Event Logs are Cleared", "Image Notes", "Ok", "Warning")}

# Do whatever this does.
	Start-Process -FilePath "C:\tools\VirtualImageException\ClientSideClonePrepTool.exe" -Wait
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Clientside Clone Prep Tool ran", "Image Notes", "Ok", "Warning")}

# Delete C:\Application Installation folder and all files
	Remove-Item "C:\Application Installation" -recurse -Force -Confirm:$false
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Application Installation folder is gone", "Image Notes", "Ok", "Warning")}

# Clear Crypto Keys
	Remove-Item -path "C:\ProgramData\Microsoft\Crypto\Keys\*" -Force -Confirm:$false
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Crypto keys are cleared from programdata microsoft crypto keys", "Image Notes", "Ok", "Warning")}

#Update Image Notes
	[System.Windows.Forms.MessageBox]::Show("Please update image notes", "Image Notes", "Ok", "Warning")
	notepad "C:\user2.bat" | Out-Null

# Remove from Azure AD
	Dsregcmd /leave
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Machine is not Azure Joined", "Image Notes", "Ok", "Warning")}

# Set Virtual Image Exception
Start-Process -FilePath "C:\tools\VirtualImageException\vietool.exe" -ArgumentList 'c: --generate' -Wait
if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("Verify Vietool ran", "Image Notes", "Ok", "Warning")}

# Final Step -- Sysprep machine
[System.Windows.Forms.MessageBox]::Show("Ready to Sysprep?", "SYSPREP", "Ok", "Warning")

#Start-Process -FilePath "C:\windows\system32\sysprep\sysprep.exe" -ArgumentList '/generalize /oobe /shutdown /mode:vm'

if ($debug -eq 1) {[System.Windows.Forms.MessageBox]::Show("End of script - at this point sysprep takes over", "Image Notes", "Ok", "Warning")}


