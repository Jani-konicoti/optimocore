"""Prepare a separate document-test runtime; originals and Monitor fixture stay intact."""
import hashlib
import json
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path
import prepare_smoke

ROOT = Path(__file__).resolve().parents[1]

def main():
    destination = ROOT / '.local/runtime/document-test'
    index = json.loads((ROOT / 'docs/evidence-index.json').read_text(encoding='utf-8'))
    for artifact in index['artifacts']:
        source = prepare_smoke.CORE / artifact['name']
        if hashlib.sha256(source.read_bytes()).hexdigest() != artifact['sha256']:
            raise ValueError(f"Unexpected original build: {artifact['name']}")
    credentials = json.loads((ROOT / '.local/fixture/credentials.json').read_text(encoding='utf-8-sig'))
    prepare_smoke.DEST = destination
    prepare_smoke.main()
    # Use the existing exact-build isolated activation probe, never call it a
    # vendor-issued license. DataValidation.exe itself remains unchanged.
    patch = json.loads((ROOT / '.local/candidates/license-probe/patch-report.json').read_text(encoding='utf-8-sig'))
    utility = ROOT / '.local/candidates/license-probe/Utility.dll'
    if hashlib.sha256(utility.read_bytes()).hexdigest() != patch['candidate_sha256']:
        raise ValueError('Unexpected Utility candidate')
    shutil.copy2(utility, destination / 'Utility.dll')
    shutil.copy2(prepare_smoke.CORE / 'Empty.mdb', destination / 'Empty.mdb')
    connection = ('Data Source=127.0.0.1,14333;Initial Catalog=CoreReaDvFixture;User ID=sa;Password='
                  + credentials['sa_password'] + ';Connect Timeout=5;Encrypt=False;Application Name=CoreREA-DocumentTest;Pooling=False')
    for name in ['Monitor.exe', 'DataValidation.exe']:
        path = destination / (name + '.config')
        tree = ET.parse(path)
        for setting in tree.getroot().iter('setting'):
            value = setting.find('value')
            if value is None:
                continue
            key = setting.get('name', '')
            if key == 'ConnectionString':
                value.text = connection + '|REA Document Test'
            elif key in ['Oracle', 'NetPC']:
                value.text = 'N'
            elif key == 'ProcessName':
                value.text = 'REA Validation'
            elif key == 'EmptyDB':
                value.text = str(destination / 'Empty.mdb')
        tree.write(path, encoding='utf-8', xml_declaration=True)
    print('Prepared separate document-test copies against loopback CoreReaDvFixture; activation uses the existing isolated probe.')

if __name__ == '__main__':
    main()
