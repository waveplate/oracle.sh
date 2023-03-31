# oracle.sh
listens to your microphone and generates text-to-speech responses, providing an interactive and real-time conversation with chatgpt

# dependencies
- sox
- jq
- festival
- curl

# usage

add your `OPENAI_API_KEY` to your `~/.bashrc` file

`export OPENAI_API_KEY=<KEY>`

`$ ./oracle.sh`

or

`$ OPENAI_API_KEY=<KEY> ./oracle.sh`

then simply speak into your microphone and listen for chatgpt's response
