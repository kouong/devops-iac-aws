#!/bin/bash
# This script installs dependencies needed for a Flask web application

# Install Python 3 and pip package manager using yum (for Amazon Linux/RHEL/CentOS)
yum install -y python3-pip

# Install Flask web framework using pip3
pip3 install flask
