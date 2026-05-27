#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import json
import pprint
import re
from pyfaup.faup import Faup

from pymisp import PyMISP

url_parser = Faup()

fields_mapping = {"hostname": "domain", "ip-dst": "ip"}

lookup_files = {"Threat-Malware-by-IP": open("Threat-Malware-by-IP.csv", "a"), "Threat-Fraud-by-IP": open("Threat-Fraud-by-IP.csv", "a"), "Threat-Malware-by-Domain": open("Threat-Malware-by-Domain.csv", "a"), "isTorNode": open("isTorNode.csv","a")}

# Add headers
lookup_files["Threat-Malware-by-IP"].write("ip,threat\n")
lookup_files["Threat-Fraud-by-IP"].write("ip,threat\n")
lookup_files["Threat-Malware-by-Domain"].write("domain,threat\n")
lookup_files["isTorNode"].write("ip,isTorNode\n")
    

jsonfile = open(sys.argv[1], "r")
jobj = json.loads(jsonfile.read())
#pprint.pprint(jobj)

def is_malware(misp_event):
    malware_info_rex = [re.compile(".*payload.*", re.IGNORECASE), re.compile(".*Mal.*", re.IGNORECASE)]
    has_match = False
    for mr in malware_info_rex:
        has_match = mr.search(misp_event["info"])
        if has_match:
            return True
    return False

def is_fraud(misp_attribute):
    if misp_attribute["category"] == "Financial fraud":
        return True
    return False

def is_tor(misp_event):
    tor_info_rex = [re.compile(".*tor .*", re.IGNORECASE)]
    has_match = False
    for mr in tor_info_rex:
        has_match = mr.search(misp_event["info"])
        if has_match:
            return True
    return False

def misp_event_iter(misp_object):
    event = misp_object["Event"]
    malware_detected = is_malware(event)
    tor_detected = is_tor(event)
    attr_types = []
    attr_values = []
    for attribute in event["Attribute"]:
        if "|" in attribute["type"]:
            fields = tuple(attribute["type"].split("|"))
            indicators = tuple(attribute["value"].split("|"))
            for i, indicator in enumerate(indicators):
                fraud_detected = is_fraud(attribute)
                yield malware_detected, fraud_detected, tor_detected, attribute["category"], fields[i], indicator
        else:
            fraud_detected = is_fraud(attribute)
            yield malware_detected, fraud_detected, tor_detected, attribute["category"], attribute["type"], attribute["value"]


#for misp_event in jobj:
for misp_event in jobj["response"]:
    # pprint.pprint(misp_event["Event"]["info"])

    for malware_detected, fraud_detected, tor_detected, category, misp_type, misp_value in misp_event_iter(misp_event):
        # if misp_type == "url":
        #     print(url_parser.decode(misp_value))
#        print(malware_detected, category, misp_type, misp_value)
        if malware_detected:
#            print(misp_type + "=====" + misp_value)
            if misp_type == "hostname":
                lookup_files["Threat-Malware-by-Domain"].write(misp_value + "," + category + "\n")
            if misp_type == "ip-dst":
                lookup_files["Threat-Malware-by-IP"].write(misp_value + "," + category + "\n")
        if tor_detected:
            if misp_type == "ip-dst":
                lookup_files["isTorNode"].write(misp_value + "," + "true" + "\n")
        if fraud_detected:
            if misp_type == "ip-dst":
                lookup_files["Thread-Fraud-by-IP"].write(misp_value + "," + category + "\n")
            
                
jsonfile.close()

for k, v in lookup_files.items():
    v.close()
    
