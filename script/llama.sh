#!/bin/bash

# ================================
#  AI-POWERED SEO META GENERATOR
# ================================
# - Supports LLaMA-7B, GPT-J-6B, Mistral-7B (auto-install)
# - Generates SEO-friendly metadata & structured data
# - Fully autonomous and API-free
# - Competitor & Backlink Analysis for better ranking
# ================================

# Ensure at least two arguments are provided
if [ "$#" -lt 2 ]; then
  echo "Usage: meta_ai_generator.sh <tool_name> <operation>"
  exit 1
fi

TOOL_NAME="$1"
REQUEST_TYPE="$2"

echo "[LOG] Starting AI SEO generation for: $TOOL_NAME with operation: $REQUEST_TYPE"

# === DETECT SYSTEM TYPE ===
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
  "Linux") MODEL_DIR="$HOME/.local/models" ;;
  "Darwin") MODEL_DIR="$HOME/Library/Application Support/models" ;; # macOS
  "CYGWIN"|"MINGW"|"MSYS") MODEL_DIR="$APPDATA/models" ;; # Windows (Git Bash, Cygwin, WSL)
  *) MODEL_DIR="/usr/local/models" ;; # Fallback
esac

mkdir -p "$MODEL_DIR"

# === AI MODEL SELECTION ===
echo "Select the AI model for text generation:"
echo "1) LLaMA-7B (most accurate, slower)"
echo "2) GPT-J-6B (faster, less detailed)"
echo "3) Mistral-7B (balanced, good quality)"
read -p "Enter the number of the model you want to use: " MODEL_CHOICE

case "$MODEL_CHOICE" in
  1) MODEL_NAME="llama-7b" ; MODEL_URL="https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf" ;;
  2) MODEL_NAME="gptj-6b" ; MODEL_URL="https://huggingface.co/TheBloke/GPT-J-6B-GGUF/resolve/main/gpt-j-6b.Q4_K_M.gguf" ;;
  3) MODEL_NAME="mistral-7b" ; MODEL_URL="https://huggingface.co/TheBloke/Mistral-7B-GGUF/resolve/main/mistral-7b.Q4_K_M.gguf" ;;
  *) echo "Invalid selection. Defaulting to LLaMA-7B."; 
     MODEL_NAME="llama-7b"
     MODEL_URL="https://huggingface.co/TheBloke/Llama-2-7B-GGUF/resolve/main/llama-2-7b.Q4_K_M.gguf"
     ;;
esac

MODEL_PATH="$MODEL_DIR/$MODEL_NAME.gguf"

# === CHECK & INSTALL REQUIRED MODELS ===
if [ ! -f "$MODEL_PATH" ]; then
  echo "The selected AI model is not installed. Do you want to download it automatically? (y/n)"
  read -p "Answer: " INSTALL_MODEL
  if [ "$INSTALL_MODEL" == "y" ]; then
    echo "Downloading $MODEL_NAME model in GGUF format..."
    wget -O "$MODEL_PATH" "$MODEL_URL"

    # Verify if the model was downloaded correctly
    if [ $? -ne 0 ]; then
      echo "Error: Failed to download the model. Exiting."
      exit 1
    fi

    echo "Model downloaded successfully!"
  else
    echo "Process stopped. Install the model manually and try again."
    exit 1
  fi
fi

# === INSTALL & SETUP LLaMA.CPP IF MISSING (CMAKE) ===
LLAMA_DIR="$HOME/.local/llama.cpp"
LLAMA_BIN_DIR="$LLAMA_DIR/build/bin"

if [ ! -d "$LLAMA_DIR" ]; then
  echo "LLaMA.CPP is missing. Installing it now..."
  git clone https://github.com/ggerganov/llama.cpp "$LLAMA_DIR"
fi

# Install CMake if missing
if ! command -v cmake &> /dev/null; then
  echo "CMake is not installed. Installing it now..."
  sudo apt update && sudo apt install -y cmake
fi

# Build llama.cpp using CMake
echo "Building LLaMA.CPP using CMake..."
cd "$LLAMA_DIR"
mkdir -p build && cd build
cmake ..
make -j$(nproc)

# Detect available LLaMA binary
if [ -f "$LLAMA_BIN_DIR/llama-server" ]; then
  LLAMA_EXEC="$LLAMA_BIN_DIR/llama-server"
elif [ -f "$LLAMA_BIN_DIR/llama" ]; then
  LLAMA_EXEC="$LLAMA_BIN_DIR/llama"
elif [ -f "$LLAMA_BIN_DIR/llama-cli" ]; then
  LLAMA_EXEC="$LLAMA_BIN_DIR/llama-cli"
else
  echo "Error: No valid LLaMA.CPP executable found. Exiting."
  exit 1
fi

echo "Using LLaMA executable: $LLAMA_EXEC"

# === NORMALIZE TOOL NAME FOR SEO ===
normalize_tool_name() {
  echo "$TOOL_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}
NORMALIZED_NAME=$(normalize_tool_name)

# === AI-POWERED TEXT GENERATION ===
generate_ai_text() {
  PROMPT="$1"
  echo "$PROMPT" | "$LLAMA_EXEC" -m "$MODEL_PATH" -n 150 --temp 0.7 --top-k 50
}

# === SEO FUNCTIONS ===

# Meta Description
generate_meta_description() {
  echo "Generating meta description for: $TOOL_NAME..."
  generate_ai_text "Create a compelling SEO-friendly meta description for a tool called $TOOL_NAME."
}

# Meta Keywords
generate_meta_keywords() {
  echo "Generating meta keywords for: $TOOL_NAME..."
  generate_ai_text "Generate a list of 10 high-ranking SEO keywords for $TOOL_NAME."
}

# Competitor Analysis
generate_competitor_analysis() {
  echo "Performing Competitor Analysis for: $TOOL_NAME..."
  generate_ai_text "Analyze top competitors for $TOOL_NAME in the current SERP rankings and suggest improvements."
}

# === PROCESS REQUEST ===
case "$REQUEST_TYPE" in
  "description") generate_meta_description ;;
  "meta_keywords") generate_meta_keywords ;;
  "competitor_analysis") generate_competitor_analysis ;;
  *) 
    echo "Invalid request type. Use one of the following:"
    echo "description, meta_keywords, competitor_analysis"
    exit 1
    ;;
esac