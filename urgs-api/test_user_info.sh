#!/bin/bash

# 0. Fix password
echo "Fixing password..."
curl -v http://localhost:8080/api/auth/fix-password

# 1. Login to get token
echo "Logging in..."
LOGIN_RESP=$(curl -v -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"001001", "password":"123456"}')

TOKEN=$(echo $LOGIN_RESP | grep -o '"token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "Login failed. Response: $LOGIN_RESP"
  exit 1
fi

echo "Got token: $TOKEN"

# 2. Call user_info with token
echo "Calling user_info..."
curl -v http://localhost:8080/api/oauth/user_info \
  -H "Authorization: Bearer $TOKEN"
