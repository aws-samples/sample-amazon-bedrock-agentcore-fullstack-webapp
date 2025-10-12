import { useState } from 'react';
import Modal from '@cloudscape-design/components/modal';
import Box from '@cloudscape-design/components/box';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Button from '@cloudscape-design/components/button';
import FormField from '@cloudscape-design/components/form-field';
import Input from '@cloudscape-design/components/input';
import Alert from '@cloudscape-design/components/alert';
import { signUp, signIn, confirmSignUp } from './auth';

interface AuthModalProps {
  visible: boolean;
  onDismiss: () => void;
  onSuccess: () => void;
}

type AuthMode = 'signin' | 'signup' | 'confirm';

export default function AuthModal({ visible, onDismiss, onSuccess }: AuthModalProps) {
  const [mode, setMode] = useState<AuthMode>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmCode, setConfirmCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSignIn = async () => {
    setLoading(true);
    setError('');
    try {
      await signIn(email, password);
      onSuccess();
      resetForm();
    } catch (err: any) {
      setError(err.message || 'Failed to sign in');
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async () => {
    setLoading(true);
    setError('');
    try {
      await signUp(email, password);
      setMode('confirm');
      setError('');
    } catch (err: any) {
      setError(err.message || 'Failed to sign up');
    } finally {
      setLoading(false);
    }
  };

  const handleConfirm = async () => {
    setLoading(true);
    setError('');
    try {
      await confirmSignUp(email, confirmCode);
      await signIn(email, password);
      onSuccess();
      resetForm();
    } catch (err: any) {
      setError(err.message || 'Failed to confirm account');
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setEmail('');
    setPassword('');
    setConfirmCode('');
    setMode('signin');
    setError('');
  };

  const handleDismiss = () => {
    resetForm();
    onDismiss();
  };

  return (
    <Modal
      visible={visible}
      onDismiss={handleDismiss}
      header={mode === 'signin' ? 'Sign In' : mode === 'signup' ? 'Sign Up' : 'Confirm Account'}
      footer={
        <Box float="right">
          <SpaceBetween direction="horizontal" size="xs">
            <Button variant="link" onClick={handleDismiss}>
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={mode === 'signin' ? handleSignIn : mode === 'signup' ? handleSignUp : handleConfirm}
              loading={loading}
            >
              {mode === 'signin' ? 'Sign In' : mode === 'signup' ? 'Sign Up' : 'Confirm'}
            </Button>
          </SpaceBetween>
        </Box>
      }
    >
      <SpaceBetween size="m">
        {error && (
          <Alert type="error" dismissible onDismiss={() => setError('')}>
            {error}
          </Alert>
        )}

        {mode === 'confirm' ? (
          <>
            <Alert type="info">
              A verification code has been sent to {email}. Please enter it below.
            </Alert>
            <FormField label="Verification Code">
              <Input
                value={confirmCode}
                onChange={({ detail }) => setConfirmCode(detail.value)}
                placeholder="Enter 6-digit code"
              />
            </FormField>
          </>
        ) : (
          <>
            <FormField label="Email">
              <Input
                value={email}
                onChange={({ detail }) => setEmail(detail.value)}
                type="email"
                placeholder="your@email.com"
              />
            </FormField>

            <FormField label="Password">
              <Input
                value={password}
                onChange={({ detail }) => setPassword(detail.value)}
                type="password"
                placeholder="Enter password"
              />
            </FormField>

            {mode === 'signin' ? (
              <Box textAlign="center">
                Don't have an account?{' '}
                <Button variant="inline-link" onClick={() => setMode('signup')}>
                  Sign up
                </Button>
              </Box>
            ) : (
              <Box textAlign="center">
                Already have an account?{' '}
                <Button variant="inline-link" onClick={() => setMode('signin')}>
                  Sign in
                </Button>
              </Box>
            )}
          </>
        )}
      </SpaceBetween>
    </Modal>
  );
}
