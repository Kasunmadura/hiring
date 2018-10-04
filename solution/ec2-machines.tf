resource "aws_instance" "phpapp" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "t2.micro"
  count = 2 
  associate_public_ip_address = "true"
  subnet_id = "${aws_subnet.PublicAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.FrontEnd.id}"]
  key_name = "${var.key_name}"
  tags {
        Name = "phpapp"
  }
  user_data = <<HEREDOC
  #!/bin/bash
  yum update -y
  yum install -y httpd24 php56 php56-mysqlnd
  service httpd start
  chkconfig httpd on
  echo "<?php" >> /var/www/html/index.php
  echo "\$conn = new mysqli('mydatabase.kasun.internal', 'root', 'secret', 'test');" >> /var/www/html/index.php
  echo "\$sql = 'SELECT * FROM mytable'; " >> /var/www/html/index.php
  echo "\$result = \$conn->query(\$sql); " >>  /var/www/html/index.php
  echo "while(\$row = \$result->fetch_assoc()) { echo 'the value is: ' . \$row['mycol'] ;} " >> /var/www/html/index.php
  echo "\$conn->close(); " >> /var/www/html/index.php
  echo "?>" >> /var/www/html/index.php
HEREDOC
}

resource "aws_instance" "database" {
  ami           = "${lookup(var.AmiLinux, var.region)}"
  instance_type = "t2.micro"
  associate_public_ip_address = "false"
  subnet_id = "${aws_subnet.PrivateAZA.id}"
  vpc_security_group_ids = ["${aws_security_group.Database.id}"]
  key_name = "${var.key_name}"
  tags {
        Name = "database"
  }
  user_data = <<HEREDOC
  #!/bin/bash
  sleep 180
  yum update -y
  yum install -y mysql55-server
  service mysqld start
  /usr/bin/mysqladmin -u root password 'secret'
  mysql -u root -psecret -e "create user 'root'@'%' identified by 'secret';" mysql
  mysql -u root -psecret -e 'CREATE TABLE mytable (mycol varchar(255));' test
  mysql -u root -psecret -e "INSERT INTO mytable (mycol) values ('Hello New Company! kasun') ;" test
HEREDOC
}

resource "aws_elb" "web" {
  name = "kasun-elb"

  subnets         = ["${aws_subnet.PublicAZA.id}"]
  security_groups = ["${aws_security_group.FrontEnd.id}"]
  instances       = ["${aws_instance.phpapp.*.id}"]


  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

