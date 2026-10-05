#!/bin/bash
set -e

# Copy config.example.toml to config.toml if it doesn't exist
if [ ! -f "config.toml" ]; then
  cp config.example.toml config.toml
fi

# Configure config.toml with environment-based settings
python3 << 'PYTHON_EOF'
import toml
import os

config = toml.load('config.toml')

if 'app' not in config:
    config['app'] = {}

# Configure Pixabay if PIXABAY_API_KEY is set
# IMPORTANT: keys must live under config['app'], because material.py does:
#   api_key = config.app.get("pixabay_api_keys")
if os.environ.get('PIXABAY_API_KEY'):
    config['app']['video_source'] = 'pixabay'
    config['app']['pixabay_api_keys'] = [os.environ['PIXABAY_API_KEY']]
    # remove mistaken top-level key from older start.sh versions
    config.pop('pixabay_api_keys', None)

# Optional: FORCE_VIDEO_SOURCE=pixabay|pexels|...
if os.environ.get('FORCE_VIDEO_SOURCE'):
    config['app']['video_source'] = os.environ['FORCE_VIDEO_SOURCE'].strip()

# Configure Groq/OpenAI-compatible if GROQ_API_KEY and GROQ_MODEL are set
if os.environ.get('GROQ_API_KEY') and os.environ.get('GROQ_MODEL'):
    config['app']['llm_provider'] = 'openai'
    config['app']['openai_api_key'] = os.environ['GROQ_API_KEY']
    config['app']['openai_base_url'] = 'https://api.groq.com/openai/v1'
    config['app']['openai_model_name'] = os.environ['GROQ_MODEL']

with open('config.toml', 'w') as f:
    toml.dump(config, f)
PYTHON_EOF

# Start API in background (listens on 8080)
python main.py &

# Wait a moment for API to start
sleep 2

# Start streamlit in foreground (listens on 8501)
exec streamlit run ./webui/Main.py --server.address=0.0.0.0 --server.port=8501 --browser.serverAddress=127.0.0.1 --server.enableCORS=True --browser.gatherUsageStats=False --client.toolbarMode=minimal --logger.hideWelcomeMessage=True --server.showEmailPrompt=False
