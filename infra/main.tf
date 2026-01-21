# ============================================================================
# AWS PROVIDER CONFIGURATION
# ============================================================================
# Specifies which AWS region to deploy resources in
# All resources in this file will be created in us-east-1 (North Virginia)

provider "aws" {
  region = "us-east-1"
}

# ============================================================================
# IAM ROLES AND POLICIES FOR CODEDEPLOY
# ============================================================================
# CodeDeploy needs permissions to deploy applications to EC2 instances
# These resources create the necessary IAM role and attach required policies

# ----------------------------------------------------------------------------
# IAM ROLE FOR CODEDEPLOY SERVICE
# ----------------------------------------------------------------------------
# This role allows CodeDeploy service to perform deployments on your behalf
# It can read deployment configurations and update EC2 instances

resource "aws_iam_role" "codedeploy_role" {
  name = "12weeks-aws-workshop-codedeploy-role-2025"

  # This policy allows CodeDeploy service to assume (use) this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codedeploy.amazonaws.com" # Only CodeDeploy service can use this role
      }
      Effect = "Allow"
    }]
  })

  tags = {
    Name        = "12weeks-aws-workshop-codedeploy-role-2025"
    Environment = "Workshop"
  }
}

# Attach AWS managed policy that gives CodeDeploy the permissions it needs
# This policy allows CodeDeploy to read Auto Scaling groups, EC2 instances, and tags
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ============================================================================
# IAM ROLES AND POLICIES FOR EC2 INSTANCE
# ============================================================================
# EC2 instance needs permissions to interact with CodeDeploy and S3
# This allows the instance to download deployment artifacts and communicate with CodeDeploy

# ----------------------------------------------------------------------------
# IAM ROLE FOR EC2 INSTANCE
# ----------------------------------------------------------------------------
# This role gives the EC2 instance permissions to access AWS services
# Without this, the instance cannot download deployment packages from S3

resource "aws_iam_role" "ec2_role" {
  name = "12weeks-aws-workshop-ec2-role-2025"

  # This policy allows EC2 service to assume (use) this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com" # Only EC2 service can use this role
      }
      Effect = "Allow"
    }]
  })

  tags = {
    Name        = "12weeks-aws-workshop-ec2-role-2025"
    Environment = "Workshop"
  }
}

# Attach policy that allows EC2 to read from S3
# This lets the EC2 instance download deployment artifacts from S3 buckets
resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach policy that allows EC2 to work with CodeDeploy
# This enables the CodeDeploy agent running on EC2 to communicate with CodeDeploy service
resource "aws_iam_role_policy_attachment" "ec2_codedeploy_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# ----------------------------------------------------------------------------
# INSTANCE PROFILE FOR EC2
# ----------------------------------------------------------------------------
# Instance Profile is a container for the IAM role that can be attached to EC2
# Think of it as a bridge between IAM roles and EC2 instances

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "12weeks-aws-workshop-ec2-profile-2025"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name        = "12weeks-aws-workshop-ec2-profile-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# SECURITY GROUP FOR EC2 INSTANCE
# ============================================================================
# Security groups act as virtual firewalls for your EC2 instances
# They control inbound and outbound traffic

# ----------------------------------------------------------------------------
# SECURITY GROUP RULES
# ----------------------------------------------------------------------------
# This security group allows:
# - Inbound: HTTP traffic on port 80 (so users can visit your website)
# - Outbound: All traffic (so EC2 can download updates and CodeDeploy agent)

resource "aws_security_group" "ec2_sg" {
  name        = "12weeks-aws-workshop-sg-2025"
  description = "Security group for 12 Weeks AWS Workshop EC2 instance"

  # INBOUND RULE: Allow HTTP traffic from anywhere
  # This lets anyone on the internet access your web application on port 80
  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 0.0.0.0/0 means "from anywhere on the internet"
  }

  # OUTBOUND RULE: Allow all traffic out
  # This lets the EC2 instance reach the internet to:
  # - Download CodeDeploy agent installation files
  # - Install Python packages (pip install)
  # - Download system updates (yum update)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow access to anywhere
  }

  tags = {
    Name        = "12weeks-aws-workshop-sg-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# EC2 INSTANCE
# ============================================================================
# This creates the virtual server (EC2 instance) where your application will run

# ----------------------------------------------------------------------------
# EC2 INSTANCE CONFIGURATION
# ----------------------------------------------------------------------------
# Instance Type: t2.micro (Free Tier eligible - 1 vCPU, 1 GB RAM)
# AMI: Amazon Linux 2023 (includes yum package manager)
# The user_data script runs ONCE when the instance first launches

resource "aws_instance" "web_server" {
  # Amazon Machine Image - the operating system and base software
  ami           = "ami-0bdd88bd06d16ba03" # Amazon Linux 2023 in us-east-1
  instance_type = "t2.micro"              # Small instance size (Free Tier eligible)

  # Attach the IAM instance profile (gives permissions to the instance)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Attach the security group (controls network access)
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # SSH key pair for remote access (if you need to SSH into the instance)
  # Make sure this key pair exists in your AWS account before applying
  key_name = "ec2-key-pair"

  # Tags help identify and organize your resources
  tags = {
    Name        = "12weeks-aws-workshop-2025"
    Environment = "Workshop"
    ManagedBy   = "Terraform"
  }

  # USER DATA SCRIPT
  # This bash script runs automatically when the instance launches
  # It installs the CodeDeploy agent which is required for deployments
  user_data = <<-EOF
              #!/bin/bash
              # Update all system packages to latest versions
              yum update -y
              
              # Install Ruby (required by CodeDeploy agent)
              yum install ruby -y
              
              # Install wget (tool to download files from the internet)
              yum install wget -y
              
              # Navigate to the ec2-user's home directory
              cd /home/ec2-user
              
              # Download the CodeDeploy agent installer from AWS S3
              wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
              
              # Make the installer executable
              chmod +x ./install
              
              # Run the installer (auto mode installs and starts the agent)
              ./install auto
              EOF
}

# ============================================================================
# CODEDEPLOY APPLICATION
# ============================================================================
# CodeDeploy Application is a container that groups deployment configurations
# Think of it as a project or application name in CodeDeploy

# ----------------------------------------------------------------------------
# CODEDEPLOY APPLICATION CONFIGURATION
# ----------------------------------------------------------------------------
# Compute Platform: Server (for EC2 instances)
# Other options: Lambda (for serverless) or ECS (for containers)

resource "aws_codedeploy_app" "web_app" {
  name             = "12weeks-aws-workshop-app-2025"
  compute_platform = "Server" # We're deploying to EC2 instances (servers)

  tags = {
    Name        = "12weeks-aws-workshop-app-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# CODEDEPLOY DEPLOYMENT GROUP
# ============================================================================
# Deployment Group specifies WHERE to deploy your application
# It identifies target EC2 instances using tags

# ----------------------------------------------------------------------------
# DEPLOYMENT GROUP CONFIGURATION
# ----------------------------------------------------------------------------
# This group targets EC2 instances with the tag "Name: 12weeks-aws-workshop-2025"
# When CodeDeploy runs, it will deploy to all instances matching this tag

resource "aws_codedeploy_deployment_group" "web_deploy_group" {
  # Link this deployment group to the CodeDeploy application
  app_name = aws_codedeploy_app.web_app.name

  # Name of this deployment group
  deployment_group_name = "12weeks-aws-workshop-deploy-group-2025"

  # IAM role that CodeDeploy uses to perform the deployment
  service_role_arn = aws_iam_role.codedeploy_role.arn

  # EC2 TAG FILTER
  # This tells CodeDeploy which EC2 instances to deploy to
  # It will deploy to any instance with the matching tag
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"                      # Tag key to match
      type  = "KEY_AND_VALUE"             # Match both key and value
      value = "12weeks-aws-workshop-2025" # Tag value to match
    }
  }

  tags = {
    Name        = "12weeks-aws-workshop-deploy-group-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# CI/CD PIPELINE RESOURCES
# ============================================================================
# This section creates an automated pipeline that will:
# 1. Detect changes in your GitHub repository
# 2. Build your application using CodeBuild
# 3. Deploy the built application to your EC2 instance using CodeDeploy
# ============================================================================

# ----------------------------------------------------------------------------
# S3 BUCKET FOR PIPELINE ARTIFACTS
# ----------------------------------------------------------------------------
# This bucket stores temporary files (artifacts) as they move between
# pipeline stages. Think of it as a relay station where the output of one
# stage becomes the input for the next stage.
# Example: Source code from GitHub → Build artifacts → Deployment package

resource "aws_s3_bucket" "pipeline_artifacts" {
  # Bucket name must be globally unique across ALL AWS accounts
  bucket = "12weeks-aws-workshop-2025-bucket"

  tags = {
    Name        = "12weeks-aws-workshop-2025-bucket"
    Environment = "Workshop"
  }
}

# Enable versioning on the artifacts bucket
# This keeps track of different versions of your artifacts, useful for rollbacks
resource "aws_s3_bucket_versioning" "pipeline_artifacts_versioning" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block all public access to the artifacts bucket for security
# This ensures no one from the internet can access your pipeline artifacts
resource "aws_s3_bucket_public_access_block" "pipeline_artifacts_pab" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true # Block public access control lists
  block_public_policy     = true # Block public bucket policies
  ignore_public_acls      = true # Ignore any existing public ACLs
  restrict_public_buckets = true # Restrict public bucket policies
}

# ----------------------------------------------------------------------------
# GITHUB CONNECTION
# ----------------------------------------------------------------------------
# This creates a connection between AWS and your GitHub account
# IMPORTANT: After Terraform creates this, you MUST manually approve it in
# the AWS Console under Developer Tools > Connections
# Without approval, the pipeline cannot access your GitHub repository

resource "aws_codestarconnections_connection" "github" {
  name          = "12-weeks-aws-github-con-2025"
  provider_type = "GitHub"

  tags = {
    Name        = "12-weeks-aws-github-con-2025"
    Environment = "Workshop"
  }
}

# ----------------------------------------------------------------------------
# IAM ROLE FOR CODEBUILD
# ----------------------------------------------------------------------------
# CodeBuild needs permission to perform actions on your behalf
# This role defines what CodeBuild is allowed to do

resource "aws_iam_role" "codebuild_role" {
  name = "12weeks-aws-workshop-codebuild-role-2025"

  # This policy allows CodeBuild service to assume (use) this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codebuild.amazonaws.com" # Only CodeBuild can use this role
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

# Define what permissions CodeBuild has when using the role above
resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_role.name
  name = "12weeks-aws-workshop-codebuild-policy-2025"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to create and write to CloudWatch Logs
        # This allows you to see build logs in AWS Console
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
        # Permission to read/write artifacts from/to S3
        # CodeBuild needs to get source code and save build results
        Effect = "Allow"
        Action = [
          "s3:GetObject",        # Download files from S3
          "s3:GetObjectVersion", # Get specific versions of files
          "s3:PutObject"         # Upload build artifacts to S3
        ]
        Resource = "${aws_s3_bucket.pipeline_artifacts.arn}/*"
      },
      {
        # Permission to list bucket contents
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.pipeline_artifacts.arn
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# CODEBUILD PROJECT
# ----------------------------------------------------------------------------
# This defines HOW your application will be built
# It uses the buildspec.yaml file in your repository root for build instructions

resource "aws_codebuild_project" "build_project" {
  name          = "12weeks-aws-workshop-project-2025"
  description   = "CodeBuild project for 12 Weeks AWS Workshop"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 10 # Maximum time (in minutes) a build can run before timing out

  # Configure how build artifacts are stored
  artifacts {
    type = "CODEPIPELINE" # Artifacts are managed by CodePipeline
  }

  # Caching configuration (disabled for simplicity)
  cache {
    type = "NO_CACHE"
  }

  # Define the build environment (the container where your build runs)
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"       # Small = 3 GB memory, 2 vCPUs
    image                       = "aws/codebuild/standard:7.0" # Ubuntu-based image with common tools
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD" # Use CodeBuild's credentials
    privileged_mode             = false       # Don't need Docker-in-Docker for this project
  }

  # Configure where the source code comes from
  source {
    type      = "CODEPIPELINE"   # Source comes from CodePipeline
    buildspec = "buildspec.yaml" # File that contains build commands
  }

  # Configure where build logs are stored
  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/12weeks-aws-workshop-project-2025"
      stream_name = "build-log"
    }
  }

  tags = {
    Name        = "12weeks-aws-workshop-project-2025"
    Environment = "Workshop"
  }
}

# ----------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP FOR CODEBUILD
# ----------------------------------------------------------------------------
# Creates a centralized location for storing build logs
# Retention is set to 7 days to reduce storage costs

resource "aws_cloudwatch_log_group" "codebuild_logs" {
  name              = "/aws/codebuild/12weeks-aws-workshop-project-2025"
  retention_in_days = 7 # Logs older than 7 days are automatically deleted

  tags = {
    Name        = "12weeks-aws-workshop-codebuild-logs"
    Environment = "Workshop"
  }
}

# ----------------------------------------------------------------------------
# IAM ROLE FOR CODEPIPELINE
# ----------------------------------------------------------------------------
# CodePipeline needs permission to orchestrate all the stages
# This role allows it to interact with S3, CodeBuild, CodeDeploy, and GitHub

resource "aws_iam_role" "codepipeline_role" {
  name = "12weeks-aws-workshop-codepipeline-role-2025"

  # Allow CodePipeline service to use this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = {
        Service = "codepipeline.amazonaws.com" # Only CodePipeline can use this role
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

# Define what permissions CodePipeline has
resource "aws_iam_role_policy" "codepipeline_policy" {
  role = aws_iam_role.codepipeline_role.name
  name = "12weeks-aws-workshop-codepipeline-policy-2025"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permissions to manage artifacts in S3
        # Pipeline moves files between stages using S3
        Effect = "Allow"
        Action = [
          "s3:GetObject",           # Download artifacts
          "s3:GetObjectVersion",    # Get specific artifact versions
          "s3:GetBucketVersioning", # Check bucket versioning status
          "s3:PutObject",           # Upload artifacts
          "s3:PutObjectAcl"         # Set permissions on uploaded objects
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        # Permissions to trigger and monitor CodeBuild
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds", # Check build status
          "codebuild:StartBuild"      # Start a new build
        ]
        Resource = aws_codebuild_project.build_project.arn
      },
      {
        # Permissions to trigger and monitor CodeDeploy
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",           # Start a deployment
          "codedeploy:GetApplication",             # Get app details
          "codedeploy:GetApplicationRevision",     # Get revision info
          "codedeploy:GetDeployment",              # Check deployment status
          "codedeploy:RegisterApplicationRevision" # Register new app version
        ]
        Resource = [
          aws_codedeploy_app.web_app.arn,
          "${aws_codedeploy_app.web_app.arn}/*",
          aws_codedeploy_deployment_group.web_deploy_group.arn
        ]
      },
      {
        # Permission to access deployment configurations
        # This includes AWS-managed configs like CodeDeployDefault.OneAtATime
        Effect = "Allow"
        Action = [
          "codedeploy:GetDeploymentConfig"
        ]
        Resource = "arn:aws:codedeploy:us-east-1:711387110440:deploymentconfig:*"
      },
      {
        # Permission to use the GitHub connection
        # This allows CodePipeline to pull source code from GitHub
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
# CODEPIPELINE - THE MAIN ORCHESTRATOR
# ============================================================================
# This is the heart of your CI/CD pipeline
# It coordinates the flow: GitHub → Build → Deploy to EC2
# Each "stage" represents a step in the process

resource "aws_codepipeline" "pipeline" {
  name    = "12weeks-aws-workshop-pipeline-2025"
  role_arn = aws_iam_role.codepipeline_role.arn

  # Define where to store artifacts between stages
  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # -------------------------
  # STAGE 1: SOURCE
  # -------------------------
  # This stage monitors your GitHub repository for changes
  # When you push code to the 'main' branch, it triggers the pipeline

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceOutput"]
      # This creates a zip file of your source code

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "kouong/aws-group-yde" # Your GitHub repo
        BranchName           = "main"                 # Which branch to monitor
        OutputArtifactFormat = "CODE_ZIP"             # Package source as a zip file
        DetectChanges        = true                   # Automatically trigger on new commits
      }
    }
  }

  # -------------------------
  # STAGE 2: BUILD
  # -------------------------
  # This stage takes your source code and builds it
  # It runs the commands defined in your buildspec.yaml file

  stage {
    name = "Build"

    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceOutput"] # Uses source code from Stage 1
      output_artifacts = ["BuildOutput"]  # Creates build artifacts for Stage 3

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
      }
    }
  }

  # -------------------------
  # STAGE 3: DEPLOY
  # -------------------------
  # This stage deploys your built application to the EC2 instance
  # It uses CodeDeploy and follows the instructions in appspec.yml

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      version         = "1"
      input_artifacts = ["BuildOutput"] # Uses build artifacts from Stage 2

      configuration = {
        ApplicationName     = aws_codedeploy_app.web_app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.web_deploy_group.deployment_group_name
      }
    }
  }

  tags = {
    Name        = "12weeks-aws-workshop-pipeline-2025"
    Environment = "Workshop"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================
# These values are displayed after running terraform apply
# They provide important information about your deployed resources

output "ec2_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "pipeline_name" {
  description = "The name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}
