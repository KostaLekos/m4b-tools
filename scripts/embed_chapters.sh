#!/bin/bash

read -p "Enter path to .cue chapter file: " CUE_FILE
read -p "Enter path to input .m4b file: " INPUT_M4B
read -p "Enter desired output path for new .m4b file (incliding filename): " OUTPUT_M4B

# Validate inputs
if [[ ! -f "$CUE_FILE" ]]; then
  echo "Error: Cue file '$CUE_FILE' does not exist."
  exit 1
fi

if [[ ! -f "$INPUT_M4B" ]]; then
  echo "Error: Input m4b file '$INPUT_M4B' does not exist."
  exit 1
fi

if [[ -z "$OUTPUT_M4B" ]]; then
  echo "Error: Output path cannot be empty."
  exit 1
fi

# Check ffmpeg
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is required but not installed."
  exit 1
fi

# Manual cue to ffmetadata converter with proper END timestamps
cue_to_ffmetadata() {
  local cue="$1"
  local out="$2"
  
  echo ";FFMETADATA1" > "$out"

  local track=0
  local -a starts titles

  while IFS= read -r line; do
    if [[ "$line" =~ ^TRACK ]]; then
      ((track++))
    fi
    if [[ "$line" =~ ^INDEX[[:space:]]+01[[:space:]]+([0-9]{2}):([0-9]{2}):([0-9]{2}) ]]; then
      mm=${BASH_REMATCH[1]}
      ss=${BASH_REMATCH[2]}
      ff=${BASH_REMATCH[3]}
      # Convert mm:ss:ff (frames at 75 fps) to milliseconds
      total_ms=$((10#$mm*60*1000 + 10#$ss*1000 + 10#$ff*1000/75))
      starts[$track]=$total_ms
    fi
    if [[ "$line" =~ ^TITLE[[:space:]]+\"(.+)\" ]]; then
      titles[$track]="${BASH_REMATCH[1]}"
    fi
  done < "$cue"

  for ((i=1; i<=track; i++)); do
    echo "[CHAPTER]" >> "$out"
    echo "TIMEBASE=1/1000" >> "$out"
    echo "START=${starts[i]}" >> "$out"
    if (( i < track )); then
      # END = start of next chapter - 1ms
      end=$((starts[i+1]-1))
      (( end < 0 )) && end=0
      echo "END=$end" >> "$out"
    fi
    echo "title=${titles[i]}" >> "$out"
  done
}

# Create temporary ffmetadata file
FFMETADATA=$(mktemp)

# Try direct ffmpeg cue conversion first (may lose tags/cover)
ffmpeg -i "$CUE_FILE" -f ffmetadata "$FFMETADATA" 2>/dev/null

if [[ ! -s "$FFMETADATA" ]]; then
  echo "Direct ffmpeg cue parsing failed, using manual converter."
  cue_to_ffmetadata "$CUE_FILE" "$FFMETADATA"
fi

# Embed chapters preserving original metadata and cover art
# -map 0 copies all streams from original m4b (audio, cover, metadata)
# -map_metadata 0 copies metadata from input m4b (author, narrator, etc)
# -map_metadata:s:1 1 sets stream metadata from ffmetadata (chapters)
ffmpeg -y -i "$INPUT_M4B" -i "$FFMETADATA" \
  -map 0:a -map 0:v? -map_metadata 0 -map_metadata:s:1 1 \
  -c copy \
  -metadata vendor_id= \
  "$OUTPUT_M4B"

RET=$?

rm "$FFMETADATA"

if [[ $RET -ne 0 ]]; then
  echo "Error: ffmpeg failed to embed chapters."
  exit 1
fi

echo "Chapters successfully embedded into '$OUTPUT_M4B'"
