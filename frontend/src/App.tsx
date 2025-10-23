import { useState, useEffect } from 'react';
import AppLayout from '@cloudscape-design/components/app-layout';
import TopNavigation from '@cloudscape-design/components/top-navigation';
import ContentLayout from '@cloudscape-design/components/content-layout';
import Container from '@cloudscape-design/components/container';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Box from '@cloudscape-design/components/box';
import ButtonGroup from '@cloudscape-design/components/button-group';
import Grid from '@cloudscape-design/components/grid';
import StatusIndicator from '@cloudscape-design/components/status-indicator';
import ChatBubble from '@cloudscape-design/chat-components/chat-bubble';
import Avatar from '@cloudscape-design/chat-components/avatar';
import SupportPromptGroup from '@cloudscape-design/chat-components/support-prompt-group';
import PromptInput from '@cloudscape-design/components/prompt-input';
import Alert from '@cloudscape-design/components/alert';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import AuthModal from './AuthModal';
import { getCurrentUser, getIdToken, signOut, AuthUser } from './auth';
import { invokeAgent } from './agentcore';
import './markdown.css';

interface Message {
  type: 'user' | 'agent';
  content: string;
  timestamp: Date;
  feedback?: 'helpful' | 'not-helpful';
  feedbackSubmitting?: boolean;
}

interface MessageFeedback {
  [messageIndex: number]: {
    feedback?: 'helpful' | 'not-helpful';
    submitting?: boolean;
    showCopySuccess?: boolean;
  };
}

function App() {
  const [prompt, setPrompt] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [user, setUser] = useState<AuthUser | null>(null);
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [checkingAuth, setCheckingAuth] = useState(true);
  const [messageFeedback, setMessageFeedback] = useState<MessageFeedback>({});
  const [showSupportPrompts, setShowSupportPrompts] = useState(true);

  useEffect(() => {
    checkAuth();
  }, []);

  const checkAuth = async () => {
    try {
      const currentUser = await getCurrentUser();
      setUser(currentUser);
    } catch (err) {
      setUser(null);
    } finally {
      setCheckingAuth(false);
    }
  };

  const handleSignOut = () => {
    signOut();
    setUser(null);
    setMessages([]);
  };

  const handleAuthSuccess = async () => {
    setShowAuthModal(false);
    await checkAuth();
  };

  const handleFeedback = async (messageIndex: number, feedbackType: 'helpful' | 'not-helpful') => {
    // Set submitting state
    setMessageFeedback(prev => ({
      ...prev,
      [messageIndex]: { ...prev[messageIndex], submitting: true }
    }));

    // Simulate feedback submission (you can add actual API call here)
    await new Promise(resolve => setTimeout(resolve, 500));

    // Set feedback submitted
    setMessageFeedback(prev => ({
      ...prev,
      [messageIndex]: { feedback: feedbackType, submitting: false }
    }));
  };

  const handleCopy = async (messageIndex: number, content: string) => {
    try {
      await navigator.clipboard.writeText(content);

      // Show success indicator
      setMessageFeedback(prev => ({
        ...prev,
        [messageIndex]: { ...prev[messageIndex], showCopySuccess: true }
      }));

      // Hide success indicator after 2 seconds
      setTimeout(() => {
        setMessageFeedback(prev => ({
          ...prev,
          [messageIndex]: { ...prev[messageIndex], showCopySuccess: false }
        }));
      }, 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    }
  };

  const cleanResponse = (response: string): string => {
    // Remove surrounding quotes if present
    let cleaned = response.trim();
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
      (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.slice(1, -1);
    }

    // Replace literal \n with actual newlines
    cleaned = cleaned.replace(/\\n/g, '\n');

    // Replace literal \t with actual tabs
    cleaned = cleaned.replace(/\\t/g, '\t');

    return cleaned;
  };

  const handleSupportPromptClick = (promptText: string) => {
    // Fill the prompt input with the selected text
    setPrompt(promptText);
    // Hide support prompts after selection
    setShowSupportPrompts(false);
  };

  const handleSendMessage = async () => {
    if (!user) {
      setShowAuthModal(true);
      return;
    }

    if (!prompt.trim()) {
      setError('Please enter a prompt');
      return;
    }

    // Hide support prompts when sending a message
    setShowSupportPrompts(false);

    const userMessage: Message = {
      type: 'user',
      content: prompt,
      timestamp: new Date()
    };

    setMessages(prev => [...prev, userMessage]);
    setLoading(true);
    setError('');
    const currentPrompt = prompt;
    setPrompt('');

    try {
      const data = await invokeAgent({ prompt: currentPrompt });

      const agentMessage: Message = {
        type: 'agent',
        content: cleanResponse(data.response || ''),
        timestamp: new Date()
      };

      setMessages(prev => [...prev, agentMessage]);

      // Show support prompts after agent responds
      setShowSupportPrompts(true);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Get contextual support prompts based on conversation
  const getSupportPrompts = () => {
    // Initial prompts when no messages
    if (messages.length === 0) {
      return [
        { id: 'calc', text: 'What is 123 + 456?' },
        { id: 'weather', text: "What's the weather like today?" },
        { id: 'table', text: 'Create a comparison table of 3 AWS services' },
        { id: 'math', text: 'Calculate 2048 * 1024 and explain the result' }
      ];
    }

    // Contextual prompts based on last message
    const lastMessage = messages[messages.length - 1];
    if (lastMessage.type === 'agent') {
      const content = lastMessage.content.toLowerCase();

      // After calculation
      if (content.includes('result') || content.includes('sum') || content.includes('calculation')) {
        return [
          { id: 'another-calc', text: 'Can you do another calculation?' },
          { id: 'weather-follow', text: "What's the weather?" },
          { id: 'explain', text: 'Can you explain that in more detail?' }
        ];
      }

      // After weather
      if (content.includes('weather') || content.includes('sunny') || content.includes('°f')) {
        return [
          { id: 'calc-follow', text: 'What is 999 + 111?' },
          { id: 'table-follow', text: 'Show me a table with sample data' },
          { id: 'thanks', text: 'Thank you!' }
        ];
      }

      // After table
      if (content.includes('|') || content.includes('table')) {
        return [
          { id: 'another-table', text: 'Create another table with different data' },
          { id: 'calc-after-table', text: 'Calculate 15 * 12' },
          { id: 'format', text: 'Can you format that differently?' }
        ];
      }
    }

    // Default follow-up prompts
    return [
      { id: 'more', text: 'Tell me more' },
      { id: 'calc-default', text: 'Do a calculation' },
      { id: 'weather-default', text: 'Check the weather' }
    ];
  };



  if (checkingAuth) {
    return (
      <>
        <TopNavigation
          identity={{
            href: "#",
            title: "Amazon Bedrock AgentCore Demo"
          }}
          utilities={[
            {
              type: "button",
              text: user ? `${user.email} | Sign Out` : "Sign In",
              iconName: user ? "user-profile" : "lock-private",
              onClick: () => {
                if (user) {
                  handleSignOut();
                } else {
                  setShowAuthModal(true);
                }
              }
            }
          ]}
          i18nStrings={{
            overflowMenuTriggerText: "More",
            overflowMenuTitleText: "All"
          }}
        />
        <AppLayout
          navigationHide={true}
          toolsHide={true}
          disableContentPaddings
          contentType="default"
          content={
            <ContentLayout defaultPadding>
              <Box textAlign="center" padding="xxl">
                Loading...
              </Box>
            </ContentLayout>
          }
        />
      </>
    );
  }

  return (
    <>
      <AuthModal
        visible={showAuthModal}
        onDismiss={() => setShowAuthModal(false)}
        onSuccess={handleAuthSuccess}
      />
      <TopNavigation
        identity={{
          href: "#",
          title: "Amazon Bedrock AgentCore Demo"
        }}
        utilities={[
          {
            type: "button",
            text: user ? `${user.email} | Sign Out` : "Sign In",
            iconName: user ? "user-profile" : "lock-private",
            onClick: () => {
              if (user) {
                handleSignOut();
              } else {
                setShowAuthModal(true);
              }
            }
          }
        ]}
        i18nStrings={{
          overflowMenuTriggerText: "More",
          overflowMenuTitleText: "All"
        }}
      />
      <AppLayout
        navigationHide={true}
        toolsHide={true}
        disableContentPaddings
        contentType="default"
        content={
          <ContentLayout defaultPadding>
            <Grid
              gridDefinition={[
                { colspan: { default: 12, xs: 1, s: 2 } },
                { colspan: { default: 12, xs: 10, s: 8 } },
                { colspan: { default: 12, xs: 1, s: 2 } }
              ]}
            >
              <div />
              <SpaceBetween size="l">
                {error && (
                  <Alert type="error" dismissible onDismiss={() => setError('')}>
                    {error}
                  </Alert>
                )}

                <Container>
                  <div role="region" aria-label="Chat">
                    <SpaceBetween size="m">
                      {messages.length === 0 ? (
                        <Box textAlign="center" padding={{ vertical: 'xxl' }} color="text-body-secondary">
                          Start a conversation with the generative AI assistant by typing a message below
                        </Box>
                      ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                          {messages.map((message, index) => {
                            const feedback = messageFeedback[index];
                            const isAgent = message.type === 'agent';

                            return (
                              <div key={index} style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                                {isAgent && (
                                  <Avatar
                                    ariaLabel="Generative AI assistant"
                                    tooltipText="Generative AI assistant"
                                    iconName="gen-ai"
                                    color="gen-ai"
                                  />
                                )}
                                <div style={{ flex: 1 }}>
                                  <ChatBubble
                                    type={message.type === 'user' ? 'outgoing' : 'incoming'}
                                    ariaLabel={`${message.type === 'user' ? 'User' : 'Generative AI assistant'} message`}
                                    avatar={message.type === 'user' ? <div /> : undefined}
                                  >
                                    <ReactMarkdown
                                      remarkPlugins={[remarkGfm]}
                                      components={{
                                        // Style code blocks
                                        code: ({ className, children }: any) => {
                                          const inline = !className;
                                          return inline ? (
                                            <code style={{
                                              backgroundColor: '#f4f4f4',
                                              padding: '2px 6px',
                                              borderRadius: '3px',
                                              fontFamily: 'monospace',
                                              fontSize: '0.9em'
                                            }}>
                                              {children}
                                            </code>
                                          ) : (
                                            <pre style={{
                                              backgroundColor: '#f4f4f4',
                                              padding: '12px',
                                              borderRadius: '6px',
                                              overflow: 'auto',
                                              fontFamily: 'monospace',
                                              fontSize: '0.9em'
                                            }}>
                                              <code className={className}>
                                                {children}
                                              </code>
                                            </pre>
                                          );
                                        },
                                        // Style links
                                        a: ({ children, href }: any) => (
                                          <a href={href} style={{ color: '#0972d3' }} target="_blank" rel="noopener noreferrer">
                                            {children}
                                          </a>
                                        ),
                                        // Style lists
                                        ul: ({ children }: any) => (
                                          <ul style={{ marginLeft: '20px', marginTop: '8px', marginBottom: '8px' }}>
                                            {children}
                                          </ul>
                                        ),
                                        ol: ({ children }: any) => (
                                          <ol style={{ marginLeft: '20px', marginTop: '8px', marginBottom: '8px' }}>
                                            {children}
                                          </ol>
                                        ),
                                        // Style paragraphs
                                        p: ({ children }: any) => (
                                          <p style={{ marginTop: '8px', marginBottom: '8px' }}>
                                            {children}
                                          </p>
                                        ),
                                      }}
                                    >
                                      {message.content}
                                    </ReactMarkdown>
                                  </ChatBubble>

                                  {isAgent && (
                                    <div style={{ marginTop: '8px' }}>
                                      <ButtonGroup
                                        variant="icon"
                                        ariaLabel="Message actions"
                                        items={[
                                          {
                                            type: 'icon-button',
                                            id: 'thumbs-up',
                                            iconName: feedback?.feedback === 'helpful' ? 'thumbs-up-filled' : 'thumbs-up',
                                            text: 'Helpful',
                                            disabled: feedback?.submitting || !!feedback?.feedback,
                                            loading: feedback?.submitting && feedback?.feedback !== 'not-helpful',
                                            disabledReason: feedback?.feedback === 'helpful'
                                              ? '"Helpful" feedback has been submitted.'
                                              : feedback?.feedback === 'not-helpful'
                                                ? '"Helpful" option is unavailable after "not helpful" feedback submitted.'
                                                : undefined,
                                          },
                                          {
                                            type: 'icon-button',
                                            id: 'thumbs-down',
                                            iconName: feedback?.feedback === 'not-helpful' ? 'thumbs-down-filled' : 'thumbs-down',
                                            text: 'Not helpful',
                                            disabled: feedback?.submitting || !!feedback?.feedback,
                                            loading: feedback?.submitting && feedback?.feedback !== 'helpful',
                                            disabledReason: feedback?.feedback === 'not-helpful'
                                              ? '"Not helpful" feedback has been submitted.'
                                              : feedback?.feedback === 'helpful'
                                                ? '"Not helpful" option is unavailable after "helpful" feedback submitted.'
                                                : undefined,
                                          },
                                          {
                                            type: 'icon-button',
                                            id: 'copy',
                                            iconName: 'copy',
                                            text: 'Copy',
                                            popoverFeedback: feedback?.showCopySuccess ? (
                                              <StatusIndicator type="success">
                                                Copied
                                              </StatusIndicator>
                                            ) : undefined,
                                          }
                                        ]}
                                        onItemClick={({ detail }) => {
                                          if (detail.id === 'thumbs-up') {
                                            handleFeedback(index, 'helpful');
                                          } else if (detail.id === 'thumbs-down') {
                                            handleFeedback(index, 'not-helpful');
                                          } else if (detail.id === 'copy') {
                                            handleCopy(index, message.content);
                                          }
                                        }}
                                      />
                                      {feedback?.feedback && (
                                        <Box margin={{ top: 'xs' }} color="text-status-info" fontSize="body-s">
                                          Feedback submitted
                                        </Box>
                                      )}
                                    </div>
                                  )}
                                </div>
                              </div>
                            );
                          })}
                          {loading && (
                            <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                              <Avatar
                                ariaLabel="Generative AI assistant"
                                tooltipText="Generative AI assistant"
                                iconName="gen-ai"
                                color="gen-ai"
                                loading={true}
                              />
                              <Box color="text-body-secondary">
                                Generating a response
                              </Box>
                            </div>
                          )}
                        </div>
                      )}

                      {showSupportPrompts && !loading && (
                        <SupportPromptGroup
                          onItemClick={({ detail }) => handleSupportPromptClick(
                            getSupportPrompts().find(p => p.id === detail.id)?.text || ''
                          )}
                          ariaLabel="Suggested prompts"
                          alignment="horizontal"
                          items={getSupportPrompts()}
                        />
                      )}

                      <PromptInput
                        value={prompt}
                        onChange={({ detail }) => setPrompt(detail.value)}
                        onAction={handleSendMessage}
                        placeholder="Ask a question..."
                        actionButtonAriaLabel="Send message"
                        actionButtonIconName="send"
                        disabled={loading}
                      />
                    </SpaceBetween>
                  </div>
                </Container>
              </SpaceBetween>
              <div />
            </Grid>
          </ContentLayout>
        }
      />
    </>
  );
}

export default App;
