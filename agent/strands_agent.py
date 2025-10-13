from strands import Agent, tool
from strands_tools import calculator # Import the calculator tool
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

model_id = "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
model = BedrockModel(
    model_id=model_id,
)

agent = Agent(
    model=model,
    tools=[calculator, weather],
    system_prompt="You're a helpful assistant. You can do simple math calculation, and tell the weather."
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
    
    return response_text

if __name__ == "__main__":
    app.run()
