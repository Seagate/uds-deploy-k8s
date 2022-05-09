# Data Mover Extension (DMX)

## Parameters to be passed into DMX scripts

### DMX pre staging script:
* Absolute path to the directory that contains the source file (Ex: /dmx/examples/sample_data)
* DMX option, a free form string, which can be provided upon UDS task create as it is an optional
parameter (see [Note](#note)). If this parameter is not provided, an empty string will be passed
into DMX scripts.

```bash
/etc/uds/dmx_staging.py /dmx/examples/sample_data "free form string"
```

### DMX object processing and DMX verify scripts
* UDS operation (Ex: 'INGEST', 'EXPORT', 'CHECK')
* File info, in JSON string format, stored in the manifest file (Ex: '{"fileName": "filename.jpg", "fileSize": 1024}')
* Absolute path to the directory that contains the source files (Ex: '/dmx/examples/sample_data')
* DMX option, a free form string, which can be provided upon UDS task create as it is an optional
parameter (see [Note](#note)). If this parameter is not provided, an empty string will be passed
into DMX scripts.

```bash
/etc/uds/dmx_object_processing.py 'INGEST' '{"fileName": "filename.jpg", "fileSize": 1024}' '/dmx/examples/sample_data' 'free form string'

/ect/uds/dmx_object_processing.py 'EXPORT' '{"fileName": "filename.jpg", "fileSize": 10, "customInfo": {"tags": ["TAG_1", "TAG_2"]}}' '/root/.uds/ingested/.uds/data_store/324cc1dcd320482cafa6677dd8de91a7' 'free form string'

/etc/uds/dmx_script_verify.py 'CHECK' '{"fileName": "filename.jpg", "fileSize": 10, "customInfo": {"tags": ["TAG_1", "TAG_2"]}}' '/root/.uds/ingested/.uds/data_store/324cc1dcd320482cafa6677dd8de91a7' 'free form string'
```

### Expected response from DMX script
The response from DMX script must be in JSON format or JSON string format.
* "status" value must be PASSED, FAILED, IGNORE
* "reason" is a string or an empty string
* "tags" is a list of strings or an empty list

```bash
{
    "status": "PASSED",
    "reason":, "defined by user",
    "tags": [
        "defined by user",
        "defined by user"
    ]
}
```

## DMX pre staging script for INGEST operation
The following is DMX pre staging script example written in python. The script iterates
through all the files in the source volume and extract the content of each file then
build a list of tags. 

A parameter that gets passed into DMX pre staging script:
* `sys.argv[1]`: Absolute path to the directory that contains the source files 
(Ex: '/dmx/examples/sample_data')

Expected result to be returned from DMX pre staging script:
* A JSON string format

``` bash
'{"status": "PASSED", "reason": "Good", "tags": ["RIGHT_TURN", "LEFT_TURN", "GOOD_IMAGE", "BAD_IMAGE"]}'
```

### DMX pre staging script example
This script can run with data set in `/dmx/examples/dmxtags/sample_data`

``` bash
#!/usr/bin/python3

import sys
import os

status = 'PASSED'
reason = 'Good'
tags = []

# Parameter that gets passed into the script is the absolute path to the source volume
# Example: /dmx/examples/sample_data
data_path = sys.argv[1]
# An free form string that gets passed on UDS task create
dmx_option = sys.argv[2]

# Function that checks to see if 'value' is already on the 'list'
def is_already_on_list(value, list):
    for v in list:
        if v == value:
            return True
    return False

# Iterate through all data files in the 'data_path' and read the content of each file
# and build a list of tags
with os.scandir(data_path) as tree_iter:
    for entry in tree_iter:
        with open(entry.path, 'r') as infile:
            read_line = infile.readline()
            if 'right turn' == read_line and not is_already_on_list('RIGHT_TURN', tags):
                tags.append('RIGHT_TURN')
            if 'left turn' == read_line and not is_already_on_list('LEFT_TURN', tags):
                tags.append('LEFT_TURN')
            if 'good image' == read_line and not is_already_on_list('GOOD_IMAGE', tags):
                tags.append('GOOD_IMAGE')
            if 'bad image' == read_line and not is_already_on_list('BAD_IMAGE', tags):
                tags.append('BAD_IMAGE')

# Build result
result = {
    "status": status,
    "reason": reason,
    "tags": tags
}
print(result)
```

## DMX object processing script for INGEST and EXPORT operations
The following is DMX object processing script example written in python. If the UDS operation
is 'INGEST', the script reads the content of the source file and creates a list of tags, in
this example it only creates one tag. If the UDS operation is 'EXPORT', the script returns
'status' as 'IGNORE' if 'customInfo' of the source file is `not` 'RIGHT_TURN' or the
source file doesn't have any tags.

Parameters that get passed into DMX object processing script:
* `sys.argv[1]`: File name (Ex: 'filename.jpg')
* `sys.argv[2]`: UDS operation (Ex: 'INGEST', 'EXPORT', 'CHECK')
* `sys.argv[3]`: File info, in JSON string format, stored in the manifest file (Ex: '{"fileName": "filename.jpg", "fileSize": 1024}')
* `sys.argv[4]`: Absolute path to the directory that contains the source file (Ex: '/dmx/examples/sample_data')

Expected result to be returned from DMX object processing script:
* A JSON string format

``` bash
'{"status": "PASSED", "reason": "Good", "tags": ["RIGHT_TURN", "LEFT_TURN", "GOOD_IMAGE", "BAD_IMAGE"]}'

# or
'{"status": "IGNORE", "reason": "", "tags": []}'
```

### DMX object processing script example
This script can run with data set in `/dmx/examples/dmxtags/sample_data`

``` bash
#!/usr/bin/python3

import sys
import os
import json

status = 'PASSED'
reason = 'Good'
tags = []

# UDS operation: INGEST, EXPORT, COPY/MOVE
uds_operation = sys.argv[1]
# 'sys.argv[2]' example:
# '{"fileName": "filename.jpg", "fileSize": 1024}'
# '{"fileName": "file1.txt", "fileSize": 10, "customInfo": {"tags": ["TAG_1", "TAG_2"]}}'
manifest_file_info_str = sys.argv[2]
# Convert the manifest file info from string format to dictionary.
manifest_file_info_dict = json.loads(manifest_file_info_str)
# Parameter that gets passed into the script is the absolute path to the source volume
# Example: /root/.uds/ingested/.uds/data_store/324cc1dcd320482cafa6677dd8de91a7
data_path = sys.argv[3]
# An free form string that gets passed on UDS task create
dmx_option = sys.argv[4]

if uds_operation == 'INGEST':
    # Build absolute path to the data file
    file_path = os.path.join(data_path, manifest_file_info_dict['fileName'])
    if os.path.exists(file_path):
        # Read the content of the file and build file tags
        with open(file_path, 'r') as infile:
            read_line = infile.readline()
            if 'right turn' == read_line:
                tags = ['RIGHT_TURN']
            if 'left turn' == read_line:
                tags = ['LEFT_TURN']
            if 'good image' == read_line:
                tags = ['GOOD_IMAGE']
            if 'bad image' == read_line:
                tags = ['BAD_IMAGE']

# Return 'status' as 'IGNORE' if the data file isn't tagged as 'RIGHT_TURN' or
# has no tags
if uds_operation == 'EXPORT':
    # Extract 'customInfo' to retrieve 'tags'
    if manifest_file_info_dict.get('customInfo', None) is not None:
        # If tag is 'RIGHT_TURN' then set status to 'IGNORE'
        if manifest_file_info_dict['customInfo']['tags'][0] != 'RIGHT_TURN':
            status = 'IGNORE'
    # If there's no tag in 'customInfo' then set status to 'IGNORE'
    if manifest_file_info_dict.get('customInfo', None) is None:
        status = 'IGNORE'

# Build result
result = {
    "status": status,
    "reason": reason,
    "tags": tags
}

print(result)
```

## DMX verify script which is also used for CHECK operation
The following is DMX verify script example written in python.

Parameters that get passed into DMX verify script:
* `sys.argv[1]`: File name (Ex: 'filename.jpg')
* `sys.argv[2]`: UDS operation (Ex: 'INGEST', 'EXPORT', 'CHECK')
* `sys.argv[3]`: File info, in JSON string format, stored in the manifest file (Ex: '{"fileName": "filename.jpg", "fileSize": 1024}')
* `sys.argv[4]`: Absolute path to the directory that contains the source file (Ex: '/dmx/examples/sample_data')

Expected result to be returned from DMX verify script:
* A JSON string format

``` bash
'{"status": "PASSED", "reason": "Good", "tags": []}'
```

### DMX verify script example
This script can run with data set in `/dmx/examples/dmxtags/sample_data`

``` bash
#!/usr/bin/python3

import sys
import json

status = 'PASSED'
reason = 'Good'
tag = []

# UDS operation: INGEST, EXPORT, COPY/MOVE
uds_operation = sys.argv[1]
# 'sys.argv[2]' example:
# '{"fileName": "filename.jpg", "fileSize": 1024}'
# '{"fileName": "file1.txt", "fileSize": 10, "customInfo": {"tags": ["TAG_1", "TAG_2"]}}'
manifest_file_info_str = sys.argv[2]
# Convert the manifest file info from string format to dictionary.
manifest_file_info_dict = json.loads(manifest_file_info_str)
# Parameter that gets passed into the script is the absolute path to the source volume
# Example: /root/.uds/ingested/.uds/data_store/324cc1dcd320482cafa6677dd8de91a7
data_path = sys.argv[3]
# An free form string that gets passed on UDS task create
dmx_option = sys.argv[4]

# Add verify logic here

# Build result
result = {
    "status": status,
    "reason": reason
}

print(result)
```

### Note:

Below is UDS task create in JSON format. "dmxOption" is an optional parameter that gets
passed into DMX script if provided.

```
{
  "category": "INGEST",
  "filter": "string",
  "sourceUri": "string",
  "destinationUri": "string",
  "sourceCredentials": {
    "accessKey": "string",
    "secretKey": "string"
  },
  "destinationCredentials": {
    "accessKey": "string",
    "secretKey": "string"
  },
  "userId": "string",
  "deduplicate": true,
  "verify": true,
  "orchestrationMode": "ENTERPRISE_PERFORMANCE",
  "jsonPathFilter": [
    "string"
  ],
  "dmxOption": "string"
}
```