#!/bin/bash

# List of keywords to filter task definitions
KEYWORDS=("ecs-fargate-trend-demo-nginx")

# List all ECS task definitions
echo "Listing all ECS task definitions..."
TASK_DEFINITIONS=$(aws ecs list-task-definitions)

# Check if the command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to list ECS task definitions"
  exit 1
fi

# Display the raw JSON output
echo "Raw JSON output:"
echo $TASK_DEFINITIONS

# Pretty print the JSON output using jq
echo "Pretty printed JSON output:"
echo $TASK_DEFINITIONS | jq .

# Filter task definitions based on keywords
echo "Filtering task definitions..."
FILTERED_TASK_DEFINITIONS=$(echo $TASK_DEFINITIONS | jq -r --argjson keywords "$(printf '%s\n' "${KEYWORDS[@]}" | jq -R . | jq -s .)" '.taskDefinitionArns[] | select(. as $arn | $keywords | any(. as $keyword | $arn | contains($keyword)))')

# Display the filtered task definitions
echo "Filtered task definitions:"
echo $FILTERED_TASK_DEFINITIONS

# Retrieve JSON for each filtered task definition
for TASK_DEF_ARN in $FILTERED_TASK_DEFINITIONS; do
  echo "Retrieving JSON for task definition: $TASK_DEF_ARN"
  TASK_DEF_JSON=$(aws ecs describe-task-definition --task-definition $TASK_DEF_ARN)
  if [ $? -ne 0 ]; then
    echo "Error: Failed to retrieve JSON for task definition $TASK_DEF_ARN"
    exit 1
  fi
  echo "Task definition JSON for $TASK_DEF_ARN:"
  echo $TASK_DEF_JSON | jq .
done