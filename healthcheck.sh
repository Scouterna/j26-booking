#!/bin/sh
# Health check script for j26booking application
# Verifies the application is responding to HTTP requests

wget --no-verbose --tries=1 --spider "http://127.0.0.1:${PORT:-8000}/" || exit 1
