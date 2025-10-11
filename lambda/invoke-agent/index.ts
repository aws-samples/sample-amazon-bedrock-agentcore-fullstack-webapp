import { BedrockAgentCoreClient, InvokeAgentRuntimeCommand } from "@aws-sdk/client-bedrock-agentcore";

const client = new BedrockAgentCoreClient({ region: process.env.AWS_REGION || 'us-east-1' });

function generateSessionId(): string {
  return `session-${Date.now()}-${Math.random().toString(36).substring(2, 15)}${Math.random().toString(36).substring(2, 15)}`;
}

export const handler = async (event: any) => {
  console.log('Invoking agent with event:', JSON.stringify(event));
  try {
    const body = JSON.parse(event.body || '{}');
    const { prompt } = body;

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

    const input = {
      runtimeSessionId: generateSessionId(),
      agentRuntimeArn: process.env.AGENT_RUNTIME_ARN!,
      endpointName: process.env.AGENT_ENDPOINT_NAME!,
      payload: new TextEncoder().encode(JSON.stringify({ input: { prompt } }))
    };

    const command = new InvokeAgentRuntimeCommand(input);
    const response = await client.send(command);
    const textResponse = response.response ? await response.response.transformToString() : '';

    return {
      statusCode: 200,
      headers: { 
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ response: textResponse })
    };
  } catch (error: any) {
    console.error('Error invoking agent:', error);
    return {
      statusCode: 500,
      headers: { 
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: error.message })
    };
  }
};
