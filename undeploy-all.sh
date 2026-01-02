#!/bin/bash

# Create placeholder dist directory
if [ ! -d "frontend/dist" ]; then
    echo "Creating placeholder frontend/dist directory for CDK synthesis..."
    mkdir -p frontend/dist
    echo "<!DOCTYPE html><html><body><h1>Destroying...</h1></body></html>" > frontend/dist/index.html

    echo "Installing CDK dependencies..."
    pushd cdk > /dev/null
    npm install
    popd > /dev/null
fi

cd cdk
npx cdk destroy AgentCoreFrontend --force
npx cdk destroy AgentCoreApi --force
npx cdk destroy AgentCoreRuntime --force
npx cdk destroy AgentCoreAuth --force
npx cdk destroy AgentCoreInfra --force
