# RegExport

Powershell script that exports the SAM & SECURITY hives. It also retrieves the bootkey, the secret needed to decrypt the hives.
The goal is to make it easier to export and automate the recovery of Windows credentials.

Administrator rights are mandatory.

```powershell
 ____            _____                       __
|  _ \ ___  __ _| ____|_  ___ __   ___  _ __| |_
| |_) / _ \/ _ |  _| \ \/ / '_ \ / _ \| '__| __|
|  _ <  __/ (_| | |___ >  <| |_) | (_) | |  | |_
|_| \_\___|\__, |_____/_/\_\ .__/ \___/|_|   \__|
           |___/           |_|

[*] Boot key is: ********************************
[+] Exporting SAM
The operation completed successfully.
[+] Successfully exported SAM to C:\SAM.reg
[+] Exporting SECURITY
The operation completed successfully.
[+] Successfully exported SECURITY to C:\SECURITY.reg

0oOo
||||)
||||     Enjoy!
'""'



```
# BootkeyFromPDF

You can use the Python script **BootkeyFromPDF.py** if you have printed LSA with regedit. The script will get the class values and calculate the bootkey.
```powershell
 ____              _   _              _____                    ____  ____  _____
| __ )  ___   ___ | |_| | _____ _   _|  ___| __ ___  _ __ ___ |  _ \|  _ \|  ___|
|  _ \ / _ \ / _ \| __| |/ / _ \ | | | |_ | '__/ _ \| '_ ` _ \| |_) | | | | |_
| |_) | (_) | (_) | |_|   <  __/ |_| |  _|| | | (_) | | | | | |  __/| |_| |  _|
|____/ \___/ \___/ \__|_|\_\___|\__, |_|  |_|  \___/|_| |_| |_|_|   |____/|_|
                                |___/


[*] HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\JD : ********
[*] HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\Skew1 : ********
[*] HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\GBG : ********
[*] HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa\Data : ********
[+] Target system bootKey: ********************************

```
### Usage 
```python
 python .\pdf_parser.py --help
usage: pdf_parser.py [-h] --path PATH

Calculate bootkey from PDF.

options:
  -h, --help   show this help message and exit
  --path PATH  Path to the PDF file

```
# Post Export
You can use the Python script **RegExport.py** in a controlled VM to import the results of RegExport. Then the script will dump the results using Reg Save. Finally, decrypt the hives using bootkey to recover Windows secrets.

```powershell
python .\RegExport.py --help
usage: RegExport.py [-h] --directory DIRECTORY --bootkey BOOTKEY [--output-file OUTPUT_FILE] --sam SAM --security SECURITY

Import results from Reg Export and dump results using Reg Save. Decrypt hives using bootkey to recover Windows secrets.

options:
  -h, --help            show this help message and exit
  --directory DIRECTORY
                        Directory where the .hive files will be saved
  --bootkey BOOTKEY     Boot key for SAM and LSA extraction
  --output-file OUTPUT_FILE
                        Output file for SAM and LSA hashes
  --sam SAM             Path to the SAM file
  --security SECURITY   Path to the SECURITY file
```

# Credits 
This is a powershell adaptation of @Defte_'s article:
[SensePost](https://sensepost.com/blog/2024/dumping-lsa-secrets-a-story-about-task-decorrelation/)

# Ethical Only

The intended use of this tool is strictly for educational purposes, promoting ethical understanding and responsible learning in the realm of cybersecurity. This tool is not meant for any malicious activities or unauthorized access.  
Using this tool against hosts that you do not have explicit permission to test is illegal. You are responsible for any trouble you may cause by using this tool.
