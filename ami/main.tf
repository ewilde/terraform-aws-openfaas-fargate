// dynamically search for amis
// equiv: aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn-ami-*.a-amazon-ecs-optimized" "Name=root-device-type,Values=ebs" --region us-east-1
data "aws_ami" "images" {
    most_recent = true
    filter {
        name = "name"
        values = ["${lookup(var.images, var.name)}"]
    }
    filter {
        name = "root-device-type"
        values = ["ebs"]
    }
    owners = ["amazon"] # Official
}
