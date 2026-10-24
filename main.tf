# AMI mas reciente de Amazon Linux 2023
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Red
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Seguridad: solo HTTP desde internet, sin SSH
resource "aws_security_group" "web" {
  name        = "${var.project_name}-web-sg"
  description = "Permite HTTP (80) entrante"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Salida libre"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-web-sg"
    Project = var.project_name
  }
}

# Servidor web con nginx
resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable --now nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="es">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>NexaTech POC - Innova Systems</title>
        <style>
          body {
            margin: 0;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 40px;
            font-family: Montserrat, Arial, sans-serif;
            background: #0d2a48;
            color: #ffffff;
            text-align: center;
          }
          .brand { display: flex; align-items: center; gap: 24px; }
          .brand svg { width: 110px; height: 108px; }
          .name { text-align: left; line-height: 1; }
          .name .top { font-size: 56px; font-weight: 800; letter-spacing: 1px; }
          .name .bottom { font-size: 38px; font-weight: 300; letter-spacing: 4px; color: #b4bdd8; margin-top: 8px; }
          .card {
            padding: 28px 48px;
            border: 1px solid #15416e;
            border-radius: 16px;
            background: #15416e;
          }
          .card h1 { font-size: 22px; font-weight: 600; margin: 0 0 8px; }
          .card p { margin: 0; color: #b4bdd8; }
          .dot { display: inline-block; width: 10px; height: 10px; background: #1caea3; margin-right: 8px; }
        </style>
      </head>
      <body>
        <div class="brand">
          <svg viewBox="0 0 558 550" xmlns="http://www.w3.org/2000/svg">
            <rect width="558" height="550" rx="70" fill="#15416e"/>
            <rect x="103" y="113" width="55" height="55" fill="#1caea3"/>
            <rect x="103" y="226" width="55" height="210" fill="#ffffff"/>
            <rect x="211" y="113" width="243" height="56" fill="#ffffff"/>
            <rect x="211" y="113" width="55" height="163" fill="#ffffff"/>
            <rect x="211" y="221" width="243" height="55" fill="#ffffff"/>
            <rect x="400" y="221" width="54" height="215" fill="#ffffff"/>
            <rect x="211" y="381" width="243" height="55" fill="#ffffff"/>
          </svg>
          <div class="name">
            <div class="top">INNOVA</div>
            <div class="bottom">SYSTEMS</div>
          </div>
        </div>
        <div class="card">
          <h1><span class="dot"></span>NexaTech Solutions - POC de Infraestructura como Codigo</h1>
          <p>Servidor creado con Terraform por Innova Systems.</p>
        </div>
      </body>
    </html>
    HTML
  EOF

  user_data_replace_on_change = true

  tags = {
    Name    = "${var.project_name}-web"
    Project = var.project_name
  }
}