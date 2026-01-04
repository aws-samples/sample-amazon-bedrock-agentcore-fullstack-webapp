import SideNavigation, { SideNavigationProps } from '@cloudscape-design/components/side-navigation';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Button from '@cloudscape-design/components/button';
import Box from '@cloudscape-design/components/box';
import { SessionSummary } from '@aws-sdk/client-bedrock-agentcore';

interface ChatHistorySidebarProps {
  sessions: SessionSummary[];
  sessionId: string | null;
  loading: boolean;
  error: string;
  onSessionSelect: (sessionId: string) => void;
  onNewChat: () => void;
  onRefresh: () => void;
}

const ChatHistorySidebar: React.FC<ChatHistorySidebarProps> = ({
  sessions,
  sessionId,
  loading,
  error,
  onSessionSelect,
  onNewChat,
  onRefresh,
}) => {
  const formatDate = (date: Date): string => {
    const now = new Date();
    const diffMs = now.getTime() - new Date(date).getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;

    return new Date(date).toLocaleDateString();
  };

  // Build navigation items from sessions
  const navigationItems: SideNavigationProps.Item[] = sessions
    .filter(session => session.sessionId)
    .map(session => ({
      type: 'link' as const,
      text: session.sessionId!,
      href: `#${session.sessionId}`,
      info: session.createdAt ? <Box color="text-body-secondary" fontSize="body-s">{formatDate(session.createdAt)}</Box> : undefined
    }));

  const handleFollow = (event: CustomEvent<SideNavigationProps.FollowDetail>) => {
    event.preventDefault();
    const href = event.detail.href;
    if (href && href.startsWith('#')) {
      const selectedSessionId = href.substring(1);
      onSessionSelect(selectedSessionId);
    }
  };

  return (
    <div style={{
      display: 'flex',
      flexDirection: 'column',
      height: '100%'
    }}>
      {/* Header with buttons */}
      <div style={{ padding: '12px 24px 0 28px' }}>
        <SpaceBetween size="s">
          <Button
            onClick={onNewChat}
            variant="primary"
            iconName="add-plus"
            fullWidth
          >
            New Chat
          </Button>
          <Button
            onClick={onRefresh}
            iconName="refresh"
            variant="normal"
            fullWidth
            loading={loading}
          >
            Refresh
          </Button>
        </SpaceBetween>
      </div>

      {/* Error message */}
      {error && (
        <Box color="text-status-error" padding={{ horizontal: 's' }}>
          {error}
        </Box>
      )}

      {/* Loading state */}
      {loading && sessions.length === 0 && (
        <Box textAlign="center" padding="l" color="text-body-secondary">
          Loading...
        </Box>
      )}

      {/* Empty state */}
      {!loading && sessions.length === 0 && !error && (
        <Box textAlign="center" padding="l" color="text-body-secondary">
          No chat history yet
        </Box>
      )}

      {/* Sessions list */}
      {sessions.length > 0 && (
        <div style={{ flex: 1, overflow: 'auto' }}>
          <SideNavigation
            activeHref={sessionId ? `#${sessionId}` : undefined}
            items={navigationItems}
            onFollow={handleFollow}
          />
        </div>
      )}

      {/* Footer */}
      <div style={{
        padding: '12px 24px',
        borderTop: '1px solid #e9ebed',
        fontSize: '12px',
        color: '#5f6b7a'
      }}>
        {sessions.length} conversation{sessions.length !== 1 ? 's' : ''}
      </div>
    </div>
  );
};

export default ChatHistorySidebar;
