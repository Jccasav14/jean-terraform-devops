#!/bin/bash
# ============================
# USER DATA para Amazon Linux 2023 + Docker + FastAPI (Imagen de jccasav)
# ============================

# Actualizar sistema
dnf update -y

# Instalar Docker
dnf install -y docker

# Habilitar Docker al arranque
systemctl enable docker
systemctl start docker

# Permitir que ec2-user use docker sin sudo
usermod -aG docker ec2-user

# Descargar imagen desde DockerHub (ajustada a tu usuario)
docker pull jccasav/fastapi-hello:latest

# Crear servicio systemd para mantener el contenedor corriendo siempre
cat << EOF > /etc/systemd/system/fastapi.service
[Unit]
Description=FastAPI HelloWorld Container
After=docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --name fastapi_app -p 80:8000 jccasav/fastapi-hello:latest
ExecStop=/usr/bin/docker stop fastapi_app
ExecStopPost=/usr/bin/docker rm fastapi_app

[Install]
WantedBy=multi-user.target
EOF

# Recargar systemd
systemctl daemon-reload

# Iniciar servicio de tu app
systemctl start fastapi.service
systemctl enable fastapi.service
