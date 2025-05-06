# Linux System Auditor v1.1 By Soufianne Said NASSIBI 

![Bash](https://img.shields.io/badge/bash-5.x-blue.svg)
![License](https://img.shields.io/badge/license-GPLv3-green)

##  Description

**Linux System Auditor** est un script Bash avancé permettant d’effectuer un audit complet d’un système Linux, avec génération de rapport, recommandations automatiques, et option d’analyse par intelligence artificielle (Gemini ou OpenAI). Il est conçu pour être à la fois simple d’utilisation, portable et extensible.

##  Fonctionnalités principales

-  Audit détaillé :
  - Informations système (OS, kernel, uptime…)
  - Utilisation CPU / RAM / processus
  - Réseau, interfaces, DNS et routage
  - Analyse des disques (volumes, inode, SMART)
  - Services actifs et ports ouverts
  - Audit de sécurité (SSH root, sudo, firewall, comptes…)

-  Mode IA :
  - Possibilité d’analyse du rapport par Gemini ou OpenAI
  - Questions personnalisées à poser à l’IA (interface CLI)

-  Configuration :
  - Choix du fournisseur d’IA (Gemini ou OpenAI)
  - Stockage local de la clé API (encodée en base64)
  - Possibilité de supprimer ou de modifier la config

-  Génération de rapport :
  - Export dans un fichier `audit_report_<hostname>_<date>.txt`
  - Recommandations automatiques selon les résultats détectés

-  Respect de la vie privée :
  - Aucun appel externe sauf si l’utilisateur active le mode IA

##  Dépendances

Le script repose uniquement sur des utilitaires systèmes standard :

- `bash`, `awk`, `grep`, `ps`, `lscpu`, `ip`, `ss`, `df`, `lsblk`, `uptime`, `systemctl`, `find`, `jq` (pour OpenAI), `curl`
- Optionnel : `smartctl`, `lsof`, `bc`, `python3` (pour Gemini)

>  Aucune installation complexe n’est requise par défaut.

##  Installation

```bash
git clone https://github.com/<votre-utilisateur>/linux-system-auditor.git
cd linux-system-auditor
chmod +x auditor.sh
./auditor.sh
