#!/bin/bash

# File containing the list of URLs
URL_FILE="urls.txt"

# Check if the file exists
if [ ! -f "$URL_FILE" ]; then
  echo "URL file not found: $URL_FILE"
  exit 1
fi

# Loop through each line (URL) in the file
while IFS= read -r DOMAIN || [ -n "$DOMAIN" ]; do
  # Skip empty lines
  if [ -z "$DOMAIN" ]; then
    continue
  fi

  # Check the SSL expiration date
  EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

  # Skip invalid URLs (if no expiry date is found)
  if [ -z "$EXPIRY_DATE" ]; then
    echo "Skipping invalid or unreachable URL: $DOMAIN"
    continue
  fi

  # Convert expiry date to seconds since epoch
  EXPIRY_IN_SECONDS=$(date -d "$EXPIRY_DATE" +%s)
  CURRENT_DATE_IN_SECONDS=$(date +%s)

  # Calculate days until expiration
  DAYS_UNTIL_EXPIRY=$(( (EXPIRY_IN_SECONDS - CURRENT_DATE_IN_SECONDS) / 86400 ))

  # Output the result
  if [ "$DAYS_UNTIL_EXPIRY" -le 0 ]; then
    echo "The SSL certificate for $DOMAIN has expired."
  else
    echo "The SSL certificate for $DOMAIN will expire in $DAYS_UNTIL_EXPIRY days."
  fi
done < "$URL_FILE"

