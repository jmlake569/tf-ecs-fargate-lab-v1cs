#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Ensure required files exist
if [ ! -f ./desired_task_definitions.txt ]; then
  echo "Error: desired_task_definitions.txt not found"
  exit 1
fi

# Display contents of desired_task_definitions.txt for debugging
echo "Contents of desired_task_definitions.txt:"
cat ./desired_task_definitions.txt

# Check if the file is empty
if [ ! -s ./desired_task_definitions.txt ]; then
  echo "Error: desired_task_definitions.txt is empty"
  exit 1
fi

# Fetch current task definitions from AWS
echo "Fetching current task definitions from AWS..."
aws ecs list-task-definitions > current_task_definitions.json
jq -r '.taskDefinitionArns[]' current_task_definitions.json > current_task_definitions.txt

# Display current task definitions
echo "Current task definitions:"
cat current_task_definitions.txt

# Compare current task definitions with desired task definitions
echo "Comparing current task definitions with desired task definitions..."
> task_definitions_to_process.txt
while IFS= read -r DESIRED_TASK_DEF; do
  if grep -q "$DESIRED_TASK_DEF" current_task_definitions.txt; then
    echo "Task definition $DESIRED_TASK_DEF already exists."
  else
    echo "Task definition $DESIRED_TASK_DEF does not exist. Adding to process list."
    echo $DESIRED_TASK_DEF >> task_definitions_to_process.txt
  fi
done < ./desired_task_definitions.txt

# Display the task definitions to process
echo "Task definitions to process:"
cat task_definitions_to_process.txt

# Describe and patch task definitions
while IFS= read -r TASK_DEF; do
  echo "Describing task definition: $TASK_DEF"
  aws ecs describe-task-definition --task-definition "$TASK_DEF" > current_task_definition.json
  echo "Current task definition:"
  cat current_task_definition.json

  docker run -v $(pwd):/mnt/input \
             -v $(pwd):/mnt/output \
             trendmicrocloudone/ecs-taskdef-patcher:2.3.44 \
             -i /mnt/input/current_task_definition.json \
             -o /mnt/output/patched_task_definition.json
  echo "Patched task definition:"
  cat $(pwd)/patched_task_definition.json
  cp $(pwd)/patched_task_definition.json path/to/terraform/configuration/$(basename "$TASK_DEF").json
done < task_definitions_to_process.txt

# Register new task definitions
while IFS= read -r TASK_DEF; do
  NEW_TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://$(pwd)/path/to/terraform/configuration/$(basename "$TASK_DEF").json | jq -r '.taskDefinition.taskDefinitionArn')
  echo "New task definition ARN: $NEW_TASK_DEF_ARN"
done < task_definitions_to_process.txt