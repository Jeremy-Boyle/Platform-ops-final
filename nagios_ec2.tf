#Website to grap ip
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

#Create our nagios log instance
resource "aws_instance" "nagios-server" {
    instance_type = "t2.micro"
    ami = data.aws_ami.ubuntu.id
    key_name = aws_key_pair.generated_key.key_name

    subnet_id = aws_subnet.sub-a.id
    vpc_security_group_ids = [aws_security_group.nagios.id]

    depends_on = [local_file.private_key]

    connection {
        host = aws_instance.nagios-server.public_ip
        user = "ubuntu"
        private_key = file(local_file.private_key.filename)
    }

    #Upload install script
    provisioner "file" {
        source      = "conf/install-nagios.sh"
        destination = "/tmp/install-nagios.sh"
    }

    #exc install script
    provisioner "remote-exec" {
        inline = [
            #Waits for complete
            "sudo cloud-init status --wait",
            "sudo chmod +x /tmp/install-nagios.sh",
            "sudo sh /tmp/install-nagios.sh"
        ]
    }

    #Configures apache2
    provisioner "file" {
        source      = "conf/apache_ports.conf"
        destination = "/tmp/apache_ports.conf"
    }

    #Configures nagios4
    provisioner "file" {
        source      = "conf/nagios_apache2.conf"
        destination = "/tmp/nagios_apache2.conf"
    }

    #Complete by copying files and starting services
    provisioner "remote-exec" {
        inline = [
            "sudo cp /tmp/apache_ports.conf /etc/apache2/ports.conf",
            "sudo cp /tmp/nagios_apache2.conf /etc/nagios4/apache2.conf",
            "sudo sed -i '18s/$/ ${chomp(data.http.myip.body)}\\/32/' /etc/nagios4/apache2.conf",
            "sudo htdigest -b -c /etc/nagios4/htdigest.users Nagios4 ${local.nagios_admin} ${local.nagios_password}",
            "sudo systemctl enable apache2",
            "sudo systemctl enable nagios4",
            "sudo systemctl start apache2",
            "sudo systemctl restart nagios4"
        ]
    }
    
    tags = {
        Name = "nagios-server"
    }

}

#Create a security_group for nagios
resource "aws_security_group" "nagios" {
    name        = "nagios_traffic"
    description = "Allows web inbound traffic"
    vpc_id = aws_vpc.vpc.id

    ingress {
        description = "Allow port 22 from our ip"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    }

    ingress {
        description = "Allow port 8080 for nagios"
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        #Grab http data and apply local ip
        cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
    }

    egress {
        description = "Allow outside traffic for updates"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        #Grab http data and apply local ip
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "nagios_traffic"
    }
}