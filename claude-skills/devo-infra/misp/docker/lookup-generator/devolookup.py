#!/usr/bin/env python3
import json
import base64
import datetime
import io 
import csv
import sys


# To get all the MISP object fields, we do this:
#
# $ git clone https://github.com/MISP/misp-objects
# $ pushd misp-objects/objects
# $ grep -r misp-attribute| awk '{print $3}' | cut -d, -f1 | sort -u
# $ popd
#
misp_fields = ["aba-rtn", "AS", "attachment", "authentihash", "bank-account-nr", "bic", "boolean", "btc", "cc-number", "comment", "cookie", "counter", "date-of-birth", "datetime", "domain", "email-attachment", "email-body", "email-dst", "email-dst-display-name", "email-header", "email-message-id", "email-mime-boundary", "email-reply-to", "email-src", "email-src-display-name", "email-subject","email-thread-index","email-x-mailer","filename","first-name","float","gender", "hostname", "http-method", "iban", "identity-card-number", "impfuzzy", "imphash", "ip-dst", "ip-src","ja3-fingerprint-md5","last-name","link","malware-sample","md5","middle-name","mime-type","nationality","other","passport-country","passport-expiration","passport-number","pattern-in-file","pehash","phone-number","place-of-birth","port","redress-number","regkey","sha1","sha224","sha256","sha384","sha512","sha512/224","sha512/256","size-in-bytes","snort","src-port","ssdeep","stix2-pattern","target-email","target-external","target-location","target-machine","target-org","target-user","text","timestamp-microsec","tlsh","uri","url","user-agent","whois-registrant-email","whois-registrant-name","whois-registrant-org","whois-registrant-phone","whois-registrar","x509-fingerprint-md5","x509-fingerprint-sha1","x509-fingerprint-sha256","xmr","yara"]

misperrors = {'error': 'Error'}
moduleinfo = {'version': '1', 'author': 'Sebastien Tricaud',
              'description': 'Export to a Devo lookup',
              'module-type': ['export']}
moduleconfig = ["version","aggregate_by","feeds_from","separator_char"]
mispattributes = {}


configversion = "1"
configaggregate_by = "ip-dst"
configfeeds_from = ""
configseparator_char = "\n"
defaultconfig = {"version": configversion, "aggregate_by": configaggregate_by, "feeds_from": configfeeds_from, "separator_char": configseparator_char}

def get_all_fields(data):
    fields = ["category","uuid"]
    for event in data:
        for attribute in event["Attribute"]:
            if "|" in attribute["type"]:            
                attr_fields = tuple(attribute["type"].split("|"))
                for i, field in enumerate(attr_fields):
                    if field not in fields:
                        fields.append(field)        
            else:
                field = attribute["type"]
                if field not in fields:
                    fields.append(field)        

    return fields


def handler(q=False):
    if q is False:
        return False
    request = json.loads(q)

    config = {}
    if "config" in request:
        config = request["config"]
    else:
        config = defaultconfig

    if "data" not in request:
        return False


    csvbuf = io.StringIO()
    csv_writer = csv.DictWriter(csvbuf, fieldnames=get_all_fields(request["data"]))
    csv_writer.writeheader()
    
    for event in request["data"]:
        for attribute in event["Attribute"]:
            if "|" in attribute["type"]:
                fields = tuple(attribute["type"].split("|"))
                indicators = tuple(attribute["value"].split("|"))
                all_indicators = {}
                for i, indicator in enumerate(indicators):
                    all_indicators[fields[i]] = indicator

                all_indicators["category"] = attribute["category"]
                all_indicators["uuid"] = attribute["uuid"]
                    
                csv_writer.writerow(all_indicators)
            else:
                csv_writer.writerow({
                    attribute["type"]: attribute["value"],
                    "category": attribute["category"],
                    "uuid": attribute["uuid"]
                })

    if config["aggregate_by"] == "" or config["aggregate_by" == None]:
        return {"response": [], "data": str(base64.b64encode(bytes(csvbuf.getvalue(), "utf-8")), "utf-8")}

                
    csv_reader = csv.DictReader(io.StringIO(csvbuf.getvalue()))

    aggregated_dict = {}
    for row in csv_reader:    
        try:
            agg_key = aggregated_dict[row[config["aggregate_by"]]]
        except KeyError:
            try:
                aggregated_dict[row[config["aggregate_by"]]] = {}
            except KeyError:
                # This error comes from the fact the row does not have the aggregate field we are looking for, so we return the last non aggregated CSV
                return {"response": [], "data": str(base64.b64encode(bytes(csvbuf.getvalue(), "utf-8")), "utf-8")}                

            agg_key = aggregated_dict[row[config["aggregate_by"]]]

        for k,v in row.items():
            if k == config["aggregate_by"]:
                continue
                    
            try:
                element = agg_key[k]
            except KeyError:
                agg_key[k] = []
                element = agg_key[k]

            if v not in element:
                element.append(v)
    
    aggregated_csvbuf = io.StringIO()
    aggregated_csv_writer = csv.DictWriter(aggregated_csvbuf, fieldnames=get_all_fields(request["data"]))
    aggregated_csv_writer.writeheader()

    infield_separator = config["separator_char"]
    if infield_separator == None:
        infield_separator = " " # No defined separator? we use space
    if infield_separator == "\\n":
        infield_separator = "\n"
    for k,v in aggregated_dict.items():
        flat_v = {}
        for kk, vv in v.items():
            flat_v[kk] = infield_separator.join(vv)
        key_v = {}
        key_v[config["aggregate_by"]] = k

        # Requires Python >= 3.5
        out_dict = {**flat_v, **key_v}    
        aggregated_csv_writer.writerow(out_dict)
                
    
    return {"response": [], "data": str(base64.b64encode(bytes(aggregated_csvbuf.getvalue(), "utf-8")), "utf-8")}

def introspection():
    modulesetup = {}
    try:
        configversion
        modulesetup["version"] = configversion
    except NameError:
        pass
    try:
        configaggregate_by
        modulesetup["aggregate_by"] = configaggregate_by
    except NameError:
        pass
    try:
        configfeeds_from
        modulesetup["feeds_from"] = configfeeds_from
    except NameError:
        pass
    try:
        configseparator_char
        modulesetup["separator_char"] = configseparator_char
    except NameError:
        pass
    return modulesetup

def version():
    moduleinfo["config"] = moduleconfig
    return moduleinfo


# if __name__ == "__main__":
#     query = {"module": "devo_lookup"}
#     query["config"] = {"version": "1", "aggregate_by": "ip-dst", "feeds_from": ""}
#     fp = open(sys.argv[1], "r")
#     filebuf = fp.read()
#     query["data"] = json.loads(filebuf)


#     retval = handler(json.dumps(query))
    
#     fp.close()
