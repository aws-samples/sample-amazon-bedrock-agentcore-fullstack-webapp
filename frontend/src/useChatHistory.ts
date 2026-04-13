import { useState, useCallback } from 'react';
import {
  BedrockAgentCoreClient,
  ListSessionsCommand,
  ListSessionsCommandInput,
  ListEventsCommand,
  SessionSummary
} from '@aws-sdk/client-bedrock-agentcore';
import { CognitoIdentityClient } from '@aws-sdk/client-cognito-identity';
import { fromCognitoIdentityPool } from '@aws-sdk/credential-provider-cognito-identity';
import { getIdToken } from './auth';
import { parseSessionEvents } from './messageParser';

/**
 * Custom hook for managing chat history with AgentCore Memory
 * Provides functions to fetch sessions and messages from the memory store
 * 
 * @param memoryId - The AgentCore Memory ID
 * @param actorId - The actor ID (user identifier)
 * @returns Object containing sessions, loading state, error, and utility functions
 */
export const useChatHistory = (memoryId: string, actorId: string) => {
  const [sessions, setSessions] = useState<SessionSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');

  /**
   * Fetch all chat sessions for the current actor from AgentCore Memory
   * Sessions are sorted by creation date (newest first)
   */
  const fetchSessions = useCallback(async () => {
    if (!memoryId || !actorId) {
      setError('Memory ID and Actor ID are required');
      return;
    }

    setLoading(true);
    setError('');

    try {
      // Get ID Token from Cognito for authentication
      const idToken = await getIdToken();

      if (!idToken) {
        throw new Error('Not authenticated - please sign in');
      }

      const region = (import.meta as any).env.VITE_REGION || 'us-east-1';
      const userPoolId = (import.meta as any).env.VITE_USER_POOL_ID;
      const identityPoolId = (import.meta as any).env.VITE_IDENTITY_POOL_ID;

      // Create Bedrock AgentCore client with Cognito credentials
      const client = new BedrockAgentCoreClient({
        region,
        credentials: fromCognitoIdentityPool({
          client: new CognitoIdentityClient({ region }),
          identityPoolId,
          logins: {
            [`cognito-idp.${region}.amazonaws.com/${userPoolId}`]: idToken
          }
        })
      });

      const input: ListSessionsCommandInput = {
        memoryId,
        actorId,
        maxResults: 50
      };

      const command = new ListSessionsCommand(input);
      const response = await client.send(command);

      // Get session summaries and sort by creation date (newest first)
      const sessionList: SessionSummary[] = response.sessionSummaries || [];
      sessionList.sort((a, b) => {
        const timeA = a.createdAt?.getTime() || 0;
        const timeB = b.createdAt?.getTime() || 0;
        return timeB - timeA;
      });

      setSessions(sessionList);
    } catch (err: any) {
      console.error('Failed to fetch chat sessions:', err);

      // "not found" error is a normal state for first-time users
      // Don't show error for this case
      const errorMessage = err.message || '';
      if (errorMessage.toLowerCase().includes('not found')) {
        // Show empty session list without error
        setSessions([]);
        setError('');
      } else {
        // Show other errors
        setError(errorMessage || 'Failed to load chat history');
      }
    } finally {
      setLoading(false);
    }
  }, [memoryId, actorId]);

  /**
   * Fetch all messages for a specific session from AgentCore Memory
   * 
   * @param sessionId - The session ID to fetch messages for
   * @returns Array of message objects with type, content, and timestamp
   */
  const fetchSessionMessages = useCallback(async (sessionId: string) => {
    if (!memoryId || !actorId) {
      return [];
    }

    try {
      const idToken = await getIdToken();
      if (!idToken) {
        console.warn('No ID token available');
        return [];
      }

      const region = (import.meta as any).env.VITE_REGION || 'us-east-1';
      const userPoolId = (import.meta as any).env.VITE_USER_POOL_ID;
      const identityPoolId = (import.meta as any).env.VITE_IDENTITY_POOL_ID;

      const client = new BedrockAgentCoreClient({
        region,
        credentials: fromCognitoIdentityPool({
          client: new CognitoIdentityClient({ region }),
          identityPoolId,
          logins: {
            [`cognito-idp.${region}.amazonaws.com/${userPoolId}`]: idToken
          }
        })
      });

      const command = new ListEventsCommand({
        memoryId,
        actorId,
        sessionId,
        maxResults: 100
      });

      const response = await client.send(command);

      return parseSessionEvents(response.events || []);
    } catch (err: any) {
      console.error('Failed to fetch session messages:', err);
      // Return empty array for "not found" errors (first session)
      if (err.message?.toLowerCase().includes('not found')) {
        return [];
      }
      throw err;
    }
  }, [memoryId, actorId]);

  /**
   * Generate a new unique session ID
   * Format: session_{timestamp}_{uuid}
   * 
   * @returns A new session ID string (32+ characters)
   */
  const createNewSession = useCallback((): string => {
    // Generate a 32+ character session ID
    const timestamp = Date.now();
    const randomPart = crypto.randomUUID();
    return `session_${timestamp}_${randomPart}`;
  }, []);

  /**
   * Add a new session to local state (before API persistence)
   * Used when creating a new chat to show it in the sidebar immediately
   */
  const addLocalSession = useCallback((sessionId: string) => {
    const newSession: SessionSummary = {
      sessionId,
      actorId,
      createdAt: new Date(),
    };
    
    // Add to the beginning of the sessions array
    setSessions(prev => [newSession, ...prev]);
  }, [actorId]);

  /**
   * Clear all session data and reset state
   * Used when user signs out
   */
  const clearSessions = useCallback(() => {
    setSessions([]);
    setError('');
    setLoading(false);
  }, []);

  return {
    sessions,
    loading,
    error,
    fetchSessions,
    fetchSessionMessages,
    createNewSession,
    addLocalSession,
    clearSessions
  };
};
