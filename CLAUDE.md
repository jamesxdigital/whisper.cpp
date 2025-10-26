# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Branch Strategy

This repository uses a dual-branch workflow:

- **`master`** - Tracks upstream [ggml-org/whisper.cpp](https://github.com/ggml-org/whisper.cpp) exactly
  - Always kept in sync with upstream
  - No custom modifications
  - Fast-forward merges only

- **`james`** - Custom modifications branch (primary working branch)
  - Contains custom wrapper script and optimizations
  - Rebased on top of master regularly
  - Use this branch for daily work

### Syncing with Upstream

To update both branches with latest upstream changes:

```bash
# Update master from upstream
git checkout master
git fetch upstream
git merge upstream/master
git push origin master

# Rebase custom changes onto updated master
git checkout james
git rebase master
git push origin james --force-with-lease
```

## Common Development Commands

### Building the Project

```bash
# CMake build (recommended)
cmake -B build
cmake --build build --config Release

# Or use the Makefile shortcut
make build

# Build with specific backend support
cmake -B build -DGGML_CUDA=1        # NVIDIA GPU support
cmake -B build -DGGML_METAL=1       # Apple Metal support (macOS default)
cmake -B build -DGGML_VULKAN=1      # Vulkan GPU support
cmake -B build -DGGML_BLAS=1        # OpenBLAS support
cmake -B build -DWHISPER_COREML=1   # Core ML support (Apple)
cmake -B build -DWHISPER_OPENVINO=1 # OpenVINO support
cmake -B build -DWHISPER_SDL2=1     # SDL2 support for real-time audio
```

### Running Tests

```bash
# Run integration tests with a specific model
./tests/run-tests.sh base.en 4  # model_name threads

# The main test files are in tests/
# - test-c.c: C API tests
# - test-vad.cpp: Voice Activity Detection tests
# - test-whisper.js: JavaScript tests
```

### Model Download and Usage

```bash
# Download a model
./models/download-ggml-model.sh base.en

# Download VAD model for Voice Activity Detection
./models/download-vad-model.sh silero-v5.1.2

# Quick test with make (downloads model if needed)
make base.en  # Downloads and runs on all samples

# Run transcription
./build/bin/whisper-cli -m models/ggml-base.en.bin -f samples/jfk.wav

# With VAD enabled
./build/bin/whisper-cli -m models/ggml-base.en.bin -vm models/ggml-silero-v5.1.2.bin --vad -f samples/jfk.wav
```

### Quantization

```bash
# Quantize a model (reduces size/memory usage)
./build/bin/quantize models/ggml-base.en.bin models/ggml-base.en-q5_0.bin q5_0
```

## High-Level Architecture

whisper.cpp implements OpenAI's Whisper ASR model in C/C++ with a focus on performance and portability.

### Core Components

1. **Model Architecture** (`src/whisper-arch.h`):
   - Encoder-Decoder transformer architecture
   - Three main systems: ENCODER, DECODER, and CROSS (cross-attention)
   - Supports multiple model sizes (tiny, base, small, medium, large)

2. **Main Implementation** (`include/whisper.h`, `src/whisper.cpp`):
   - C API for model loading, inference, and result retrieval
   - Thread-safe context management
   - Supports streaming and batch processing

3. **GGML Integration**:
   - Uses ggml library for tensor operations and ML primitives
   - Custom binary format (.bin files) for efficient model storage
   - Multiple backend support (CPU, CUDA, Metal, Vulkan, etc.)

4. **Voice Activity Detection (VAD)**:
   - Optional VAD preprocessing to detect speech segments
   - Reduces processing time by skipping non-speech audio
   - Silero VAD model support

### Key Directories

- `include/`: Public C API header (whisper.h)
- `src/`: Core implementation files
- `ggml/`: GGML machine learning library (submodule)
- `models/`: Model conversion and download scripts
- `examples/`: Various usage examples (CLI, streaming, server, etc.)
- `bindings/`: Language bindings (Go, Java, JavaScript, Ruby, etc.)
- `tests/`: Test files and scripts

### Build System

The project uses CMake as the primary build system with optional Makefile shortcuts. Platform-specific optimizations are automatically detected and enabled (e.g., Metal on macOS, NEON on ARM).

### Model Format

Models are distributed in GGML format (.bin files) which pack:
- Model parameters and architecture
- Mel filterbank coefficients
- Vocabulary/tokenizer
- Quantized weights

The format is optimized for memory-mapped loading and minimal allocations at runtime.