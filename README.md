# AWS CI/CD Pipeline Setup Guide

This guide will help you deploy a Python web application to AWS with automatic deployments from GitHub. Every time you push code to GitHub, it will automatically build and deploy to your EC2 server.

---

## 📋 What You'll Need

- A computer with internet connection
- An AWS account (free tier is fine)
- A GitHub account
- About 30-45 minutes

---

## 🚀 Step 1: Install Required Software

### 1.1 Install Terraform

Terraform is the tool that creates AWS resources automatically.

**Windows:**
1. Download Terraform from: https://www.terraform.io/downloads
2. Extract the `.zip` file to `C:\terraform`
3. Add to Windows PATH:
   - Press `Windows Key`, search for "Environment Variables"
   - Click "Edit the system environment variables"
   - Click "Environment Variables" button
   - Under "System variables", find and select "Path", click "Edit"
   - Click "New" and add: `C:\terraform`
   - Click "OK" on all windows
4. Open a **new** PowerShell window and verify:
   ```powershell
   terraform version
   ```
   Notes: Alternatively you can use scoop for installing terraform https://scoop.sh/#/

**Mac:**
```bash
brew install terraform
```

**Linux:**
```bash
sudo apt-get update
sudo apt-get install terraform
```

**Notes**!!!: To make things simpler I recommend to use scoop for installing terraform and git (or anything on windows if available on scoop) https://scoop.sh/#/

### 1.2 Install Git (if not already installed)

**Windows:** Download from https://git-scm.com/download/win

**Mac:**
```bash
brew install git
```

**Linux:**
```bash
sudo apt-get install git
```

Verify installation:
```bash
git --version
```

---

## 🔐 Step 2: Set Up AWS Credentials

### 2.1 Create an AWS Access Key

1. Log in to your AWS Console: https://console.aws.amazon.com
2. Click your username (top-right) → **Security credentials**
3. Scroll down to **Access keys** section
4. Click **Create access key**
5. Select **Command Line Interface (CLI)**
6. Check the confirmation box and click **Next**
7. Click **Create access key**
8. **IMPORTANT:** Copy both:
   - Access key ID (looks like: `AKIAIOSFODNN7EXAMPLE`)
   - Secret access key (looks like: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

### 2.2 Configure AWS Credentials on Your Computer

**Option A: Using AWS Credentials File (RECOMMENDED)**

1. Create the `.aws` folder in your home directory:

   **Windows (PowerShell):**
   ```powershell
   New-Item -Path "$env:USERPROFILE\.aws" -ItemType Directory -Force
   ```

   **Mac/Linux:**
   ```bash
   mkdir -p ~/.aws
   ```

2. Create a `credentials` file:

   **Windows (PowerShell):**
   ```powershell
   notepad "$env:USERPROFILE\.aws\credentials"
   ```

   **Mac/Linux:**
   ```bash
   nano ~/.aws/credentials
   ```

3. Add your credentials (replace with your actual keys):
   ```
   [default]
   aws_access_key_id = AKIAIOSFODNN7EXAMPLE
   aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

4. Save and close the file
   - **Windows:** Click File → Save, then close Notepad
   - **Mac/Linux:** Press `Ctrl+O`, `Enter`, then `Ctrl+X`

**Option B: Using Environment Variables**

**Windows (PowerShell):**
```powershell
$env:AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_DEFAULT_REGION="us-east-1"
```

**Mac/Linux (Bash):**
```bash
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## 🔑 Step 3: Create an EC2 Key Pair

This allows you to connect to your server if needed.

1. Go to AWS Console: https://console.aws.amazon.com/ec2
2. Make sure you're in the **us-east-1** region (check top-right corner)
3. In the left menu, click **Key Pairs** (under "Network & Security")
4. Click **Create key pair**
5. Name it: `ec2-key-pair`
6. Key pair type: **RSA**
7. Private key format: `.pem` (Mac/Linux) or `.ppk` (Windows)
8. Click **Create key pair**
9. Save the downloaded file in a safe place

---

## 📁 Step 4: Fork and Clone This Repository

### 4.1 Fork the Repository

1. Go to: https://github.com/kouong/aws-group-yde
2. Click the **Fork** button (top-right)
3. This creates a copy in your GitHub account

### 4.2 Clone Your Fork

```bash
git clone https://github.com/YOUR-USERNAME/aws-group-yde.git
cd aws-group-yde
```

Replace `YOUR-USERNAME` with your actual GitHub username.

### 4.3 Update the Repository Reference

Open `infra/main.tf` and find line 635:
```terraform
FullRepositoryId     = "kouong/aws-group-yde"
```

Change it to:
```terraform
FullRepositoryId     = "YOUR-USERNAME/aws-group-yde"
```

Save the file.

---

## 🏗️ Step 5: Deploy Infrastructure to AWS

### 5.1 Initialize Terraform

Open PowerShell/Terminal in the project folder:

```bash
cd infra
terraform init
```

This downloads necessary Terraform plugins. You should see "Terraform has been successfully initialized!"

### 5.2 Preview What Will Be Created

```bash
terraform plan
```

This shows all the AWS resources that will be created. Review the output to see:
- EC2 instance (your web server)
- CodePipeline (automation pipeline)
- CodeBuild (builds your app)
- CodeDeploy (deploys your app)
- IAM roles and security groups

### 5.3 Create AWS Resources

```bash
terraform apply
```

- Type `yes` when prompted
- Wait 3-5 minutes for resources to be created
- **IMPORTANT:** Copy the `ec2_public_ip` shown at the end (you'll need this later)

---

## 🔗 Step 6: Connect GitHub to AWS

Terraform created a connection, but you must approve it manually.

1. Go to AWS Console: https://console.aws.amazon.com
2. Search for **CodePipeline** → **Settings** → **Connections**
3. Find `12-weeks-aws-github-con-2025`
4. Status will show **Pending**
5. Click on it, then click **Update pending connection**
6. Click **Install a new app** (or select existing GitHub app)
7. Log in to GitHub if prompted
8. Select your forked repository
9. Click **Connect**
10. Status should change to **Available** ✅

---

## 🎉 Step 7: Test Your Pipeline

### 7.1 Trigger the Pipeline

Make a small change to test automatic deployment:

```bash
cd ..
git add frontend/app.py infra/main.tf
git commit -m "Test pipeline"
git push origin main
```

### 7.2 Watch the Pipeline

1. Go to AWS Console → **CodePipeline**
2. Click **12weeks-aws-workshop-pipeline-2025**
3. Watch the three stages:
   - **Source** (gets code from GitHub) - ~30 seconds
   - **Build** (packages your app) - ~2-3 minutes
   - **Deploy** (deploys to EC2) - ~2-3 minutes

Total time: 5-7 minutes

### 7.3 View Your Application

Once all stages show ✅ **Succeeded**:

Open your browser and go to:
```
http://YOUR-EC2-PUBLIC-IP
```

Replace `YOUR-EC2-PUBLIC-IP` with the IP from Step 5.3.

You should see your Python Flask application! 🎊

---

## 🔄 Making Changes

Every time you push code to GitHub, the pipeline automatically:
1. Detects the change
2. Builds your application
3. Deploys to your EC2 server

Try it:
```bash
# Edit frontend/app.py - change some text
notepad frontend/app.py =>  search for the word "lightblue" and change it to another color. (eg. green)
git add frontend/app.py
git commit -m "Update app"
git push origin main
```

***Important notes***
1. If you see *** Please Tell me who you are. , just run the suggest commands as there are
```
git config --golbal user.email "you@example.com"
git config --global user.name "Your Name"
```

2. If there is a popup windows "CredentialHelperSelector", choose  "manager" and choose to login via Browser and then click "Select". You might then be asked to enter github username and password.

Wait 5-7 minutes, then refresh your browser to see the changes!

---

## 🧹 Cleaning Up (Delete Everything)

To avoid AWS charges, delete all resources when done:

```bash
cd infra
terraform destroy
```

Type `yes` when prompted. This removes everything from AWS.

Since the S3 bucket is not empty you will get an error message becaue the bucket must first be emptied before deletion. You can just go the aws console, empty the bucket and then delete the bucket.

---

## 🐛 Troubleshooting

### Issue: "terraform: command not found"
- **Solution:** Restart your terminal after installing Terraform

### Issue: "Error: No valid credential sources found"
- **Solution:** Double-check Step 2.2. Make sure credentials are saved correctly

### Issue: EC2 instance not accessible
- **Solution:** Wait 2-3 minutes after deployment. EC2 needs time to install CodeDeploy agent

### Issue: Pipeline fails at Deploy stage
- **Solution:** 
  1. Make sure you completed Step 6 (GitHub connection)
  2. Check CodeDeploy logs in AWS Console

### Issue: "A resource with that name already exists"
- **Solution:** Someone else used the same S3 bucket name. Edit `infra/main.tf` line 339:
  ```terraform
  bucket = "12weeks-aws-workshop-2025-bucket-YOUR-INITIALS"
  ```

---

## 📚 What Gets Created in AWS

| Resource | Purpose | Free Tier? |
|----------|---------|------------|
| EC2 Instance (t2.micro) | Your web server | ✅ Yes (750 hours/month) |
| S3 Bucket | Stores deployment files | ✅ Yes (5GB) |
| CodePipeline | Automates deployments | ❌ No ($1/month) |
| CodeBuild | Builds your application | ✅ Yes (100 min/month) |
| CodeDeploy | Deploys to EC2 | ✅ Yes (free for EC2) |

**Estimated Cost:** $1-2/month (mostly CodePipeline)

---

## 🎓 Learn More

- **Terraform Docs:** https://www.terraform.io/docs
- **AWS CodePipeline:** https://aws.amazon.com/codepipeline/
- **AWS Free Tier:** https://aws.amazon.com/free/

---

## ✅ Architecture Overview

```
GitHub Repository
      ↓
   [Push Code]
      ↓
CodePipeline (Orchestrator)
      ↓
  ┌───┴───┬─────────┐
  │       │         │
Source → Build → Deploy
  │       │         │
GitHub CodeBuild CodeDeploy
  │       │         │
  └───────┴─────→ EC2
                    │
              [Your App Running]
                    │
              http://your-ip
```

---

## 📝 Project Structure

```
aws-group-yde/
├── frontend/           # Your Python Flask application
│   ├── app.py         # Main application file
│   ├── appspec.yml    # Deployment instructions for CodeDeploy
│   └── scripts/       # Deployment lifecycle scripts
├── infra/             # Terraform infrastructure code
│   ├── main.tf        # Main infrastructure definitions
│   ├── output.tf      # Output values (like EC2 IP)
│   └── variables.tf   # Configurable variables
└── buildspec.yaml     # Build instructions for CodeBuild
```

---

## 🆘 Need Help?

If you get stuck:
1. Check the Troubleshooting section above
2. Review AWS CloudWatch logs for detailed error messages
3. Make sure all prerequisites are installed correctly
4. Verify your AWS credentials are configured properly

---

**Happy Deploying! 🚀**