#!/bin/bash

# Kill any running processes that match "app.py" in their command line
# The "|| true" ensures the script doesn't fail if no matching processes are found
pkill -f app.py || true
