# alb-dns-registrator

Registers ALB DNS name with DNS service

## USAGE

`./alb-dns-registrator.sh  [--debug=true] [--instance-id=i-0123abc] [--region=aws-region] [--zone=ft.com] [--ttl=60] [--interval=300] --dynkey=secret`

...or to pass arguments to Docker image

`docker run --env "CLI_ARGS=--dynkey=secret" coco/alb-dns-registrator:latest`
