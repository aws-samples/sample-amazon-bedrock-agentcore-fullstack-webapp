import { Event, Conversational } from '@aws-sdk/client-bedrock-agentcore';

/**
 * Message interface for frontend display
 */
export interface Message {
  type: 'user' | 'agent';
  content: string;
  timestamp: Date;
}

/**
 * Content item structure after filtering toolUse/toolResult
 */
interface ContentItem {
  text: string;
  toolUse?: unknown;
  toolResult?: unknown;
}

/**
 * Parsed message data structure from JSON payload
 */
interface ParsedMessageData {
  message: {
    role: string;
    content: unknown;
  };
}

/**
 * Maps AgentCore role format to frontend message type.
 * Handles both uppercase (USER/ASSISTANT) and lowercase variants from blob payloads.
 * 
 * @param role - Role string from AgentCore Memory
 * @returns Normalized message type or null if invalid
 */
function mapRoleToMessageType(role: string): 'user' | 'agent' | null {
  const normalizedRole = role.toUpperCase();
  if (normalizedRole === 'USER') return 'user';
  if (normalizedRole === 'ASSISTANT') return 'agent';
  return null;
}

/**
 * Filters out toolUse and toolResult items from content array.
 * These items represent internal agent operations and should not be displayed.
 * 
 * @param content - Content array to filter
 * @returns Filtered array containing only displayable content items
 */
function filterContentItems(content: unknown): ContentItem[] {
  if (!Array.isArray(content)) {
    return [];
  }

  return content.filter((item): item is ContentItem =>
    typeof item === 'object' &&
    item !== null &&
    !('toolUse' in item) &&      // Exclude tool invocations
    !('toolResult' in item)      // Exclude tool results (returned as USER role)
  );
}

/**
 * Extracts the first non-empty text content from filtered content items.
 * 
 * @param filteredContent - Array of filtered content items
 * @returns First text content found, or undefined if none exists
 */
function extractTextContent(filteredContent: ContentItem[]): string | undefined {
  return filteredContent
    .find(item => typeof item.text === 'string' && item.text.trim() !== '')
    ?.text;
}

/**
 * Builds a Message object from parsed message data.
 * Returns null if no valid text content is found after filtering.
 * 
 * @param messageData - Parsed message data structure
 * @param messageType - Message type ('user' or 'agent')
 * @param timestamp - Event timestamp
 * @returns Message object or null if invalid
 */
function buildMessage(
  messageData: ParsedMessageData,
  messageType: 'user' | 'agent',
  timestamp: Date
): Message | null {
  // Filter out toolUse/toolResult from content array
  const filteredContent = filterContentItems(messageData.message?.content);
  if (filteredContent.length === 0) {
    return null;
  }

  // Extract text content from filtered items
  const textContent = extractTextContent(filteredContent);
  if (!textContent) {
    return null;
  }

  return {
    type: messageType,
    content: textContent,
    timestamp,
  };
}

/**
 * Parses a conversational-type payload from AgentCore Memory.
 * 
 * @param conversational - Conversational payload from AWS SDK
 * @param timestamp - Event timestamp
 * @returns Parsed Message or null if invalid
 */
function parseConversationalPayload(
  conversational: Conversational,
  timestamp: Date
): Message | null {
  try {
    // Parse the stringified JSON in content.text
    const messageData: ParsedMessageData = JSON.parse(
      conversational.content?.text || '{}'
    );

    // Map role to frontend message type
    const messageType = mapRoleToMessageType(conversational.role || '');
    if (!messageType) {
      return null;
    }

    return buildMessage(messageData, messageType, timestamp);
  } catch (err) {
    console.warn('Failed to parse conversational payload:', err);
    return null;
  }
}

/**
 * Parses a blob-type payload from AgentCore Memory.
 * Blob payloads are used for large messages that exceed the conversational size limit.
 * The structure is a double-escaped JSON array: ["messageJson", "role"]
 * 
 * @param blobString - Blob payload string
 * @param timestamp - Event timestamp
 * @returns Parsed Message or null if invalid
 */
function parseBlobPayload(blobString: string, timestamp: Date): Message | null {
  try {
    // Parse outer array structure
    const blobArray: unknown = JSON.parse(blobString);

    // Validate array structure
    if (!Array.isArray(blobArray) || blobArray.length < 2) {
      return null;
    }

    // Validate first element is a string
    const firstElement = blobArray[0];
    if (typeof firstElement !== 'string') {
      return null;
    }
    const messageJsonString: string = firstElement;

    // Parse the stringified message data
    const messageDataRaw: unknown = JSON.parse(messageJsonString);
    if (typeof messageDataRaw !== 'object' || messageDataRaw === null) {
      return null;
    }
    const messageData = messageDataRaw as ParsedMessageData;

    // Validate second element is a string
    const secondElement = blobArray[1];
    if (typeof secondElement !== 'string') {
      return null;
    }
    const role: string = secondElement;

    const messageType = mapRoleToMessageType(role);
    if (!messageType) {
      return null;
    }

    return buildMessage(messageData, messageType, timestamp);
  } catch (err) {
    console.warn('Failed to parse blob payload:', err);
    return null;
  }
}

/**
 * Parses a single Event from AgentCore Memory.
 * Handles both conversational and blob payload types.
 * 
 * @param event - Event object from AWS SDK
 * @returns Parsed Message or null if invalid or empty
 */
function parseEvent(event: Event): Message | null {
  // Validate payload exists
  if (!event.payload?.[0]) {
    return null;
  }

  const timestamp = event.eventTimestamp
    ? new Date(event.eventTimestamp)
    : new Date();

  const payloadEntry = event.payload[0];

  // Handle conversational-type payload
  if ('conversational' in payloadEntry && payloadEntry.conversational) {
    return parseConversationalPayload(payloadEntry.conversational, timestamp);
  }

  // Handle blob-type payload (for large messages)
  if ('blob' in payloadEntry && payloadEntry.blob) {
    // Validate blob is a string
    if (typeof payloadEntry.blob !== 'string') {
      return null;
    }
    return parseBlobPayload(payloadEntry.blob, timestamp);
  }

  return null;
}

/**
 * Merges consecutive messages from the same sender into a single message.
 * This is a reduce function that accumulates messages while merging those
 * with the same message type (user/agent).
 * 
 * When merging:
 * - Content is joined with double newlines
 * - The latest timestamp is preserved
 * - Older timestamps are discarded
 * 
 * @param accumulated - Array of accumulated messages
 * @param current - Current message to process
 * @returns Updated accumulated array with merged messages
 */
function mergeConsecutiveMessages(
  accumulated: Message[],
  current: Message
): Message[] {
  if (accumulated.length === 0) {
    return [current];
  }

  const lastIndex = accumulated.length - 1;
  const last = accumulated[lastIndex];

  // Merge if same sender (type)
  if (last.type === current.type) {
    // Update last element in-place to avoid unnecessary spreading
    accumulated[lastIndex] = {
      type: last.type,
      content: `${last.content}\n\n${current.content}`,
      timestamp: current.timestamp  // Keep latest timestamp
    };
    return accumulated;
  }

  return [...accumulated, current];
}

/**
 * Parse AgentCore Memory events and convert them into display-ready messages.
 * 
 * This function:
 * 1. Reverses events to process in chronological order (oldest first)
 * 2. Parses both conversational and blob payload types
 * 3. Filters out toolUse/toolResult content automatically
 * 4. Merges consecutive messages from the same sender
 * 5. Preserves the latest timestamp when merging
 * 
 * @param events - Array of Event objects from AWS SDK (typically newest first)
 * @returns Parsed Message array (oldest first) with consecutive messages merged
 */
export function parseSessionEvents(events: Event[]): Message[] {
  return [...events]
    .reverse()                                      // Convert to oldest-first order
    .map(parseEvent)                                // Parse each event
    .filter((msg): msg is Message => msg !== null)  // Remove nulls with type guard
    .reduce(mergeConsecutiveMessages, []);          // Merge consecutive same-sender messages
}
