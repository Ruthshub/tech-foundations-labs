# This configures new Tech Foundations Cohorts
# Add new cohorts to the locals.cohort map
locals {
  cohorts = {
    BIR99 : {
      instructor_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDrrMuNdW6GceUKj6ke2IrugDaJrgEUGhdDAVLE9lC/+E/9nSqbGLsx/zZos2wHU2WTqPpihoq+1FOSrH9Iae+ep03C3PV6HvSudhFnBT8cQCxFkzJfzrGkTExQO27wToBX5FvnXJaGyj/IfHkEgILerLuLU/z0cVliuL5JacxIr8NMB5eA57GkX40GHkPWooaPs4UyIbVbpmwnjQhrF4ymPTyaa+imqn22MofD/8U5a2NBvPMFrzl6kGmabG9TO5xW8w+C/VvnOEG+wxYa6qpF4bWVWiqK/Hvuqe8IuqU1wjosUWbqEd2P6Q7hp79ry+FLZRgkLVa/q6974w7aUPRvmxyNxZFI9hjPhBa6xNnPsKeaF/LCjvwsfAhEKs/T7pR+VYy60F0QDDXekGMkhtnd+hQs1XTXznhSQg4W/fPmtvAEv9IwO2OW19TUarGoBsHtWwNKY8MzrvGIH2rO5UqT4/uY7d9IeN8b72HW/EFdR3xDUBafFrvMQCs3gDf9m3c= jamesbelchamber@pyrelaptop"
      learner_count         = 5
      single-vm-lab         = false
    }
  }
}

resource "aws_key_pair" "Instructor" {
  for_each   = local.cohorts
  key_name   = "${each.key}-instructor"
  public_key = each.value.instructor_public_key
  tags = {
    Course = "Tech Foundations"
    Cohort = each.key
    Name   = "${each.key} Instructor VM"
  }
}

resource "aws_instance" "InstructorVM" {
  for_each                    = aws_key_pair.Instructor
  ami                         = data.aws_ami.centos.id
  instance_type               = "t3a.micro"
  subnet_id                   = aws_subnet.global.id
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  associate_public_ip_address = true
  key_name                    = each.value.key_name
  user_data                   = <<EOF
#!/bin/bash -xe
dnf update -y
dnf install -y epel-release
dnf install -y ansible wget unzip
pip3 install -U pytest-testinfra
wget https://github.com/generation-org/tech-foundations-labs/archive/refs/heads/main.zip
unzip main.zip
cp -ar tech-foundations-labs-main/instructor_tools /home/centos/
chown -R centos:centos /home/centos/instructor_tools
EOF

  tags = {
    Course = "Tech Foundations"
    Cohort = each.value.tags_all.Cohort
    Name   = "${each.value.tags_all.Cohort} Instructor VM"
  }
}

module "single-vm-lab" {
  for_each = {
    for key, value in local.cohorts : key => value
    if value.single-vm-lab == true
  }
  source                = "./modules/single-vm-lab"
  ami_id = data.aws_ami.centos.id
  subnet_id = aws_subnet.global.id
  security_group_id = aws_security_group.allow_all.id

  cohort_name           = each.key
  learner_count         = each.value.learner_count
  instructor_public_key = aws_key_pair.Instructor[each.key].key_name
}