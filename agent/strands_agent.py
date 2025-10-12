from strands import Agent, tool
from strands_tools import calculator # Import the calculator tool
import argparse
import json
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands.models import BedrockModel

# Create the AgentCore app
app = BedrockAgentCoreApp()

# Create a custom tool
@tool
def weather():
    """Get the current weather. Always returns sunny weather."""
    return "It's sunny and 72°F today!"

#model_id = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
model_id = "amazon.nova-micro-v1:0"
model = BedrockModel(
    model_id=model_id,
)

agent = Agent(
    model=model,
    tools=[calculator, weather],
    system_prompt="You're a helpful assistant. You can do simple math calculations and tell the weather. When asked about weather, always use the weather tool - don't ask for a location, just call the tool directly."
)

@app.entrypoint
def strands_agent_bedrock(payload):
    """
    Invoke the agent with a payload
    
    IMPORTANT: Payload structure varies depending on invocation method:
    - Direct invocation (Python SDK, Console, agentcore CLI): {"prompt": "..."}
    - AWS SDK invocation (JS/Java/etc via InvokeAgentRuntimeCommand): {"input": {"prompt": "..."}}
    
    The AWS SDK automatically wraps payloads in an "input" field as part of the API contract.
    This function handles both formats for maximum compatibility.
    """
    import re
    
    # Handle both dict and string payloads
    if isinstance(payload, str):
        payload = json.loads(payload)
    
    # Extract the prompt from the payload
    # Try AWS SDK format first (most common for production): {"input": {"prompt": "..."}}
    # Fall back to direct format: {"prompt": "..."}
    user_input = None
    if isinstance(payload, dict):
        if "input" in payload and isinstance(payload["input"], dict):
            user_input = payload["input"].get("prompt")
        else:
            user_input = payload.get("prompt")
    
    if not user_input:
        raise ValueError(f"No prompt found in payload. Expected {{'prompt': '...'}} or {{'input': {{'prompt': '...'}}}}. Received: {payload}")
    
    response = agent(user_input)
    response_text = response.message['content'][0]['text']
    
    # Strip <thinking> and <response> tags from Nova model responses
    response_text = re.sub(r'<thinking>.*?</thinking>\s*', '', response_text, flags=re.DOTALL)
    response_text = re.sub(r'<response>(.*?)</response>', r'\1', response_text, flags=re.DOTALL)
    
    # Remove surrounding quotes if the entire response is wrapped in quotes
    response_text = response_text.strip()
    if response_text.startswith('"') and response_text.endswith('"'):
        response_text = response_text[1:-1]
    
    return response_text

if __name__ == "__main__":
    app.run()
