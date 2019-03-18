#!/usr/bin/env python
import re
import requests
from xml.etree import ElementTree

xml_url = 'https://download.seadrive.org'
name_pattern = re.compile('^seafile-server_(.*)_x86-64\\.tar\\.gz$')

def get_download_link (url):
    xml = requests.get(url)

    root = ElementTree.fromstring(xml.content)
    ns_uri, _, _ = root.tag[1:].partition('}')
    namespaces = { 'ns': ns_uri }

    keys = list(filter(lambda key: re.match(name_pattern, key.text), root.findall('ns:Contents/ns:Key', namespaces)))

    file_name = keys[len(keys) - 1].text

    return '{}/{}'.format(xml_url, file_name), file_name

def download_file (url, name):
    r = requests.get(url, stream=True)
    if r.status_code == 200:
        with open(name, 'wb') as f:
            for chunk in r:
                f.write(chunk)

if __name__ == "__main__":
    url, name = get_download_link(xml_url)
    download_file(url, name)
