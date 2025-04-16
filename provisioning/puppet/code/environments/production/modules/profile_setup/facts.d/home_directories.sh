#!/bin/bash

# Print home directories
echo "{\"home_directories\": ["
first=1
for dir in /home/*; do
  if [ $first -eq 1 ]; then
    first=0
  else
    echo ","
  fi
  echo -n "\"$dir\""
done
echo "],"

# Print owners and groups of home directories
echo "\"home_directories_owners\": {"
first=1
for dir in /home/*; do
  owner=$(stat -c "%U" "$dir")
  if [ $first -eq 1 ]; then
    first=0
  else
    echo ","
  fi
  echo -n "\"$dir\": \"$owner\""
done
echo "},"

echo "\"home_directories_groups\": {"
first=1
for dir in /home/*; do
  group=$(stat -c "%G" "$dir")
  if [ $first -eq 1 ]; then
    first=0
  else
    echo ","
  fi
  echo -n "\"$dir\": \"$group\""
done
echo "}"
echo "}"
