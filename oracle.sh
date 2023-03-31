#!/bin/bash

# depends on
# - sox
# - jq
# - curl
# - festival

# say "exit" to exit the program
# say "stop" to stop the current TTS response

DEPENDENCIES=(sox jq curl festival)
MINIMUM_CHARS=10   # minimum number of characters to send to OpenAI
MAX_TOKENS=200     # maximum number of tokens to receive from OpenAI

for i in "${DEPENDENCIES[@]}"; do
  if ! command -v $i &> /dev/null
  then
    echo "$i could not be found"
    exit
  fi
done

trap "exit;" SIGINT SIGTERM

while true; do

  TIMESTAMP=$(date +%s)
  OUTPUT_FILE="/tmp/speech_$TIMESTAMP.wav"

  sox -q -d -r 16k -c 1 -e signed-integer -b 16 -t wav $OUTPUT_FILE silence 1 0.1 3% 1 0.5 3% trim 0 5 2>&1 >/dev/null

  echo "received speech..."

  if [ -s $OUTPUT_FILE ]; then

    echo "processing speech..."

    SPEECH=$(curl -s https://api.openai.com/v1/audio/transcriptions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: multipart/form-data" \
      -F file="@$OUTPUT_FILE" \
      -F model="whisper-1" | jq -r '.text')

    rm $OUTPUT_FILE

    if [[ $SPEECH == "exit"* ]] || [[ $SPEECH == "Exit"* ]]; then

      pkill -9 festival
      exit

    elif [[ $SPEECH == "stop"* ]] || [[ $SPEECH == "Stop"* ]]; then

      pkill -9 festival

    elif [[ ${#SPEECH} -gt $MINIMUM_CHARS ]]; then

      pkill -9 festival
      echo "sending speech to OpenAI: $SPEECH"

      RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{ \"model\": \"gpt-3.5-turbo\", \"messages\": [{\"role\": \"user\", \"content\": \"$SPEECH\"}], \"max_tokens\": $MAX_TOKENS }" \
        | jq -r '.choices[0].message.content' )
      
      echo "received response: $RESPONSE"

      RESPONSE=$(echo $RESPONSE | sed 's/"/\\"/g')

      festival -b "(SayText \"$RESPONSE\")" &

    fi

  else

    rm $OUTPUT_FILE

  fi

done
