#!/bin/bash
set -e

# Configure config.toml with Groq settings if environment variables are set
if [ -n "${GROQ_API_KEY:-}" ] && [ -n "${GROQ_MODEL:-}" ]; then
  if [ -f "config.toml" ]; then
    python3 -c "
import toml
import os

# Load config
config = toml.load('config.toml')

# Ensure [app] section exists
if 'app' not in config:
    config['app'] = {}

# Set Groq/OpenAI-compatible settings
config['app']['llm_provider'] = 'openai'
config['app']['openai_api_key'] = os.environ['GROQ_API_KEY']
config['app']['openai_base_url'] = 'https://api.groq.com/openai/v1'
config['app']['openai_model_name'] = os.environ['GROQ_MODEL']

# Write back
with open('config.toml', 'w') as f:
    toml.dump(config, f)
"
  fi
fi

# Execute the original entrypoint
exec streamlit run ./webui/Main.py --server.address=0.0.0.0 --server.port=8501 --browser.serverAddress=127.0.0.1 --server.enableCORS=True --browser.gatherUsageStats=False --client.toolbarMode=minimal --logger.hideWelcomeMessage=True --server.showEmailPrompt=False

