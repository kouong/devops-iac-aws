# Guide de configuration d’un pipeline CI/CD AWS

Ce guide va t’aider à déployer une application web Python sur AWS avec des déploiements automatiques depuis GitHub. À chaque fois que tu pushes du code sur GitHub, il va automatiquement builder et déployer sur ton serveur EC2.

---

## Ce dont tu auras besoin

* Un ordinateur avec une connexion Internet
* Un compte AWS (le free tier suffit)
* Un compte GitHub
* Environ 30–45 minutes

---

## Étape 1 : Installer les logiciels requis

### 1.1 Installer Terraform

Terraform est l’outil qui crée automatiquement les ressources AWS.

**Windows :**

1. Télécharger Terraform depuis : [https://www.terraform.io/downloads](https://www.terraform.io/downloads)
2. Extraire le fichier `.zip` vers `C:\terraform`
3. Ajouter au PATH Windows :

   * Appuyer sur `Windows Key`, rechercher « Environment Variables »
   * Cliquer sur « Edit the system environment variables »
   * Cliquer sur le bouton « Environment Variables »
   * Dans « System variables », trouver et sélectionner « Path », puis cliquer « Edit »
   * Cliquer « New » et ajouter : `C:\terraform`
   * Cliquer sur « OK » dans toutes les fenêtres
4. Ouvrir une nouvelle fenêtre PowerShell et vérifier :

```
terraform version
```

**Notes :** alternativement tu peux utiliser scoop pour installer terraform [https://scoop.sh/#/](https://scoop.sh/#/)

**Mac :**

```
brew install terraform
```

**Linux :**

```
sudo apt-get update
sudo apt-get install terraform
```

**Notes !!! :** pour simplifier, je recommande d’utiliser scoop pour installer terraform et git (ou n’importe quoi sous Windows si disponible sur scoop) [https://scoop.sh/#/](https://scoop.sh/#/)

### 1.2 Installer Git (si pas déjà installé)

**Windows :** télécharger depuis [https://git-scm.com/download/win](https://git-scm.com/download/win)

**Mac :**

```
brew install git
```

**Linux :**

```
sudo apt-get install git
```

Vérifier l’installation :

```
git --version
```

---

## Étape 2 : Configurer les identifiants AWS

### 2.1 Créer une clé d’accès AWS

1. Se connecter à la console AWS : [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Cliquer sur ton nom d’utilisateur (en haut à droite) → Security credentials
3. Descendre jusqu’à la section Access keys
4. Cliquer Create access key
5. Sélectionner Command Line Interface (CLI)
6. Cocher la case de confirmation et cliquer Next
7. Cliquer Create access key
8. **IMPORTANT :** copier les deux :

   * Access key ID (ressemble à : `AKIAIOSFODNN7EXAMPLE`)
   * Secret access key (ressemble à : `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

### 2.2 Configurer les identifiants AWS sur ton ordinateur

**Option A : utiliser le fichier AWS Credentials (RECOMMANDÉ)**

1. Créer le dossier `.aws` dans ton répertoire utilisateur :

   **Windows (PowerShell) :**

   ```
   New-Item -Path "$env:USERPROFILE\.aws" -ItemType Directory -Force
   ```

   **Mac/Linux :**

   ```
   mkdir -p ~/.aws
   ```

2. Créer un fichier `credentials` :

   **Windows (PowerShell) :**

   ```
   notepad "$env:USERPROFILE\.aws\credentials"
   ```

   **Mac/Linux :**

   ```
   nano ~/.aws/credentials
   ```

3. Ajouter tes identifiants (remplacer par tes vraies clés) :

   ```
   [default]
   aws_access_key_id = AKIAIOSFODNN7EXAMPLE
   aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

4. Sauvegarder et fermer le fichier

   * Windows : Click File → Save, puis fermer Notepad
   * Mac/Linux : appuyer sur `Ctrl+O`, `Enter`, puis `Ctrl+X`

**Option B : utiliser les variables d’environnement**

**Windows (PowerShell) :**

```
$env:AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
$env:AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
$env:AWS_DEFAULT_REGION="us-east-1"
```

**Mac/Linux (Bash) :**

```
export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## Étape 3 : Créer une paire de clés EC2

Cela te permet de te connecter à ton serveur si besoin.

1. Aller sur la console AWS : [https://console.aws.amazon.com/ec2](https://console.aws.amazon.com/ec2)
2. Vérifier que tu es dans la région **us-east-1** (regarder en haut à droite)
3. Dans le menu de gauche, cliquer Key Pairs (sous « Network & Security »)
4. Cliquer Create key pair
5. Nommer : `ec2-key-pair`
6. Type de paire de clés : RSA
7. Format de clé privée : `.pem` (Mac/Linux) ou `.ppk` (Windows)
8. Cliquer Create key pair
9. Sauvegarder le fichier téléchargé dans un endroit sûr

---

## Étape 4 : Fork et cloner ce dépôt

### 4.1 Fork du dépôt

1. Aller sur : [https://github.com/kouong/aws-group-yde](https://github.com/kouong/aws-group-yde)
2. Cliquer sur le bouton Fork (en haut à droite)
3. Cela crée une copie dans ton compte GitHub

### 4.2 Cloner ton fork

```
git clone https://github.com/YOUR-USERNAME/aws-group-yde.git
cd aws-group-yde
```

Remplacer `YOUR-USERNAME` par ton vrai nom d’utilisateur GitHub.

### 4.3 Mettre à jour la référence du dépôt

Ouvrir `infra/main.tf` et trouver la ligne 635 :

```
FullRepositoryId     = "kouong/aws-group-yde"
```

Modifier en :

```
FullRepositoryId     = "YOUR-USERNAME/aws-group-yde"
```

Sauvegarder le fichier.

---

## ️ Étape 5 : Déployer l’infrastructure sur AWS

### 5.1 Initialiser Terraform

Ouvrir PowerShell/Terminal dans le dossier du projet :

```
cd infra
terraform init
```

Cela télécharge les plugins Terraform nécessaires. Tu devrais voir : « Terraform has been successfully initialized! »

### 5.2 Prévisualiser ce qui va être créé

```
terraform plan
```

Cela affiche toutes les ressources AWS qui seront créées. Vérifie la sortie pour voir :

* EC2 instance (ton serveur web)
* CodePipeline (pipeline d’automatisation)
* CodeBuild (build ton app)
* CodeDeploy (déploie ton app)
* rôles IAM et security groups

### 5.3 Créer les ressources AWS

```
terraform apply
```

* Taper `yes` quand demandé
* Attendre 3–5 minutes que les ressources soient créées
* **IMPORTANT :** copier `ec2_public_ip` affichée à la fin (tu en auras besoin plus tard)

---

## Étape 6 : Connecter GitHub à AWS

Terraform a créé une connexion, mais tu dois l’approuver manuellement.

1. Aller sur la console AWS : [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. Rechercher CodePipeline → Settings → Connections
3. Trouver `12-weeks-aws-github-con-2025`
4. Le statut affichera Pending
5. Cliquer dessus, puis cliquer Update pending connection
6. Cliquer Install a new app (ou sélectionner une GitHub app existante)
7. Se connecter à GitHub si demandé
8. Sélectionner ton dépôt forké
9. Cliquer Connect
10. Le statut doit passer à Available ✅

---

## Étape 7 : Tester ton pipeline

### 7.1 Déclencher le pipeline

Faire un petit changement pour tester le déploiement automatique :

```
cd ..
git add frontend/app.py infra/main.tf
git commit -m "Test pipeline"
git push origin main
```

### 7.2 Suivre le pipeline

1. Aller sur AWS Console → CodePipeline
2. Cliquer 12weeks-aws-workshop-pipeline-2025
3. Observer les trois étapes :

   * Source (récupère le code depuis GitHub) – ~30 secondes
   * Build (package ton app) – ~2–3 minutes
   * Deploy (déploie sur EC2) – ~2–3 minutes

Temps total : 5–7 minutes

### 7.3 Voir ton application

Quand toutes les étapes affichent ✅ Succeeded :

Ouvrir ton navigateur et aller sur :

```
http://YOUR-EC2-PUBLIC-IP
```

Remplacer `YOUR-EC2-PUBLIC-IP` par l’IP de l’étape 5.3.

Tu devrais voir ton application Python Flask !

---

## Faire des modifications

À chaque push sur GitHub, le pipeline automatiquement :

1. détecte le changement
2. build ton application
3. déploie sur ton serveur EC2

Essaye :

```
# Edit frontend/app.py - change some text
notepad frontend/app.py =>  search for the word "lightblue" and change it to another color. (eg. green)
git add frontend/app.py
git commit -m "Update app"
git push origin main
```

### Notes importantes

1. Si tu vois `*** Please Tell me who you are.` , exécute juste les commandes suggérées car il y en a :

```
git config --golbal user.email "you@example.com"
git config --global user.name "Your Name"
```

2. S’il y a une popup Windows « CredentialHelperSelector », choisir « manager » et choisir de se connecter via Browser puis cliquer « Select ». On peut ensuite te demander le username et le mot de passe GitHub.

Attendre 5–7 minutes, puis rafraîchir le navigateur pour voir les changements !

---

## Nettoyage (tout supprimer)

Pour éviter des frais AWS, supprimer toutes les ressources une fois terminé :

```
cd infra
terraform destroy
```

Taper `yes` quand demandé. Cela supprime tout sur AWS.

Comme le bucket S3 n’est pas vide, tu auras un message d’erreur parce que le bucket doit d’abord être vidé avant suppression. Tu peux aller dans la console AWS, vider le bucket puis supprimer le bucket.

---

## Dépannage

### Problème : "terraform: command not found"

* Solution : redémarrer ton terminal après l’installation de Terraform

### Problème : "Error: No valid credential sources found"

* Solution : revérifier l’étape 2.2. S’assurer que les identifiants sont bien enregistrés

### Problème : instance EC2 inaccessible

* Solution : attendre 2–3 minutes après le déploiement. EC2 a besoin de temps pour installer l’agent CodeDeploy

### Problème : le pipeline échoue à l’étape Deploy

* Solution :

  1. Vérifier que tu as bien terminé l’étape 6 (connexion GitHub)
  2. Vérifier les logs CodeDeploy dans la console AWS

### Problème : "A resource with that name already exists"

* Solution : quelqu’un d’autre a utilisé le même nom de bucket S3. Modifier `infra/main.tf` ligne 339 :

```
bucket = "12weeks-aws-workshop-2025-bucket-YOUR-INITIALS"
```

---

## Ce qui est créé sur AWS

| Ressource               | But                                | Free tier ?              |
| ----------------------- | ---------------------------------- | ------------------------ |
| EC2 Instance (t2.micro) | Ton serveur web                    | ✅ Oui (750 heures/mois)  |
| S3 Bucket               | Stocke les fichiers de déploiement | ✅ Oui (5GB)              |
| CodePipeline            | Automatise les déploiements        | ❌ Non ($1/mois)          |
| CodeBuild               | Build ton application              | ✅ Oui (100 min/mois)     |
| CodeDeploy              | Déploie sur EC2                    | ✅ Oui (gratuit pour EC2) |

Coût estimé : $1–2/mois (principalement CodePipeline)

---

## En savoir plus

* Terraform Docs : [https://www.terraform.io/docs](https://www.terraform.io/docs)
* AWS CodePipeline : [https://aws.amazon.com/codepipeline/](https://aws.amazon.com/codepipeline/)
* AWS Free Tier : [https://aws.amazon.com/free/](https://aws.amazon.com/free/)

---

## ✅ Vue d’ensemble de l’architecture

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

## Structure du projet

```
aws-group-yde/
├── frontend/           # Ton application Python Flask
│   ├── app.py         # Fichier principal de l’application
│   ├── appspec.yml    # Instructions de déploiement pour CodeDeploy
│   └── scripts/       # Scripts du cycle de vie de déploiement
├── infra/             # Code Terraform de l’infrastructure
│   ├── main.tf        # Définitions principales
│   ├── output.tf      # Valeurs output (comme l’IP EC2)
│   └── variables.tf   # Variables configurables
└── buildspec.yaml     # Instructions de build pour CodeBuild
```

---

## Besoin d’aide ?

Si tu bloques :

1. Vérifie la section Dépannage ci-dessus
2. Consulte les logs AWS CloudWatch pour des erreurs détaillées
3. Assure-toi que tous les prérequis sont installés correctement
4. Vérifie que tes identifiants AWS sont bien configurés

---

Happy Deploying!
