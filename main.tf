#-----------------------------
#Keypair Creation
#-----------------------------
resource "aws_key_pair" "auth_key" {
  key_name   = "${var.project_name}-${var.project_env}"
  public_key = file("sshkey.pub")
  tags = {
    Name    = "${var.project_name}-${var.project_env}"
    project = var.project_name
    env     = var.project_env
  }

}

#----------------------------
#Security Group
#----------------------------

resource "aws_security_group" "http_access" {
  name        = "${var.project_name}-${var.project_env}-httpd-access"
  description = "${var.project_name}-${var.project_env}-httpd-access"

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_security_group" "ssh_access" {
  name        = "${var.project_name}-${var.project_env}-ssh-access"
  description = "${var.project_name}-${var.project_env}-ssh-access"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}
#------------------------------------------
#Creating EC2 instance
#------------------------------------------
resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.latest.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.auth_key.key_name
  vpc_security_group_ids = [aws_security_group.http_access.id, aws_security_group.ssh_access.id]
  tags = {
    Name    = "${var.project_name}-${var.project_env}-frontend"
    project = var.project_name
    env     = var.project_env
  }

  lifecycle {

    create_before_destroy = true
  }

}

#------------------------------------------
#Creating route53 in new branch
#------------------------------------------

resource "aws_route53_record" "terraform" {
  zone_id = var.hosted_zone_id
  name    = "${var.hostname}.${var.hosted_zone_name}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.webserver.public_ip]
}
