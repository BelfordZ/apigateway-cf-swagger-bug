#!/usr/bin/env bash
aws cloudformation create-stack --region us-west-2 --stack-name footest --template-body file://./stack-template.yml
