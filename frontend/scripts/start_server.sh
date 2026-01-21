#!/bin/bash

# Change to the web application directory
cd /home/ec2-user/simple-webapp

# Start the Python web app in the background
# nohup: keeps the process running even after logout
# > app.log: redirects standard output to app.log file
# 2>&1: redirects error messages to the same log file
# &: runs the command in background
nohup python3 app.py > app.log 2>&1 &
