// Note: Using direct HTTP calls to AgentCore with JWT bearer tokens
// as shown in AWS AgentCore documentation
import { getAccessToken } from './auth';

const region = import.meta.env.VITE_REGION || 'us-east-1';
const agentRuntimeArn = import.meta.env.VITE_AGENT_RUNTIME_ARN;

export interface InvokeAgentRequest {
  prompt: string;
}

export interface InvokeAgentResponse {
  response: string;
}

export const invokeAgent = async (request: InvokeAgentRequest): Promise<InvokeAgentResponse> => {
  try {
    // Check if runtime ARN is available
    if (!agentRuntimeArn) {
      throw new Error('AgentCore Runtime ARN not configured. Please check deployment.');
    }

    // Get JWT access token from Cognito (required for AgentCore as per AWS documentation)
    const jwtToken = await getAccessToken();
    if (!jwtToken) {
      throw new Error('Not authenticated - no access token available');
    }



    // URL encode the agent runtime ARN for the API call (as per AWS documentation)
    const encodedAgentRuntimeArn = encodeURIComponent(agentRuntimeArn);
    
    // Use the correct AgentCore endpoint format from AWS documentation
    const url = `https://bedrock-agentcore.${region}.amazonaws.com/runtimes/${encodedAgentRuntimeArn}/invocations?qualifier=DEFAULT`;
    
    console.log('Invoking AgentCore directly:', { url, agentRuntimeArn, region });
    console.log('Request payload:', { prompt: request.prompt });
    
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${jwtToken}`,
        'X-Amzn-Bedrock-AgentCore-Runtime-Session-Id': `testsession${Date.now()}${Math.random().toString(36).substring(2, 15)}`,
        'X-Amzn-Trace-Id': `trace-${Date.now()}`,
      },
      body: JSON.stringify({
        prompt: request.prompt
      }),
    });
    
    console.log('AgentCore response status:', response.status);
    console.log('AgentCore response headers:', Object.fromEntries(response.headers.entries()));

    if (!response.ok) {
      const errorText = await response.text();
      console.error('AgentCore error response:', errorText);
      throw new Error(`AgentCore invocation failed: ${response.status} ${response.statusText} - ${errorText}`);
    }

    let data;
    try {
      data = await response.json();
      console.log('AgentCore response data:', data);
    } catch (parseError) {
      console.error('Failed to parse JSON response:', parseError);
      const textResponse = await response.text();
      console.log('Raw response text:', textResponse);
      throw new Error(`Invalid JSON response from AgentCore: ${textResponse}`);
    }
    
    // Handle different response formats from AgentCore
    let responseText = '';
    if (typeof data === 'string') {
      responseText = data;
    } else if (data && typeof data === 'object') {
      responseText = data.response || data.content || data.text || data.message || data.output || JSON.stringify(data);
    } else {
      responseText = 'No response from agent';
    }
    
    console.log('Final response text:', responseText);
    
    return {
      response: responseText
    };

  } catch (error: any) {
    console.error('AgentCore invocation error:', error);
    throw new Error(`Failed to invoke agent: ${error.message}`);
  }
};