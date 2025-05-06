import os
import sys
import base64
import google.generativeai as genai

CONFIG_PATH = os.path.expanduser("~/.linux_auditor_config")

def load_config():
    config = {}
    if os.path.isfile(CONFIG_PATH):
        with open(CONFIG_PATH) as f:
            for line in f:
                if line.strip() and not line.strip().startswith("#"):
                    key, _, value = line.partition("=")
                    config[key.strip()] = value.strip()
    return config

def decode_api_key(encoded_key):
    try:
        return base64.b64decode(encoded_key.encode()).decode()
    except Exception as e:
        print(f"Error decoding API key: {e}")
        sys.exit(1)

def ask_question(api_key, question, model_name):
    decoded_key = decode_api_key(api_key)
    genai.configure(api_key=decoded_key)
    model = genai.GenerativeModel(model_name)
    response = model.generate_content(question)
    print(response.text)

def analyze_report(api_key, filepath, model_name):
    with open(filepath, "r") as f:
        content = f.read()
    decoded_key = decode_api_key(api_key)
    genai.configure(api_key=decoded_key)
    model = genai.GenerativeModel(model_name)
    prompt = f"Please analyze this Linux audit report and give me security insights:\n{content}"
    response = model.generate_content(prompt)
    print(response.text)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 gemini_client.py <ask|analyze> [args...]")
        sys.exit(1)

    config = load_config()
    api_key = config.get("AI_API_KEY")
    model_name = config.get("AI_MODEL", "gemini-2.0-flash-lite")

    if not api_key:
        print("API key not found in ~/.linux_auditor_config")
        sys.exit(1)

    action = sys.argv[1]

    if action == "ask" and len(sys.argv) >= 3:
        question = " ".join(sys.argv[2:])
        ask_question(api_key, question, model_name)
    elif action == "analyze" and len(sys.argv) >= 3:
        analyze_report(api_key, sys.argv[2], model_name)
    else:
        print("Invalid usage. For ask: python3 gemini_client.py ask <question>")
        print("For analyze: python3 gemini_client.py analyze <report_file>")
