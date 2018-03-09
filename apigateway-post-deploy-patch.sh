#!/usr/bin/env bash
set -eu

PROFILE="${1:?profile cannot be null}"
REGION="${2:?region cannot be null}"

get_cloudformation_value() {
    local export_name="${1:?export name cannot be null}"
    aws --profile $PROFILE cloudformation list-exports --region $REGION --output text --query 'Exports[?Name==`'"$export_name"'`].Value'
}

api_id=$(get_cloudformation_value bug-demo-gateway-id)

json="$(cat << HEREDOC
{
	"type": "object",
	"oneOf": [{
		"\$ref": "https://apigateway.amazonaws.com/restapis/${api_id}/models/foo"
	}, {
		"\$ref": "https://apigateway.amazonaws.com/restapis/${api_id}/models/bar"
	}, {
		"\$ref": "https://apigateway.amazonaws.com/restapis/${api_id}/models/baz"
	}]
}
HEREDOC
)"

escaped_json="$(echo -n $json | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')"

set -x
aws --profile $PROFILE apigateway update-model --region $REGION --rest-api-id $api_id --model-name 'TopicProxyCommand' --patch-operations op=replace,path=/schema,value="${escaped_json}"
aws --profile $PROFILE apigateway create-deployment --region $REGION --rest-api-id $api_id --stage-name 'commandTopicProxy'
