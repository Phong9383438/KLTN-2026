import google.generativeai as genai
import os
from dotenv import load_dotenv
from flask import Flask, request, jsonify

# 1. Load environment variables from the .env file
load_dotenv()

# 2. Retrieve the API key securely
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("Error: GEMINI_API_KEY is missing. Please check your .env file.")

# 3. Configure the Gemini API
genai.configure(api_key=api_key)

# Initialize API Server
app = Flask(__name__)

def get_fake_response(attacker_command):
    """
    Simulates a vulnerable Ubuntu Linux terminal output using Gemini API.
    """
    # System Instruction to define the AI's persona as a Linux environment
    system_instruction = """
    You are a vulnerable Ubuntu 22.04 LTS server. 
    Your task is to ONLY return the exact command-line output that a Linux terminal would print.
    DO NOT explain your answers. DO NOT use Markdown formatting (like ```bash) unless it is the actual output.
    If a command fails, print the standard bash error message.
    The current user is 'www-data'. The current directory is '/var/www/html'.
    """

    # Initialize the model with the system prompt
    model = genai.GenerativeModel(
        model_name='gemini-3.6-flash',
        system_instruction=system_instruction
    )

    # Generate and return the simulated terminal output
    try:
        response = model.generate_content(attacker_command)
        return response.text
    except Exception as e:
        return f"bash: error processing command: {e}"

# 4. Define the API route to receive commands from the Cowrie Honeypot
@app.route('/ask_ai', methods=['POST'])
def handle_ask_ai():
    # Extract the command entered by the attacker from the incoming JSON request
    data = request.json
    attacker_cmd = data.get('command', '')

    # Process the command through the Gemini API
    fake_output = get_fake_response(attacker_cmd)

    # Package the simulated output into a JSON response for Cowrie to render
    return jsonify({"fake_output": fake_output})

if __name__ == "__main__":
    # Start the Flask server, binding it specifically to the Controller's Tailscale IP
    print("Starting Gemini Proxy Server on Tailscale network...")
    app.run(host='100.88.136.106', port=5000)
