# 2CLD3 – Introduction au Cloud

Ressources pédagogiques de la formation **Introduction au Cloud** — supports de TP et fichiers de départ.

---

## Structure du dépôt

```
.
├── 2CLD3_TP1_etudes_de_cas_cloud.html              ← TP1 – Études de cas (avec corrigé)
├── 2CLD3_TP2_comparatif_AWS_Azure_GCP.html         ← TP2 – Les 3 grands acteurs du Cloud
├── 2CLD3_TP3_site_statique_S3_LocalStack.html      ← TP3 – Site S3 statique sur LocalStack (interface web + CLI)
├── 2CLD3_TP4_IaC_Terraform_S3.html                 ← TP4 – Même site S3, déployé via Terraform
├── 2CLD3_TP5_IaC_Terraform_serverless.html         ← TP5 – Application serverless (Lambda + API Gateway + DynamoDB)
│
├── 2CLD3P - initiation aux clouds/                ← Fichiers HTML du site statique (TP3)
│   ├── index.html
│   └── error.html
│
├── tp3-terraform-s3/                              ← Code Terraform du TP4
│   ├── main.tf
│   ├── index.html
│   └── error.html
│
└── tp4-terraform-serverless/                      ← Code Terraform du TP5
    ├── main.tf
    ├── frontend/
    │   └── index.html.tpl
    └── lambda/
        ├── register.py
        └── login.py
```

---

## Prérequis communs

| Outil | Vérification | Installation rapide |
|---|---|---|
| Docker Desktop | `docker --version` | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop) |
| LocalStack CLI | `localstack --version` | `pip install localstack` |
| AWS CLI | `aws --version` | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| Terraform | `terraform --version` | `winget install HashiCorp.Terraform` (Windows) |

> **Token LocalStack** : un token d'accès vous sera fourni par le formateur. Stockez-le dans une variable d'environnement, ne l'écrivez jamais en dur dans une commande.
>
> ```powershell
> $env:LOCALSTACK_AUTH_TOKEN = "ls-XXXXXXXXXXXX"
> ```

---

## Progression des TPs

### TP1 – Études de cas cloud
Ouvrir `2CLD3_TP1_etudes_de_cas_cloud.html` dans un navigateur.  
Analyse de quatre migrations réelles (Netflix, Spotify, Dropbox, Capital One).

---

### TP2 – Comparatif AWS / Azure / Google Cloud
Ouvrir `2CLD3_TP2_comparatif_AWS_Azure_GCP.html`.  
Positions, forces, limites, services équivalents et critères de choix entre les 3 grands providers.

---

### TP3 – Site statique S3 sur LocalStack
Ouvrir `2CLD3_TP3_site_statique_S3_LocalStack.html`.  
Déploiement manuel d'un site HTML via l'interface web de LocalStack et l'AWS CLI.  
Fichiers source dans `2CLD3P - initiation aux clouds/`.

---

### TP4 – Infrastructure as Code avec Terraform (S3)
Ouvrir `2CLD3_TP4_IaC_Terraform_S3.html`.  
Même site S3 mais déployé entièrement par Terraform. Introduction à `init / plan / apply / destroy`.  
Code de départ dans `tp3-terraform-s3/`.

```bash
cd tp3-terraform-s3
terraform init
terraform plan
terraform apply
```

---

### TP5 – Application serverless complète avec Terraform
Ouvrir `2CLD3_TP5_IaC_Terraform_serverless.html`.  
Inscription / connexion utilisateur : S3 (frontend) → API Gateway → Lambda Python → DynamoDB, le tout sur LocalStack via Terraform.  
Code de départ dans `tp4-terraform-serverless/`.

```bash
cd tp4-terraform-serverless
terraform init
terraform plan
terraform apply
```

---

## Lancer LocalStack

```powershell
docker run --rm -d `
  -p 4566:4566 `
  -e LOCALSTACK_AUTH_TOKEN `
  -v /var/run/docker.sock:/var/run/docker.sock `
  --name localstack `
  localstack/localstack-pro
```

Interface web : [app.localstack.cloud](https://app.localstack.cloud) → cliquer sur l'instance **localhost.localstack.cloud** → onglet **Resource Browser**.

---

> Les dossiers `_FORMATEUR/` contiennent les supports réservés à l'usage du formateur.
