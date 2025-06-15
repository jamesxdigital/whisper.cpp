# Whisper.cpp Usage Guide

Simple usage guide for the `whispercpp` command - one command that handles all audio and video formats.

## Quick Start

```bash
# Works with any audio/video format
whispercpp -l nl -f audio.m4a        # Dutch M4A file
whispercpp -l en -f video.mp4        # English video
whispercpp -f podcast.mp3            # Auto-detect language
```

## Common Options

### Language
```bash
whispercpp -l nl -f audio.m4a        # Dutch
whispercpp -l en -f video.mp4        # English
whispercpp -l de -f audio.flac       # German
whispercpp -l fr -f podcast.mp3      # French
whispercpp -l auto -f audio.m4a      # Auto-detect (default)
```

### Output Formats
```bash
whispercpp --output-txt -f audio.m4a     # Text (default)
whispercpp --output-srt -f video.mp4     # Subtitles
whispercpp --output-vtt -f audio.m4a     # WebVTT
whispercpp --output-json -f audio.m4a    # JSON (best for AI analysis)
whispercpp --output-csv -f audio.m4a     # CSV
```

### Performance
```bash
whispercpp -t 8 -f audio.m4a             # More threads (faster)
```

### Advanced Features
```bash
whispercpp --translate -f audio.m4a      # Translate to English
whispercpp --no-timestamps -f audio.m4a  # Clean text only
whispercpp -ml 1 -f audio.m4a            # Word-level timestamps
whispercpp --print-colors -f audio.m4a   # Confidence colors
```

## Common Use Cases

### Your Dutch Voice Memos
```bash
whispercpp -l nl -f "/Users/james.milton/Desktop/Admiraal de Ruijterweg 384-1 138.m4a"
whispercpp -l nl --output-json -f "voice-memo.m4a"  # For AI analysis
```

### Video Transcription
```bash
whispercpp -l en -f "lecture.mp4"        # Extract audio from video
whispercpp -l nl --output-srt -f "meeting.mov"  # Create subtitles
```

### Podcast/Audio Files
```bash
whispercpp -l en -f "podcast.mp3"
whispercpp -l de --output-json -f "interview.flac"
```

### Maximum Detail
```bash
whispercpp -l nl -ml 1 --print-colors --output-json -f "detailed-analysis.m4a"
```

## Supported Formats

**Audio:** M4A, MP3, FLAC, OGG, AAC, WMA, WAV, etc.
**Video:** MP4, MOV, AVI, MKV, WMV, FLV, WebM, etc.

- Automatically converts any format to the required 16kHz mono WAV
- Extracts audio from video files
- Uses WAV files directly if already in correct format

## Voice Activity Detection (VAD) - Optional Speed Boost

If you have long recordings with silence/pauses, VAD can provide ~30% speed improvement:

```bash
# Download VAD model first
./models/download-vad-model.sh silero-v5.1.2

# Use VAD (requires both flags)
whispercpp --vad -vm models/ggml-silero-v5.1.2.bin -l nl -f audio.m4a
```

## Model Management

```bash
# Download main model (if not already done)
./models/download-ggml-model.sh large-v3-turbo

# List available models
ls models/*.bin
```

## Help

```bash
whispercpp --help
```

## Your Most Common Command

For Dutch voice memos from your phone:
```bash
whispercpp -l nl -f "voice-memo.m4a"
```