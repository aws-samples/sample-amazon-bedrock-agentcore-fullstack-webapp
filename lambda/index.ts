import { BedrockAgentCoreClient, InvokeAgentRuntimeCommand } from "@aws-sdk/client-bedrock-agentcore";

export const handler = async (event: any) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  try {
    const { prompt } = JSON.parse(event.body || '{}');

    if (!prompt) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Prompt is required' })
      };
    }

    const client = new BedrockAgentCoreClient({ region: process.env.AWS_REGION || 'us-east-1' });

    const sessionId = generateSessionId();
    console.log('Generated session ID:', sessionId);

    const payloadData = JSON.stringify({ prompt });
    console.log('Payload being sent:', payloadData);
    
    const input = {
      runtimeSessionId: sessionId,
      agentRuntimeArn: process.env.AGENT_RUNTIME_ARN!,
      qualifier: "DEFAULT",
      payload: new TextEncoder().encode(payloadData)
    };

    console.log('Invoking agent with ARN:', process.env.AGENT_RUNTIME_ARN);

    const command = new InvokeAgentRuntimeCommand(input);
    const response = await client.send(command);
    const textResponse = await response.response.transformToString();

    console.log('Agent response received');

    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        response: textResponse,
        sessionId
      })
    };

  } catch (error: any) {
    console.error('Error invoking agent:', error);

    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        error: 'Failed to invoke agent',
        message: error.message
      })
    };
  }
};

function generateSessionId(): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 15);
  const random2 = Math.random().toString(36).substring(2, 15);
  return `session-${timestamp}-${random}-${random2}`;
}