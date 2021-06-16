#!/bin/bash

token="1103297755:AAGZgk8CBo8SRZ-H8GZpDOvN_Hkc0s4mfVw"
chatid="1346525877"

while read -r line;do
    message="$line"
    curl -s -X POST https://api.telegram.org/bot$token/sendMessage -d chat_id=$chatid -d text="$message"
done < "${1:-/dev/stdin}"




