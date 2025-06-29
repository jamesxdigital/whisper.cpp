#!/bin/bash
# Smart whisper.cpp wrapper: handles WAV directly, converts other formats automatically
# Supports any format that ffmpeg can read: M4A, MP3, MP4, MOV, AVI, MKV, FLAC, OGG, etc.
# Automatically creates .txt output files unless another output format is specified
# Usage: whispercpp-convert.sh [whisper-cli options] -f <audio_or_video_file>

set -e

# Cleanup function for temporary files and processes
cleanup() {
    # Kill any running ffmpeg processes started by this script
    if [[ -n "$FFMPEG_PID" ]]; then
        echo "Stopping ffmpeg conversion..."
        kill -TERM "$FFMPEG_PID" 2>/dev/null || true
        wait "$FFMPEG_PID" 2>/dev/null || true
    fi
    
    # Kill any running whisper-cli processes started by this script
    if [[ -n "$WHISPER_PID" ]]; then
        echo "Stopping whisper transcription..."
        kill -TERM "$WHISPER_PID" 2>/dev/null || true
        wait "$WHISPER_PID" 2>/dev/null || true
    fi
    
    # Clean up temporary files
    if [[ -n "$TEMP_WAV" ]] && [[ -f "$TEMP_WAV" ]]; then
        echo "Cleaning up temporary file: $TEMP_WAV"
        rm -f "$TEMP_WAV"
    fi
}

# Set up signal handlers for cleanup on exit/interrupt
trap cleanup EXIT INT TERM

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is required but not installed"
    exit 1
fi

# Find the input file (look for -f flag)
INPUT_FILE=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            INPUT_FILE="$2"
            shift 2
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Check if input file was provided
if [ -z "$INPUT_FILE" ]; then
    echo "Error: No input file specified (use -f flag)"
    echo "Usage: $(basename "$0") [options] -f <audio_file>"
    exit 1
fi

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file not found: $INPUT_FILE"
    exit 1
fi

# Get file info
INPUT_DIR=$(dirname "$INPUT_FILE")
INPUT_BASENAME=$(basename "$INPUT_FILE")
INPUT_NAME="${INPUT_BASENAME%.*}"
INPUT_EXT="${INPUT_BASENAME##*.}"

# Convert extension to lowercase
INPUT_EXT_LOWER=$(echo "$INPUT_EXT" | tr '[:upper:]' '[:lower:]')

# Check if file has audio stream
if ! ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$INPUT_FILE" &>/dev/null; then
    echo "Error: No audio stream found in file: $INPUT_FILE"
    exit 1
fi

# Handle WAV files directly or convert other formats
if [[ "$INPUT_EXT_LOWER" == "wav" ]]; then
    echo "Using WAV file directly"
    # Add default model if not specified
    if [[ ! " ${ARGS[@]} " =~ " -m " ]] && [[ ! " ${ARGS[@]} " =~ " --model " ]]; then
        ARGS+=("-m" "$HOME/Tools/whisper.cpp/models/ggml-large-v3-turbo.bin")
    fi
    # Add default threads if not specified
    if [[ ! " ${ARGS[@]} " =~ " -t " ]] && [[ ! " ${ARGS[@]} " =~ " --threads " ]]; then
        ARGS+=("-t" "12")
    fi
    # Add default text output if no output format specified
    if [[ ! " ${ARGS[@]} " =~ " -otxt " ]] && [[ ! " ${ARGS[@]} " =~ " --output-txt " ]] && \
       [[ ! " ${ARGS[@]} " =~ " -ovtt " ]] && [[ ! " ${ARGS[@]} " =~ " --output-vtt " ]] && \
       [[ ! " ${ARGS[@]} " =~ " -osrt " ]] && [[ ! " ${ARGS[@]} " =~ " --output-srt " ]] && \
       [[ ! " ${ARGS[@]} " =~ " -ocsv " ]] && [[ ! " ${ARGS[@]} " =~ " --output-csv " ]] && \
       [[ ! " ${ARGS[@]} " =~ " -oj " ]] && [[ ! " ${ARGS[@]} " =~ " --output-json " ]] && \
       [[ ! " ${ARGS[@]} " =~ " -olrc " ]] && [[ ! " ${ARGS[@]} " =~ " --output-lrc " ]]; then
        ARGS+=("--output-txt")
    fi
    # Run whisper.cpp directly on the WAV file
    echo "Running whisper.cpp..."
    "$HOME/Tools/whisper.cpp/build/bin/whisper-cli" "${ARGS[@]}" -f "$INPUT_FILE"
    echo "Done!"
    exit 0
else
    # Extract audio from any format (video or audio) and convert to 16kHz mono WAV
    echo "Converting $INPUT_EXT to 16kHz mono WAV..."
    WAV_FILE="$INPUT_DIR/${INPUT_NAME}.wav"
    TEMP_WAV="$WAV_FILE"  # Mark as temporary for cleanup
    ffmpeg -i "$INPUT_FILE" -vn -ar 16000 -ac 1 -c:a pcm_s16le "$WAV_FILE" -y -loglevel error &
    FFMPEG_PID=$!
    wait $FFMPEG_PID
fi

# Add default model if not specified
if [[ ! " ${ARGS[@]} " =~ " -m " ]] && [[ ! " ${ARGS[@]} " =~ " --model " ]]; then
    ARGS+=("-m" "$HOME/Tools/whisper.cpp/models/ggml-large-v3-turbo.bin")
fi

# Add default threads if not specified
if [[ ! " ${ARGS[@]} " =~ " -t " ]] && [[ ! " ${ARGS[@]} " =~ " --threads " ]]; then
    ARGS+=("-t" "12")
fi

# Add default text output if no output format specified
if [[ ! " ${ARGS[@]} " =~ " -otxt " ]] && [[ ! " ${ARGS[@]} " =~ " --output-txt " ]] && \
   [[ ! " ${ARGS[@]} " =~ " -ovtt " ]] && [[ ! " ${ARGS[@]} " =~ " --output-vtt " ]] && \
   [[ ! " ${ARGS[@]} " =~ " -osrt " ]] && [[ ! " ${ARGS[@]} " =~ " --output-srt " ]] && \
   [[ ! " ${ARGS[@]} " =~ " -ocsv " ]] && [[ ! " ${ARGS[@]} " =~ " --output-csv " ]] && \
   [[ ! " ${ARGS[@]} " =~ " -oj " ]] && [[ ! " ${ARGS[@]} " =~ " --output-json " ]] && \
   [[ ! " ${ARGS[@]} " =~ " -olrc " ]] && [[ ! " ${ARGS[@]} " =~ " --output-lrc " ]]; then
    ARGS+=("--output-txt")
fi

# Run whisper.cpp with the converted file
echo "Running whisper.cpp..."
"$HOME/Tools/whisper.cpp/build/bin/whisper-cli" "${ARGS[@]}" -f "$WAV_FILE" &
WHISPER_PID=$!
wait $WHISPER_PID

echo "Done!"