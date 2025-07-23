#!/bin/bash

bash run-one.sh 2>&1 | grep -E 'Sent|Value|RSS'
