# m4b-tools

Currently only tested on Linux (Arch).

If you run into any errors, it would be greatly appreciated if you reported them.


## Installion
- Open the scripts folder
- Pick your desired script
- Download it


## Use


### embed_champters.sh

A Bash script for embedding chapters from a ``.cue`` file into an existing .m4b audiobook, while preserving metadata and cover art.

#### Features

- Parses ``.cue`` files to generate chapter metadata for ``.m4b`` audiobooks.

- Preserves original metadata (e.g., author, narrator) and cover art.

- Handles ``.cue`` files even if they can't be parsed directly by ``ffmpeg``.

- Outputs a new ``.m4b`` file with chapters.

#### Prerequisites

- **ffmpeg**: Must be installed and available in your ``PATH``.

#### Usage

Run the script and follow the prompts (script can be run from any folder and files can be in any folder):
```./embed_chapters.sh```

You'll be asked to provide:

- The path to the ``.cue`` file with chapter information.

- The path to the input ``.m4b`` file (original audiobook).

- The desired output path and filename for the new ``.m4b`` file.

Example:
```
Enter path to .cue chapter file: /path/to/chapters.cue
Enter path to input .m4b file: /path/to/audiobook.m4b
Enter desired output path for new .m4b file (including filename): /path/to/audiobook_with_chapters.m4b
```

#### Notes

- The script creates a temporary ``ffmetadata`` file to store chapter data.

- If ``ffmpeg`` fails to parse the ``.cue`` file directly, the script uses a manual parser.

- The output ``.m4b`` retains all streams, including audio and cover art.

#### Limitations

- Designed for ``.cue`` files using standard formatting (``TRACK``, ``INDEX``, and ``TITLE`` lines).

- Chapters must be defined in the ``.cue`` file using ``INDEX 01`` entries.

- Timestamps in ``.cue`` files are converted from MM:SS:FF (75 fps) to milliseconds.




### mp3_to_m4b.sh

A Bash script to convert a folder of ``.mp3`` files into a single ``.m4b`` audiobook, complete with chapters and optional cover art.

#### Features

- Converts multiple ``.mp3`` files into a single ``.m4b`` audiobook.

- Generates chapters based on the ``.mp3`` file order (alphabetical) and durations.

- Supports adding cover art (optional).

- Uses ``mp4chaps`` to embed chapter information.

- Outputs a clean ``.m4b`` file at 128kbps AAC audio (industry standard).

#### Prerequisites

- **ffmpeg**: For audio and video processing.

- **mp4chaps**: For adding chapter metadata to the final ``.m4b`` file.

- ``find``, ``sort``, and standard GNU utilities.

#### Usage

Run the script and follow the prompts (script can be run from any folder and files can be in any folder):
```./mp3_to_m4b.sh```

You will be asked for:

- The input folder path containing ``.mp3`` files.

- The desired output file path (including filename, e.g., ``audiobook.m4b``).

- An optional cover image file (e.g., ``.jpg`` or ``.png``).

Example:
```
📂 Input folder path (MP3s): /path/to/mp3s
📝 Output file path (including filename): /path/to/output/audiobook.m4b
🎨 Cover image file path (optional): cover.jpg
```

The script will:

1. Scan and sort all ``.mp3`` files in the input directory.

2. Generate a chapter file (``.chapters.txt``) with timestamps.

3. Concatenate all ``.mp3`` files into one ``.m4b`` file, with optional cover art.

4. Embed chapter information into the ``.m4b``.

5. Clean up temporary files.

#### Output

- The final ``.m4b`` audiobook file at the path you specified.

- Embedded chapters matching the order of ``.mp3`` files (again alphabetical).

- Cover art embedded if provided.

#### Notes

- The script assumes ``.mp3`` files are named and ordered as you want them in the final audiobook.

- Chapter timestamps are based on the cumulative durations of each ``.mp3``.

- ``mp4chaps`` is required for embedding chapters—install it via your package manager.

- Cover art must be a valid image file (e.g., ``.jpg`` or ``.png``).

