import google.generativeai as genai
import os
from dotenv import load_dotenv

# 1. Load environment variables from the .env file
load_dotenv()

# 2. Retrieve the API key securely
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    raise ValueError("Error: GEMINI_API_KEY is missing. Please check your .env file.")

# 3. Configure the Gemini API
genai.configure(api_key=api_key)

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

# Internal testing block
if __name__ == "__main__":
    test_cmd = "cat /etc/passwd"
    print(f"Attacker executed: {test_cmd}")
    print("-" * 30)
    print(get_fake_response(test_cmd))
