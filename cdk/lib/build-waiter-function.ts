// Lambda function code for waiting on CodeBuild
export const handler = async (event: any) => {
  const AWS = require('aws-sdk');
  const codebuild = new AWS.CodeBuild();
  
  const buildId = event.ResourceProperties.BuildId;
  const maxWaitMinutes = 20;
  const pollIntervalSeconds = 30;
  
  console.log('Waiting for build:', buildId);
  
  const startTime = Date.now();
  const maxWaitMs = maxWaitMinutes * 60 * 1000;
  
  while (Date.now() - startTime < maxWaitMs) {
    try {
      const response = await codebuild.batchGetBuilds({ ids: [buildId] }).promise();
      const build = response.builds[0];
      const status = build.buildStatus;
      
      console.log(`Build status: ${status}`);
      
      if (status === 'SUCCEEDED') {
        return {
          PhysicalResourceId: buildId,
          Data: { Status: 'SUCCEEDED' }
        };
      } else if (['FAILED', 'FAULT', 'TIMED_OUT', 'STOPPED'].includes(status)) {
        throw new Error(`Build failed with status: ${status}`);
      }
      
      // Still in progress, wait before next check
      await new Promise(resolve => setTimeout(resolve, pollIntervalSeconds * 1000));
      
    } catch (error: any) {
      if (error.message.includes('Build failed')) {
        throw error;
      }
      console.error('Error checking build status:', error);
      throw error;
    }
  }
  
  throw new Error(`Build timeout after ${maxWaitMinutes} minutes`);
};
