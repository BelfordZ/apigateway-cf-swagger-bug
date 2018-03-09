#!/usr/bin/env bash
set -eu

get_cloudformation_value() {
    local export_name="${1:?export name cannot be null}"
    aws cloudformation list-exports --region us-west-2 --output text --query 'Exports[?Name==`'"$export_name"'`].Value'
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
aws apigateway update-model --region us-west-2 --rest-api-id $api_id --model-name 'ProxyModel' --patch-operations op=replace,path=/schema,value="${escaped_json}"
aws apigateway create-deployment --region us-west-2 --rest-api-id $api_id --stage-name 'commandTopicProxy'
