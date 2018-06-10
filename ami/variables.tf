variable "name" {
    default = "amazon_linux"
    description = "Which version of linux to use: amazon_linux or amazon_ecs."
}

variable "images" {
    type = "map"

    default = {
        amazon_linux = "amzn-ami-hvm-????.??.?.????????-x86_64-gp2"
        amazon_ecs = "amzn-ami-*.e-amazon-ecs-optimized"
        win_2012 = "Windows_Server-2012-R2_RTM-English-64Bit-Base-*"
        win_2016 = "Windows_Server-2016-English-Full-Base-*"
    }
}
