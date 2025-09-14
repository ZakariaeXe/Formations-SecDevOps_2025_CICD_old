# Fichier: infrastructure/terraform/vulnerable-aws.tf

# ❌ VULN 1: S3 Bucket public avec ACL ouverte
resource "aws_s3_bucket" "vulnerable_bucket" {
  bucket = "my-super-secret-data-bucket-${random_id.bucket_suffix.hex}"
  
  # ❌ VULNÉRABILITÉ: Bucket public
  acl = "public-read-write"  # DANGEREUX !
  
  # ❌ VULNÉRABILITÉ: Pas de chiffrement
  # server_side_encryption_configuration - MANQUANT !
  
  # ❌ VULNÉRABILITÉ: Versioning désactivé
  versioning {
    enabled = false
  }
  
  # ❌ VULNÉRABILITÉ: Pas de logging
  logging {
    # target_bucket - MANQUANT !
  }
}

# ❌ VULN 2: Groupe de sécurité trop ouvert
resource "aws_security_group" "vulnerable_sg" {
  name        = "vulnerable-web-sg"
  description = "Vulnerable security group"
  
  # ❌ VULNÉRABILITÉ: SSH ouvert au monde entier
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # DANGEREUX !
  }
  
  # ❌ VULNÉRABILITÉ: RDP ouvert au monde entier  
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # DANGEREUX !
  }
  
  # ❌ VULNÉRABILITÉ: Tous les ports ouverts en sortie
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ❌ VULN 3: Instance EC2 sans encryption et clés hardcodées
resource "aws_instance" "vulnerable_instance" {
  ami           = "ami-0c55b159cbfafe1d0"
  instance_type = "t2.micro"
  
  # ❌ VULNÉRABILITÉ: Clé SSH hardcodée
  key_name = "hardcoded-ssh-key"  # DANGEREUX !
  
  # ❌ VULNÉRABILITÉ: Pas de chiffrement du disque
  root_block_device {
    encrypted = false  # DANGEREUX !
  }
  
  # ❌ VULNÉRABILITÉ: Métadonnées IMDSv1
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"  # Devrait être "required"
  }
  
  # ❌ VULNÉRABILITÉ: User data avec secrets
  user_data = <<-EOF
              #!/bin/bash
              export DB_PASSWORD="super_secret_password_123"
              export API_KEY="sk-1234567890abcdef"
              echo "admin:password123" | chpasswd
              EOF

  vpc_security_group_ids = [aws_security_group.vulnerable_sg.id]
  
  tags = {
    Environment = "production"  # ❌ Pas de test en prod !
  }
}

# ❌ VULN 4: RDS sans encryption ni backup
resource "aws_db_instance" "vulnerable_db" {
  identifier = "vulnerable-database"
  
  engine         = "mysql"
  engine_version = "5.7"  # ❌ Version obsolète
  instance_class = "db.t2.micro"
  
  db_name  = "productiondb"
  username = "admin"
  password = "password123"  # ❌ VULNÉRABILITÉ: Mot de passe faible hardcodé
  
  allocated_storage = 20
  
  # ❌ VULNÉRABILITÉ: Pas de chiffrement
  storage_encrypted = false
  
  # ❌ VULNÉRABILITÉ: Pas de backup
  backup_retention_period = 0
  
  # ❌ VULNÉRABILITÉ: Accessible publiquement
  publicly_accessible = true
  
  # ❌ VULNÉRABILITÉ: Pas de monitoring
  monitoring_interval = 0
  
  # ❌ VULNÉRABILITÉ: Pas de logs d'audit
  enabled_cloudwatch_logs_exports = []
  
  skip_final_snapshot = true  # ❌ Dangereux en production
}
