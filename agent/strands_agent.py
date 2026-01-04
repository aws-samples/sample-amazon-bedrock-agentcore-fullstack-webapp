import json
import os
from typing import Final
from bedrock_agentcore.memory.integrations.strands.config import AgentCoreMemoryConfig
from bedrock_agentcore.memory.integrations.strands.session_manager import AgentCoreMemorySessionManager
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent, tool
from strands_tools import calculator  # Import the calculator tool
from strands.models import BedrockModel

# Constant variables
AGENTCORE_MEMORY_ID: Final[str] = os.environ["AGENTCORE_MEMORY_ID"]
MODEL_ID: Final[str] = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
MODEL: Final[BedrockModel] = BedrockModel(model_id=MODEL_ID)

# Create the AgentCore app
app = BedrockAgentCoreApp()


# Create a custom tool
@tool
def weather():
    """Get the current weather. Always returns sunny weather."""
    return "It's sunny and 72°F today!"


@app.entrypoint
async def agent_invocation(payload):
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

    # Extract the prompt, actorId, and sessionId from the payload
    # Try AWS SDK format first (most common for production): {"input": {"prompt": "...", "actorId": "...", "sessionId": "..."}}
    # Fall back to direct format: {"prompt": "...", "actorId": "...", "sessionId": "..."}
    user_input = None
    actor_id = None
    session_id = None

    if isinstance(payload, dict):
        if "input" in payload and isinstance(payload["input"], dict):
            user_input = payload["input"].get("prompt")
            actor_id = payload["input"].get("actorId")
            session_id = payload["input"].get("sessionId")
        else:
            user_input = payload.get("prompt")
            actor_id = payload.get("actorId")
            session_id = payload.get("sessionId")

    # Validate required fields
    if not user_input:
        raise ValueError(f"No prompt found in payload. Expected {{'prompt': '...'}} or {{'input': {{'prompt': '...'}}}}. Received: {payload}")

    if not actor_id or not session_id:
        raise ValueError(f"No actorId or sessionId found in payload. Received: {payload}")

    agent = Agent(
        model=MODEL,
        tools=[calculator, weather],
        system_prompt="You're a helpful assistant. You can do simple math calculation, and tell the weather.",
        session_manager=AgentCoreMemorySessionManager(
            agentcore_memory_config=AgentCoreMemoryConfig(
                memory_id=AGENTCORE_MEMORY_ID,
                session_id=session_id,
                actor_id=actor_id,
            )
        ),
        callback_handler=None,
    )

    # Stream response
    stream = agent.stream_async(user_input)
    async for event in stream:
        if event.get("event", {}).get("contentBlockDelta", {}).get("delta", {}).get("text"):
            print(event.get("event", {}).get("contentBlockDelta", {}).get("delta", {}).get("text"))
            yield (event.get("event", {}).get("contentBlockDelta", {}).get("delta", {}).get("text"))


if __name__ == "__main__":
    app.run()
