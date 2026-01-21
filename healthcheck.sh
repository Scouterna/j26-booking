#!/bin/sh
# Health check script for j26booking application
# Verifies the application is responding to HTTP requests

wget --no-verbose --tries=1 --spider "http://localhost:${PORT:-8000}/" || exit 1
