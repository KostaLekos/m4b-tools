#!/bin/bash

# Get user input
read -rp "📂 Input folder path (MP3s): " input_dir
read -rp "📝 Output file path (including filename): " output_path
read -rp "🎨 Cover image file path (optional): " cover_image
#read -rp "👤 Author name (optional): " author

# Derive additional paths
chapter_file="${output_path%.m4b}.chapters.txt"
concat_file="/tmp/concat_list.txt"

# Create chapter file
echo "🔧 Creating chapter file: $chapter_file"
> "$chapter_file"

# Get MP3 list sorted
echo "📁 Scanning MP3 files in: $input_dir"
mapfile -d '' mp3_files < <(find "$input_dir" -maxdepth 1 -type f -iname "*.mp3" -print0)
IFS=$'\n' mp3_files=($(printf '%s\n' "${mp3_files[@]}" | sort))

# Generate chapter file
offset=0
for mp3 in "${mp3_files[@]}"; do
    filename="${mp3##*/}"
    title="${filename%.mp3}"

    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$mp3")
    duration=${duration%.*}

    if [[ -z "$duration" ]]; then
        echo "⚠️ Failed to get duration for: $mp3"
        continue
    fi

    hrs=$((offset / 3600))
    mins=$(((offset % 3600) / 60))
    secs=$((offset % 60))
    timestamp=$(printf "%02d:%02d:%02d.000" $hrs $mins $secs)

    echo "$timestamp $title" >> "$chapter_file"
    offset=$((offset + duration))
done

echo "📑 Chapter file content:"
cat "$chapter_file"
echo

# Build concat list
echo "🧱 Building concat list: $concat_file"
> "$concat_file"
for mp3 in "${mp3_files[@]}"; do
    echo "file '$mp3'" >> "$concat_file"
done

# Convert to M4B with cover and author metadata
echo "🎧 Converting to M4B at 128k: $output_path"
if [[ -f "$cover_image" ]]; then
    ffmpeg -f concat -safe 0 -i "$concat_file" -i "$cover_image" \
        -map 0:a -map 1:v \
        -c:a aac -b:a 128k \
        -c:v:0 mjpeg \
        -metadata author="$author" \
        -disposition:v:0 attached_pic \
        "$output_path"
else
    ffmpeg -f concat -safe 0 -i "$concat_file" \
        -c:a aac -b:a 128k \
        -metadata author="$author" \
        "$output_path"
fi

# Add chapters
echo "🏷️  Embedding chapters into: $output_path"
mp4chaps -i "$output_path"

# Cleanup
rm "$concat_file"
rm "$chapter_file"

echo "✅ M4B audiobook created with author and chapters: $output_path"
