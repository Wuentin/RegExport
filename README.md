# RegExport

Powershell script that exports the SAM & SECURITY hives. It also retrieves the bootkey, the secret needed to decrypt the hives.
The goal is to make it easier to export and automate the recovery of Windows credentials.

Currently system rights are mandatory, a workaround is being worked on.


# Credits 
This is a powershell adaptation of @Defte_'s article:
[SensePost](https://sensepost.com/blog/2024/dumping-lsa-secrets-a-story-about-task-decorrelation/)

