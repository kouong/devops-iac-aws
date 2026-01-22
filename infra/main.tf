# ============================================================================
# CONFIGURATION DU PROVIDER AWS
# ============================================================================
# Spécifie la région AWS dans laquelle déployer les ressources
# Toutes les ressources de ce fichier seront créées dans us-east-1 (Virginie du Nord)

provider "aws" {
  region = "us-east-1"
}

# ============================================================================
# RÔLES ET POLITIQUES IAM POUR CODEDEPLOY
# ============================================================================
# CodeDeploy a besoin d’autorisations pour déployer des applications sur des instances EC2
# Ces ressources créent le rôle IAM nécessaire et attachent les politiques requises

# ----------------------------------------------------------------------------
# RÔLE IAM POUR LE SERVICE CODEDEPLOY
# ----------------------------------------------------------------------------
# Ce rôle permet au service CodeDeploy d’effectuer des déploiements en ton nom
# Il peut lire les configurations de déploiement et mettre à jour les instances EC2

resource "aws_iam_role" "codedeploy_role" {
  name = "12weeks-aws-workshop-codedeploy-role-2025"

  # Cette politique permet au service CodeDeploy d’assumer (utiliser) ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codedeploy.amazonaws.com" # Seul CodeDeploy peut utiliser ce rôle
      }
      Effect = "Allow"
    }]
  })

  tags = {
    Name        = "12weeks-aws-workshop-codedeploy-role-2025"
    Environment = "Workshop"
  }
}

# Attacher la politique AWS gérée qui donne à CodeDeploy les permissions nécessaires
# Cette politique permet à CodeDeploy de lire les Auto Scaling groups, les instances EC2 et les tags
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ============================================================================
# RÔLES ET POLITIQUES IAM POUR L’INSTANCE EC2
# ============================================================================
# L’instance EC2 a besoin d’autorisations pour interagir avec CodeDeploy et S3
# Cela permet à l’instance de télécharger les artefacts de déploiement et de communiquer avec CodeDeploy

# ----------------------------------------------------------------------------
# RÔLE IAM POUR L’INSTANCE EC2
# ----------------------------------------------------------------------------
# Ce rôle donne à l’instance EC2 des permissions pour accéder aux services AWS
# Sans cela, l’instance ne peut pas télécharger les packages de déploiement depuis S3

resource "aws_iam_role" "ec2_role" {
  name = "12weeks-aws-workshop-ec2-role-2025"

  # Cette politique permet au service EC2 d’assumer (utiliser) ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com" # Seul EC2 peut utiliser ce rôle
      }
      Effect = "Allow"
    }]
  })

  tags = {
    Name        = "12weeks-aws-workshop-ec2-role-2025"
    Environment = "Workshop"
  }
}

# Attacher la politique qui permet à EC2 de lire depuis S3
# Cela laisse l’instance EC2 télécharger les artefacts de déploiement depuis les buckets S3
resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attacher la politique qui permet à EC2 de fonctionner avec CodeDeploy
# Cela active l’agent CodeDeploy sur EC2 pour communiquer avec le service CodeDeploy
resource "aws_iam_role_policy_attachment" "ec2_codedeploy_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# ----------------------------------------------------------------------------
# PROFIL D’INSTANCE POUR EC2
# ----------------------------------------------------------------------------
# Le profil d’instance est un conteneur pour le rôle IAM qui peut être attaché à une instance EC2
# EC2 utilise cela pour obtenir des credentials AWS temporaires

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "12weeks-aws-workshop-ec2-profile-2025"
  role = aws_iam_role.ec2_role.name
}

# ============================================================================
# RÉSEAU : VPC, SUBNET, INTERNET GATEWAY, ROUTE TABLE
# ============================================================================
# Création d’un réseau simple où ton instance EC2 sera lancée

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "12weeks-aws-workshop-vpc-2025"
    Environment = "Workshop"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "12weeks-aws-workshop-igw-2025"
    Environment = "Workshop"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name        = "12weeks-aws-workshop-subnet-2025"
    Environment = "Workshop"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "12weeks-aws-workshop-rt-2025"
    Environment = "Workshop"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
}

# ============================================================================
# GROUPES DE SÉCURITÉ
# ============================================================================

# ----------------------------------------------------------------------------
# RÈGLES DU GROUPE DE SÉCURITÉ
# ----------------------------------------------------------------------------
# Ce groupe de sécurité autorise :
# - Entrant : trafic HTTP sur le port 80 (pour que les utilisateurs puissent visiter ton site)
# - Sortant : tout le trafic (pour que l’EC2 puisse télécharger les mises à jour et l’agent CodeDeploy)

resource "aws_security_group" "ec2_sg" {
  name        = "12weeks-aws-workshop-sg-2025"
  description = "Security group for 12 Weeks AWS Workshop EC2 instance"

  # RÈGLE ENTRANTE : autoriser le trafic HTTP depuis n’importe où
  # Cela permet à n’importe qui sur Internet d’accéder à ton application web sur le port 80
  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 signifie « depuis n’importe où sur Internet »
  }

  # RÈGLE SORTANTE : autoriser tout le trafic sortant
  # Cela permet à l’instance EC2 d’atteindre Internet pour :
  # - Télécharger les fichiers d’installation de l’agent CodeDeploy
  # - Installer des packages Python (pip install)
  # - Télécharger les mises à jour système (yum update)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 signifie tous les protocoles
    cidr_blocks = ["0.0.0.0/0"] # Autoriser l’accès vers n’importe où
  }

  tags = {
    Name        = "12weeks-aws-workshop-sg-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# INSTANCE EC2
# ============================================================================
# Lance une instance EC2 qui héberge ton application Flask
# Elle installe l’agent CodeDeploy requis pour les déploiements

resource "aws_instance" "web" {
  ami                    = "ami-0e001c9271cf7f3b9" # AMI : Amazon Linux 2023 (inclut yum)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Attacher le profil d’instance IAM (donne des permissions à l’instance)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Attacher le groupe de sécurité (contrôle l’accès réseau)

  key_name = "ec2-key-pair" # Paire de clés SSH pour accès distant (si tu dois te connecter en SSH)

  # Tags aident à identifier et organiser tes ressources
  tags = {
    Name        = "12weeks-aws-workshop-2025"
    Environment = "Workshop"
  }

  # SCRIPT USER DATA
  # Ce script bash s’exécute automatiquement au démarrage de l’instance
  user_data = <<-EOF
              #!/bin/bash
              
              # Mettre à jour tous les packages système aux dernières versions
              yum update -y
              
              # Installer Ruby (requis par l’agent CodeDeploy)
              yum install -y ruby
              
              # Installer wget (outil pour télécharger des fichiers depuis Internet)
              yum install -y wget
              
              # Aller dans le répertoire personnel de ec2-user
              cd /home/ec2-user
              
              # Télécharger l’installateur de l’agent CodeDeploy depuis AWS S3
              wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
              
              # Rendre l’installateur exécutable
              chmod +x ./install
              
              # Exécuter l’installateur (le mode auto installe et démarre l’agent)
              ./install auto
              
              # Démarrer et activer l’agent CodeDeploy
              systemctl start codedeploy-agent
              systemctl enable codedeploy-agent
              EOF
}

# ============================================================================
# APPLICATION CODEDEPLOY
# ============================================================================
# Application CodeDeploy qui représente ton application côté AWS

resource "aws_codedeploy_app" "web_app" {
  name = "12weeks-aws-workshop-app-2025"

  compute_platform = "Server"
}

# ============================================================================
# GROUPE DE DÉPLOIEMENT CODEDEPLOY
# ============================================================================
# Le groupe de déploiement spécifie OÙ déployer ton application
# Il identifie les instances EC2 cibles via des tags

# ----------------------------------------------------------------------------
# CONFIGURATION DU GROUPE DE DÉPLOIEMENT
# ----------------------------------------------------------------------------
# Ce groupe cible les instances EC2 avec le tag "Name: 12weeks-aws-workshop-2025"
# Quand CodeDeploy s’exécute, il déploiera sur toutes les instances correspondant à ce tag

resource "aws_codedeploy_deployment_group" "web_deploy_group" {
  # Lier ce groupe de déploiement à l’application CodeDeploy
  app_name = aws_codedeploy_app.web_app.name

  # Nom de ce groupe de déploiement
  deployment_group_name = "12weeks-aws-workshop-deploy-group-2025"

  # Rôle IAM que CodeDeploy utilise pour exécuter le déploiement
  service_role_arn = aws_iam_role.codedeploy_role.arn

  # FILTRE DE TAG EC2
  # Cela indique à CodeDeploy quelles instances EC2 cibler
  # Il déploiera sur toute instance ayant le tag correspondant
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"                      # Clé de tag à faire correspondre
      type  = "KEY_AND_VALUE"             # Faire correspondre clé et valeur
      value = "12weeks-aws-workshop-2025" # Valeur de tag à faire correspondre
    }
  }

  tags = {
    Name        = "12weeks-aws-workshop-deploy-group-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# BUCKET S3 POUR LES ARTEFACTS
# ============================================================================
# Le pipeline déplace les fichiers entre les étapes via S3
# Le nom du bucket doit être globalement unique sur TOUS les comptes AWS

resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "12weeks-aws-workshop-2025-bucket-YOUR-INITIALS"

  tags = {
    Name        = "12weeks-aws-workshop-2025-bucket"
    Environment = "Workshop"
  }
}

# ============================================================================
# CONFIGURATION CODESTAR CONNECTION (GITHUB)
# ============================================================================
# Cette connexion permet à CodePipeline d’accéder à ton dépôt GitHub

resource "aws_codestarconnections_connection" "github" {
  name          = "12-weeks-aws-github-con-2025"
  provider_type = "GitHub"
}

# ============================================================================
# CONFIGURATION CODEBUILD
# ============================================================================

# ----------------------------------------------------------------------------
# RÔLE IAM POUR CODEBUILD
# ----------------------------------------------------------------------------
# CodeBuild a besoin d’autorisations pour écrire des logs, accéder à S3 et exécuter les builds

resource "aws_iam_role" "codebuild_role" {
  name = "12weeks-aws-workshop-codebuild-role-2025"

  # Cette politique permet au service CodeBuild d’assumer (utiliser) ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codebuild.amazonaws.com" # Seul CodeBuild peut utiliser ce rôle
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })

  tags = {
    Name        = "12weeks-aws-workshop-codebuild-role-2025"
    Environment = "Workshop"
  }
}

# Définir quelles permissions CodeBuild a quand il utilise le rôle ci-dessus
resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name
  name = "12weeks-aws-workshop-codebuild-policy-2025"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission de créer et écrire dans CloudWatch Logs
        # Cela te permet de voir les logs de build dans la console AWS
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-1:*:log-group:/aws/codebuild/12weeks-aws-workshop-project-2025",
          "arn:aws:logs:us-east-1:*:log-group:/aws/codebuild/12weeks-aws-workshop-project-2025:*"
        ]
      },
      {
        # Permission de lire/écrire des artefacts vers/depuis S3
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.pipeline_artifacts.arn}/*" # Autoriser l’accès aux objets du bucket d’artefacts
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# PROJET CODEBUILD
# ----------------------------------------------------------------------------
# Ce projet exécute les commandes de build décrites dans buildspec.yaml

resource "aws_codebuild_project" "build_project" {
  name         = "12weeks-aws-workshop-project-2025"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE" # Configure comment les artefacts de build sont stockés
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
  }

  source {
    type = "CODEPIPELINE" # Configure d’où vient le code source
  }

  logs_config {
    cloudwatch_logs {
      group_name = "/aws/codebuild/12weeks-aws-workshop-project-2025"
    }
  }

  cache {
    type = "NO_CACHE" # Configuration de cache (désactivée pour simplicité)
  }

  tags = {
    Name        = "12weeks-aws-workshop-project-2025"
    Environment = "Workshop"
  }
}

# ----------------------------------------------------------------------------
# GROUPE DE LOGS CLOUDWATCH
# ----------------------------------------------------------------------------
# Configure où les logs de build sont stockés

resource "aws_cloudwatch_log_group" "codebuild_log_group" {
  name              = "/aws/codebuild/12weeks-aws-workshop-project-2025"
  retention_in_days = 7 # Les logs plus vieux que 7 jours sont automatiquement supprimés

  tags = {
    Name        = "12weeks-aws-workshop-codebuild-logs"
    Environment = "Workshop"
  }
}

# ----------------------------------------------------------------------------
# RÔLE IAM POUR CODEPIPELINE
# ----------------------------------------------------------------------------
# CodePipeline a besoin d’autorisations pour orchestrer toutes les étapes
# Ce rôle lui permet d’interagir avec S3, CodeBuild, CodeDeploy et GitHub

resource "aws_iam_role" "codepipeline_role" {
  name = "12weeks-aws-workshop-codepipeline-role-2025"

  # Autoriser le service CodePipeline à utiliser ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codepipeline.amazonaws.com" # Seul CodePipeline peut utiliser ce rôle
      }
      Effect = "Allow"
      Sid    = ""
    }]
  })

  tags = {
    Name        = "12weeks-aws-workshop-codepipeline-role-2025"
    Environment = "Workshop"
  }
}

# Définir quelles permissions CodePipeline a
resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.name
  name = "12weeks-aws-workshop-codepipeline-policy-2025"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permissions pour gérer les artefacts dans S3
        # Le pipeline déplace les fichiers entre les étapes via S3
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        # Permissions pour déclencher et surveiller CodeBuild
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = aws_codebuild_project.build_project.arn
      },
      {
        # Permissions pour déclencher et surveiller CodeDeploy
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = [
          aws_codedeploy_app.web_app.arn,
          "${aws_codedeploy_app.web_app.arn}/*",
          aws_codedeploy_deployment_group.web_deploy_group.arn
        ]
      },
      {
        # Permission d’accéder aux configurations de déploiement
        # Cela inclut des configs gérées par AWS comme CodeDeployDefault.OneAtATime
        Effect = "Allow"
        Action = [
          "codedeploy:GetDeploymentConfig"
        ]
        Resource = "arn:aws:codedeploy:us-east-1:711387110440:deploymentconfig:*"
      },
      {
        # Permission d’utiliser la connexion GitHub
        # Cela permet à CodePipeline de récupérer le code source depuis GitHub
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}

# ============================================================================
# CODEPIPELINE — L’ORCHESTRATEUR PRINCIPAL
# ============================================================================
# Ceci est le cœur de ton pipeline CI/CD
# Il coordonne le flux : GitHub → Build → Déploiement sur EC2
# Chaque « stage » représente une étape du processus

resource "aws_codepipeline" "pipeline" {
  name     = "12weeks-aws-workshop-pipeline-2025"
  role_arn = aws_iam_role.codepipeline_role.arn

  # Définir où stocker les artefacts entre les étapes
  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # STAGE 1 : SOURCE
  # -------------------------
  # Cette étape surveille ton dépôt GitHub pour des changements
  # Quand tu pushes du code sur la branche 'main', cela déclenche le pipeline
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "kouong/devops-iac-aws"
        BranchName           = "main"
        OutputArtifactFormat = "CODE_ZIP" # Cela crée un fichier zip de ton code source
      }
    }
  }

  # -------------------------
  # STAGE 2 : BUILD
  # -------------------------
  # Cette étape prend ton code source et le build
  # Il exécute les commandes définies dans ton fichier buildspec.yaml
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  # -------------------------
  # STAGE 3 : DEPLOY
  # -------------------------
  # Cette étape déploie ton application buildée sur l’instance EC2
  # Elle utilise CodeDeploy et suit les instructions dans appspec.yml
  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ApplicationName     = aws_codedeploy_app.web_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.web_deploy_group.deployment_group_name
      }
    }
  }
}

# ============================================================================
# SORTIES
# ============================================================================
# Ces valeurs sont affichées après l’exécution de terraform apply
# Elles fournissent des informations importantes sur tes ressources déployées

output "ec2_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP address of the EC2 instance"
}

output "pipeline_name" {
  value       = aws_codepipeline.pipeline.name
  description = "Name of the CodePipeline"
}

output "codedeploy_app_name" {
  value       = aws_codedeploy_app.web_app.name
  description = "Name of the CodeDeploy application"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.pipeline_artifacts.bucket
  description = "Name of the S3 bucket for artifacts"
}
