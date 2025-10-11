import { useState } from 'react';
import AppLayout from '@cloudscape-design/components/app-layout';
import ContentLayout from '@cloudscape-design/components/content-layout';
import Header from '@cloudscape-design/components/header';
import Container from '@cloudscape-design/components/container';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Box from '@cloudscape-design/components/box';
import { ChatBubble, Avatar } from '@cloudscape-design/chat-components';
import PromptInput from '@cloudscape-design/components/prompt-input';
import Alert from '@cloudscape-design/components/alert';
import GenAiLabel from './GenAiLabel';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

interface Message {
  type: 'user' | 'agent';
  content: string;
  timestamp: Date;
}

function App() {
  const [prompt, setPrompt] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const invokeAgent = async () => {
    if (!prompt.trim()) {
      setError('Please enter a prompt');
      return;
    }

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
      const res = await fetch(`${API_URL}/invoke`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: currentPrompt })
      });

      const data = await res.json() as { response?: string; error?: string };

      if (!res.ok) {
        throw new Error(data.error || 'Failed to invoke agent');
      }

      const agentMessage: Message = {
        type: 'agent',
        content: data.response || '',
        timestamp: new Date()
      };

      setMessages(prev => [...prev, agentMessage]);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };



  return (
    <AppLayout
      navigationHide
      toolsHide
      content={
        <ContentLayout
          header={
            <Header variant="h1">
              AgentCore Demo
            </Header>
          }
        >
          <SpaceBetween size="l">
            {error && (
              <Alert type="error" dismissible onDismiss={() => setError('')}>
                {error}
              </Alert>
            )}

            <Container>
              <SpaceBetween size="m">
                {messages.length === 0 ? (
                  <div style={{ textAlign: 'center', padding: '2rem', color: '#5f6b7a' }}>
                    Start a conversation with the agent by typing a message below
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    {messages.map((message, index) => (
                      <div key={index} style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                        {message.type === 'agent' && (
                          <Avatar
                            ariaLabel="AI Assistant"
                            tooltipText="AI Assistant"
                            iconName="gen-ai"
                            color="gen-ai"
                          />
                        )}
                        <div style={{ flex: 1 }}>
                          <ChatBubble
                            type={message.type === 'user' ? 'outgoing' : 'incoming'}
                            ariaLabel={`${message.type} message`}
                            avatar={message.type === 'agent' ? undefined : <div />}
                          >
                            {message.content}
                          </ChatBubble>
                          {message.type === 'agent' && (
                            <div style={{ marginTop: '0.5rem' }}>
                              <GenAiLabel />
                            </div>
                          )}
                        </div>
                      </div>
                    ))}
                    {loading && (
                      <div style={{ display: 'flex', gap: '12px', alignItems: 'flex-start' }}>
                        <Avatar
                          ariaLabel="AI Assistant"
                          tooltipText="AI Assistant"
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

                <PromptInput
                  value={prompt}
                  onChange={({ detail }) => setPrompt(detail.value)}
                  onAction={invokeAgent}
                  placeholder="Ask a question..."
                  actionButtonAriaLabel="Send message"
                  actionButtonIconName="send"
                  disabled={loading}
                />
              </SpaceBetween>
            </Container>
          </SpaceBetween>
        </ContentLayout>
      }
    />
  );
}

export default App;
