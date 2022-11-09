#!/bin/bash

INPUT_SETTINGS_FILE=${1}

cat <<EOF >> /tmp/pyscript.py
import pathlib

input_path = pathlib.Path("${INPUT_SETTINGS_FILE}").resolve()

text = input_path.read_text()
text = text.replace("conn_max_age=600,", "conn_max_age=600, ssl_require=False,", 1)

input_path.write_text(text)
EOF


python /tmp/pyscript.py
