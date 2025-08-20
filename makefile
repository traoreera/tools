# ============================================================
# 📌 Variables globales
# ============================================================
PROJECT_PATH_APP := $(shell pwd)/core
PROJECT_PATH := $(shell pwd)

# Variables pour gestion liens symboliques
FROM ?= /path/to/module.py     # Source du module (fichier ou dossier)
TO ?=  $(shell pwd)/backgroundtask           # Dossier destination
NAME ?= module.py              # Nom du lien symbolique

# Variables pour gestion plugins
PLUGIN_NAME ?= myplugin
AUTHOR ?= traoreera
PLUGIN_REPO ?= http://github.com/$(AUTHOR)/$(PLUGIN_NAME).git
PLUGIN_DIR := plugins/$(PLUGIN_NAME)


# ============================================================
# 📚 Commande HELP - Affiche toutes les commandes disponibles
# ============================================================
help: ## Afficher la liste des commandes disponibles et leur usage
	@echo "📚 Liste des commandes disponibles :"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# ============================================================
# 🔧 Gestion des plugins (git + liens symboliques)
# ============================================================

add-plugin: ## Ajouter ou mettre à jour un plugin git et lier les tâches dans backgroundtask
	@if [ -z "$(PLUGIN_NAME)" ]; then \
		echo "❌ Erreur : veuillez fournir PLUGIN_NAME"; \
		echo "   Exemple : make add-plugin PLUGIN_NAME=presence"; \
		exit 1; \
	fi
	@if [ -z "$(PLUGIN_REPO)" ]; then \
		echo "⚠️ PLUGIN_REPO non défini, utilisation par défaut git@github.com:tonrepo/$(PLUGIN_NAME).git"; \
		export PLUGIN_REPO=git@github.com:tonrepo/$(PLUGIN_NAME).git; \
	fi
	@if [ ! -d "$(PLUGIN_DIR)" ]; then \
		echo "📥 Clonage du plugin $(PLUGIN_NAME) depuis $(PLUGIN_REPO)..."; \
		git clone "$(PLUGIN_REPO)" "$(PLUGIN_DIR)" || { echo "❌ Échec du clonage"; exit 1; }; \
	else \
		echo "⬆️ Mise à jour du plugin $(PLUGIN_NAME)..."; \
		cd "$(PLUGIN_DIR)" && git pull || { echo "❌ Échec de la mise à jour"; exit 1; }; \
	fi
# ============================================================
# 🔗 Création / suppression de liens symboliques
# ============================================================

link: ## Créer un lien symbolique (usage: make link FROM=source TO=destination NAME=nom_lien)
	@if [ -z "$(FROM)" ] || [ -z "$(TO)" ] || [ -z "$(NAME)" ]; then \
		echo "❌ Erreur : il faut fournir FROM, TO et NAME"; \
		echo "   Exemple : make link FROM=./plugins/presence/task/presence_task.py TO=./backgroundtask NAME=presence.py"; \
		exit 1; \
	fi
	@if [ ! -f "$(FROM)" ]; then \
		echo "❌ Fichier source '$(FROM)' introuvable."; \
		exit 1; \
	fi
	@echo "🔗 Création du lien symbolique $(TO)/$(NAME) vers $(FROM)..."
	@if [ ! -d "$(TO)" ]; then \
		echo "📂 Création du dossier $(TO)"; \
		mkdir -p "$(TO)"; \
	fi

	@ln -sf "$(PROJECT_PATH)/$(FROM)" "$(TO)/$(NAME)"
	@echo "✅ Liens créés :"
	@echo "   $(TO)/$(NAME)"

unlink: ## Supprimer un lien symbolique (usage: make unlink TO=dossier NAME=nom_fichier)
	@echo "🗑 Suppression du lien symbolique $(TO)/$(NAME)..."
	@if [ -L "$(TO)/$(NAME)" ]; then \
		rm "$(TO)/$(NAME)"; \
		echo "✅ Lien supprimé : $(TO)/$(NAME)"; \
	else \
		echo "⚠️ Aucun lien trouvé pour $(TO)/$(NAME)"; \
	fi

# ============================================================
# 🧹 Nettoyage fichiers Python compilés
# ============================================================

clean: ## Supprimer __pycache__ et fichiers *.pyc, *.pyo
	@echo "🧹 Nettoyage des fichiers inutiles..."
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type f \( -name "*.backup" -o -name "*.backup" \) -exec rm -f {} +
	@find . -type f \( -name "*.pyc" -o -name "*.pyo" \) -exec rm -f {} +

# ============================================================
# 📦 Installation & initialisation projet
# ============================================================

install: ## Installer les dépendances Python via Poetry
	@poetry lock
	@poetry install

init: ## Initialiser le projet (permissions scripts + install + démarrage dev)
	@chmod +x ./script/uninstall.sh
	@chmod +x ./script/install.sh
	@chmod +x ./script/cmd.sh
	@chmod +x ./script/repaire_ng.sh
	@chmod +x ./script/restart_poetry.sh
	$(MAKE) install
	$(MAKE) run-dev

# ============================================================
# 🚀 Lancement de l'application
# ============================================================

run-dev: ## Lancer en mode développement (reload automatique)
	@echo "🚀 Lancement en mode développement..."
	@poetry run python -m uvicorn main:app --reload --host 0.0.0.0 --port 8082

run-st: ## Lancer en mode production / statique (sans reload)
	@echo "🚀 Lancement en mode statique..."
	@poetry run python -m uvicorn main:app --host 0.0.0.0 --port 8081

pip-Noa: ## Installer pip sans cache (debug)
	@echo "📦 Installation pip sans cache..."
	@poetry run pip --no-cache-dir
	@poetry run python -m uvicorn main:app --reload --host 0.0.0.0 --port 8081

# ============================================================
# 📦 Déploiement & gestion serveur
# ============================================================

deploy: ## Déployer l'application (script externe)
	@./script/install.sh

remove-app: ## Supprimer l'application (script externe)
	@./script/uninstall.sh

repaire-ng: ## Réparer la configuration Nginx
	@./script/repaire_ng.sh

start: ## Démarrer le serveur (script externe)
	@./script/cmd.sh start

stop: ## Arrêter le serveur (script externe)
	@./script/cmd.sh stop

restart: ## Redémarrer le serveur (script externe)
	@./script/cmd.sh restart

status: ## Vérifier le statut du serveur (script externe)
	@./script/cmd.sh status

poetry-ri: ## Redémarrer Poetry (script externe)
	@./script/restart_poetry.sh

pre-commit: ## Lancer les scripts de pré-commit
	@./script/check_banned_words.py
	@./script/run_pre_commit.py

# ============================================================
# 📌 Cibles "PHONY" - éviter conflits avec fichiers du même nom
# ============================================================

.PHONY: help add-plugin link unlink clean install init run-dev run-st pip-Noa deploy remove-app repaire-ng start stop restart status poetry-ri pre-commit logs logs-live logs-debug logs-info logs-warning logs-error logs-critical logs-auth logs-db logs-api logs-plugins logs-tasks logs-email logs-clean logs-stats logs-search logs-today logs-last-hour logs-test logs-demo

# ============================================================
# 📊 Commandes de gestion des logs
# ============================================================

logs: ## Afficher tous les logs du fichier dev.log
	@echo "📋 Affichage de tous les logs..."
	@if [ -f "dev.log" ]; then \
		tail -100 dev.log; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-live: ## Afficher les logs en temps réel (tail -f)
	@echo "🔴 Logs en temps réel (Ctrl+C pour arrêter)..."
	@if [ -f "dev.log" ]; then \
		tail -f dev.log; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-debug: ## Filtrer et afficher seulement les logs DEBUG
	@echo "🔍 Logs DEBUG..."
	@if [ -f "dev.log" ]; then \
		grep "DEBUG" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-info: ## Filtrer et afficher seulement les logs INFO
	@echo "ℹ️  Logs INFO..."
	@if [ -f "dev.log" ]; then \
		grep "INFO" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-warning: ## Filtrer et afficher seulement les logs WARNING
	@echo "⚠️  Logs WARNING..."
	@if [ -f "dev.log" ]; then \
		grep "WARNING" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-error: ## Filtrer et afficher seulement les logs ERROR
	@echo "❌ Logs ERROR..."
	@if [ -f "dev.log" ]; then \
		grep "ERROR" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-critical: ## Filtrer et afficher seulement les logs CRITICAL
	@echo "🚨 Logs CRITICAL..."
	@if [ -f "dev.log" ]; then \
		grep "CRITICAL" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-auth: ## Filtrer les logs liés à l'authentification
	@echo "🔐 Logs d'authentification..."
	@if [ -f "dev.log" ]; then \
		grep -E "(auth|login|token|otp|session)" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-db: ## Filtrer les logs liés à la base de données
	@echo "🗃️  Logs de base de données..."
	@if [ -f "dev.log" ]; then \
		grep -E "(database|session|CRUD|commit|rollback)" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-api: ## Filtrer les logs liés aux routes/API
	@echo "🛣️  Logs des routes API..."
	@if [ -f "dev.log" ]; then \
		grep -E "(routes|router|API|endpoint)" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-plugins: ## Filtrer les logs liés aux plugins
	@echo "🔌 Logs des plugins..."
	@if [ -f "dev.log" ]; then \
		grep -E "(plugin|Plugin)" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-tasks: ## Filtrer les logs liés aux tâches
	@echo "📋 Logs des tâches..."
	@if [ -f "dev.log" ]; then \
		grep -E "(task|TaskManager|thread|service)" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-email: ## Filtrer les logs liés aux emails
	@echo "📧 Logs des emails..."
	@if [ -f "dev.log" ]; then \
		grep -E "(email|smtp|mail)" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-clean: ## Nettoyer/vider le fichier de logs
	@echo "🧹 Nettoyage du fichier de logs..."
	@if [ -f "dev.log" ]; then \
		echo "📁 Sauvegarde de dev.log vers dev.log.old"; \
		cp dev.log dev.log.old; \
		echo "" > dev.log; \
		echo "✅ Fichier dev.log nettoyé (sauvegarde dans dev.log.old)"; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-stats: ## Afficher les statistiques des logs
	@echo "📊 Statistiques des logs..."
	@if [ -f "dev.log" ]; then \
		echo "📋 Nombre total de lignes: $$(wc -l < dev.log)"; \
		echo "🔍 DEBUG: $$(grep -c 'DEBUG' dev.log || echo 0)"; \
		echo "ℹ️  INFO: $$(grep -c 'INFO' dev.log || echo 0)"; \
		echo "⚠️  WARNING: $$(grep -c 'WARNING' dev.log || echo 0)"; \
		echo "❌ ERROR: $$(grep -c 'ERROR' dev.log || echo 0)"; \
		echo "🚨 CRITICAL: $$(grep -c 'CRITICAL' dev.log || echo 0)"; \
		echo ""; \
		echo "🕐 Dernière entrée: $$(tail -1 dev.log | cut -d' ' -f1-2 || echo 'N/A')"; \
		echo "📏 Taille du fichier: $$(du -h dev.log | cut -f1)"; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-search: ## Rechercher dans les logs (usage: make logs-search TERM="texte_recherche")
	@if [ -z "$(TERM)" ]; then \
		echo "❌ Erreur : veuillez fournir un terme de recherche"; \
		echo "   Exemple : make logs-search TERM='utilisateur'"; \
		exit 1; \
	fi
	@echo "🔍 Recherche de '$(TERM)' dans les logs..."
	@if [ -f "dev.log" ]; then \
		grep -i "$(TERM)" dev.log | tail -30; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-today: ## Afficher les logs d'aujourd'hui
	@echo "📅 Logs d'aujourd'hui..."
	@if [ -f "dev.log" ]; then \
		grep "$$(date '+%Y-%m-%d')" dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-last-hour: ## Afficher les logs de la dernière heure
	@echo "🕐 Logs de la dernière heure..."
	@if [ -f "dev.log" ]; then \
		awk -v hour="$$(date -d '1 hour ago' '+%Y-%m-%d %H')" '$$0 >= hour' dev.log | tail -50; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi


logs-test: ## Générer des logs de test pour démonstration
	@echo "🧪 Génération de logs de test..."
	@python3 generate_test_logs.py

logs-demo: ## Démonstration complète du système de logs
	@echo "🎭 Démonstration complète du système de logging..."
	@echo ""
	@$(MAKE) logs-test
	@echo ""
	@echo "📊 Statistiques:"
	@$(MAKE) logs-stats
	@echo ""
	@echo "❌ Erreurs détectées:"
	@$(MAKE) logs-error
	@echo ""
	@echo "⚠️  Avertissements:"
	@$(MAKE) logs-warning
	@echo ""
	@echo "🔐 Logs d'authentification:"
	@$(MAKE) logs-auth

# ============================================================
# 🔄 Commandes combinées pour workflows avancés
# ============================================================

logs-errors-and-warnings: ## Afficher les erreurs ET les warnings ensemble
	@echo "🚨 Analyse complète : ERREURS + AVERTISSEMENTS"
	@echo "=================================================="
	@echo ""
	@echo "❌ ERREURS RÉCENTES:"
	@echo "-------------------"
	@if [ -f "dev.log" ]; then \
		grep "ERROR" dev.log | tail -20; \
	fi
	@echo ""
	@echo "⚠️  AVERTISSEMENTS RÉCENTS:"
	@echo "-------------------------"
	@if [ -f "dev.log" ]; then \
		grep "WARNING" dev.log | tail -20; \
	fi
	@echo ""
	@echo "📊 RÉSUMÉ:"
	@if [ -f "dev.log" ]; then \
		echo "❌ Total erreurs: $$(grep -c 'ERROR' dev.log || echo 0)"; \
		echo "⚠️  Total warnings: $$(grep -c 'WARNING' dev.log || echo 0)"; \
	fi

logs-security-audit: ## Audit de sécurité complet (auth + erreurs + warnings)
	@echo "🛡️  AUDIT DE SÉCURITÉ COMPLET"
	@echo "=============================="
	@echo ""
	@echo "🔐 AUTHENTIFICATION:"
	@echo "-------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(auth|login|token|otp|session)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "❌ ERREURS DE SÉCURITÉ:"
	@echo "----------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ERROR.*auth|ERROR.*login|ERROR.*token)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "⚠️  TENTATIVES SUSPECTES:"
	@echo "------------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(WARNING.*auth|WARNING.*login|Échec|échec|Invalid|invalid)" dev.log | tail -10; \
	fi

logs-performance-check: ## Vérification des performances (warnings + tasks + timing)
	@echo "⚡ VÉRIFICATION DES PERFORMANCES"
	@echo "==============================="
	@echo ""
	@echo "⚠️  ALERTES DE PERFORMANCE:"
	@echo "--------------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(lente|slow|timeout|performance|CPU|mémoire|memory)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "📋 ÉTAT DES TÂCHES:"
	@echo "------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(task|TaskManager|thread|service)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "⏱️  TEMPS D'EXÉCUTION:"
	@echo "---------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(exécuté en|ms|secondes)" dev.log | tail -10; \
	fi

logs-startup-analysis: ## Analyse complète du démarrage de l'application
	@echo "🚀 ANALYSE DU DÉMARRAGE"
	@echo "======================"
	@echo ""
	@echo "🔧 INITIALISATION:"
	@echo "-----------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Démarrage|initialisé|chargé|startup)" dev.log | tail -20; \
	fi
	@echo ""
	@echo "❌ ERREURS AU DÉMARRAGE:"
	@echo "-----------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ERROR.*init|ERROR.*startup|ERROR.*Démarrage)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "🔌 CHARGEMENT DES PLUGINS:"
	@echo "-------------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Plugin.*chargé|plugin.*initialisé)" dev.log | tail -10; \
	fi

logs-user-activity: ## Activité des utilisateurs (connexions, actions, erreurs)
	@echo "👥 ACTIVITÉ DES UTILISATEURS"
	@echo "==========================="
	@echo ""
	@echo "🔐 CONNEXIONS:"
	@echo "-------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Tentative de connexion|Connexion réussie|login)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "🚪 DÉCONNEXIONS:"
	@echo "---------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Déconnexion|logout)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "📝 INSCRIPTIONS:"
	@echo "---------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Inscription|register)" dev.log | tail -10; \
	fi

logs-api-monitoring: ## Monitoring des API (routes + erreurs + performance)
	@echo "🛣️  MONITORING DES API"
	@echo "====================="
	@echo ""
	@echo "📊 ACCÈS AUX ROUTES:"
	@echo "-------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(GET|POST|DELETE|PUT)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "❌ ERREURS D'API:"
	@echo "----------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ERROR.*route|ERROR.*API|ERROR.*endpoint)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "⏱️  PERFORMANCE DES ROUTES:"
	@echo "--------------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ms|temps.*exécution)" dev.log | tail -10; \
	fi

logs-database-health: ## Santé de la base de données (connexions + erreurs + transactions)
	@echo "🗃️  SANTÉ DE LA BASE DE DONNÉES"
	@echo "==============================="
	@echo ""
	@echo "🔗 CONNEXIONS:"
	@echo "-------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(database.*établie|Session.*créée|DB)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "💾 TRANSACTIONS:"
	@echo "---------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(commit|rollback|transaction)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "❌ ERREURS DE BASE:"
	@echo "------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ERROR.*database|ERROR.*DB|ERROR.*SQL)" dev.log | tail -10; \
	fi

logs-plugins-status: ## État complet des plugins (chargement + erreurs + activité)
	@echo "🔌 ÉTAT COMPLET DES PLUGINS"
	@echo "=========================="
	@echo ""
	@echo "🔧 CHARGEMENT DES PLUGINS:"
	@echo "-------------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Plugin.*chargé|plugin.*initialisé|Manager.*plugin)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "⚡ ACTIVITÉ DES PLUGINS:"
	@echo "----------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Plugin|plugin)" dev.log | grep -E "(ajouté|supprimé|créé)" | tail -10; \
	fi
	@echo ""
	@echo "❌ ERREURS DE PLUGINS:"
	@echo "---------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ERROR.*plugin|ERROR.*Plugin)" dev.log | tail -10; \
	fi

logs-email-monitoring: ## Monitoring complet des emails (envois + erreurs + SMTP)
	@echo "📧 MONITORING DES EMAILS"
	@echo "======================="
	@echo ""
	@echo "📮 ENVOIS D'EMAILS:"
	@echo "------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(Envoi d'email|email.*envoyé|email.*succès)" dev.log | tail -15; \
	fi
	@echo ""
	@echo "🔧 CONNEXIONS SMTP:"
	@echo "------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(SMTP|smtp)" dev.log | tail -10; \
	fi
	@echo ""
	@echo "❌ ERREURS D'EMAIL:"
	@echo "------------------"
	@if [ -f "dev.log" ]; then \
		grep -E "(ERROR.*email|ERROR.*SMTP|ERROR.*mail)" dev.log | tail -10; \
	fi

logs-full-report: ## Rapport complet (stats + erreurs + warnings + sécurité)
	@echo "📋 RAPPORT COMPLET DU SYSTÈME"
	@echo "============================="
	@echo ""
	@$(MAKE) logs-stats
	@echo ""
	@echo "🚨 PROBLÈMES DÉTECTÉS:"
	@echo "====================="
	@$(MAKE) logs-errors-and-warnings
	@echo ""
	@echo "🛡️  AUDIT SÉCURITÉ:"
	@echo "=================="
	@$(MAKE) logs-security-audit

logs-troubleshoot: ## Guide de dépannage automatique
	@echo "🔧 GUIDE DE DÉPANNAGE AUTOMATIQUE"
	@echo "================================="
	@echo ""
	@echo "📊 1. STATISTIQUES GÉNÉRALES:"
	@$(MAKE) logs-stats
	@echo ""
	@echo "❌ 2. ERREURS RÉCENTES (5 dernières):"
	@if [ -f "dev.log" ]; then \
		grep "ERROR" dev.log | tail -5; \
	fi
	@echo ""
	@echo "⚠️  3. WARNINGS RÉCENTS (5 derniers):"
	@if [ -f "dev.log" ]; then \
		grep "WARNING" dev.log | tail -5; \
	fi
	@echo ""
	@echo "🔍 4. MODULES LES PLUS ACTIFS:"
	@if [ -f "dev.log" ]; then \
		cut -d'-' -f3 dev.log | sort | uniq -c | sort -nr | head -5; \
	fi
	@echo ""
	@echo "💡 SUGGESTIONS:"
	@echo "- Si beaucoup d'erreurs → make logs-error"
	@echo "- Si problème de connexion → make logs-auth"
	@echo "- Si lenteur → make logs-performance-check"
	@echo "- Si problème plugin → make logs-plugins-status"

logs-debug-session: ## Session de debug interactive
	@echo "🔍 SESSION DE DEBUG INTERACTIVE"
	@echo "==============================="
	@echo ""
	@echo "📋 Choisissez votre analyse:"
	@echo "1. Erreurs récentes       → make logs-error"
	@echo "2. Problèmes d'auth       → make logs-security-audit"
	@echo "3. Performance            → make logs-performance-check"
	@echo "4. État des plugins       → make logs-plugins-status"
	@echo "5. Activité utilisateurs  → make logs-user-activity"
	@echo "6. Santé de la DB         → make logs-database-health"
	@echo "7. Rapport complet        → make logs-full-report"
	@echo "8. Logs en temps réel     → make logs-live"
	@echo ""
	@echo "💡 Exemple: make logs-security-audit"

logs-watch-errors: ## Surveillance continue des erreurs (toutes les 10 secondes)
	@echo "👀 SURVEILLANCE CONTINUE DES ERREURS"
	@echo "====================================="
	@echo "🔄 Mise à jour toutes les 10 secondes (Ctrl+C pour arrêter)"
	@echo ""
	@while true; do \
		clear; \
		echo "🕐 $$(date '+%H:%M:%S') - Surveillance des erreurs"; \
		echo "=========================================="; \
		if [ -f "dev.log" ]; then \
			echo "❌ ERREURS ($$(grep -c 'ERROR' dev.log || echo 0)):"; \
			grep "ERROR" dev.log | tail -5 || echo "Aucune erreur"; \
			echo ""; \
			echo "⚠️  WARNINGS ($$(grep -c 'WARNING' dev.log || echo 0)):"; \
			grep "WARNING" dev.log | tail -3 || echo "Aucun warning"; \
		else \
			echo "⚠️  Fichier dev.log introuvable"; \
		fi; \
		sleep 10; \
	done

logs-smart-filter: ## Filtre intelligent basé sur le contexte
	@echo "🧠 FILTRE INTELLIGENT"
	@echo "===================="
	@echo ""
	@echo "🔍 Analyse automatique du contexte..."
	@if [ -f "dev.log" ]; then \
		ERROR_COUNT=$$(grep -c 'ERROR' dev.log || echo 0); \
		WARNING_COUNT=$$(grep -c 'WARNING' dev.log || echo 0); \
		CRITICAL_COUNT=$$(grep -c 'CRITICAL' dev.log || echo 0); \
		echo "📊 Erreurs: $$ERROR_COUNT | Warnings: $$WARNING_COUNT | Critiques: $$CRITICAL_COUNT"; \
		echo ""; \
		if [ $$CRITICAL_COUNT -gt 0 ]; then \
			echo "🚨 ALERTES CRITIQUES DÉTECTÉES!"; \
			echo "==============================="; \
			grep "CRITICAL" dev.log | tail -10; \
		elif [ $$ERROR_COUNT -gt 10 ]; then \
			echo "❌ BEAUCOUP D'ERREURS DÉTECTÉES!"; \
			echo "==============================="; \
			grep "ERROR" dev.log | tail -10; \
		elif [ $$WARNING_COUNT -gt 20 ]; then \
			echo "⚠️  NOMBREUX AVERTISSEMENTS!"; \
			echo "==========================="; \
			grep "WARNING" dev.log | tail -10; \
		else \
			echo "✅ SYSTÈME STABLE - Logs récents:"; \
			echo "================================="; \
			tail -20 dev.log; \
		fi; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-timeline: ## Timeline des événements importants
	@echo "📅 TIMELINE DES ÉVÉNEMENTS"
	@echo "=========================="
	@echo ""
	@if [ -f "dev.log" ]; then \
		echo "🕐 DERNIERS ÉVÉNEMENTS CRITIQUES:"; \
		echo "---------------------------------"; \
		grep -E "(CRITICAL|ERROR|Démarrage|Arrêt|startup|shutdown)" dev.log | tail -15; \
		echo ""; \
		echo "🔐 DERNIÈRES CONNEXIONS:"; \
		echo "------------------------"; \
		grep -E "(connexion|login|logout)" dev.log | tail -10; \
		echo ""; \
		echo "🔌 DERNIÈRES ACTIVITÉS PLUGINS:"; \
		echo "-------------------------------"; \
		grep -E "(Plugin.*ajouté|plugin.*chargé)" dev.log | tail -5; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-health-check: ## Check-up santé complet du système
	@echo "🏥 CHECK-UP SANTÉ DU SYSTÈME"
	@echo "==========================="
	@echo ""
	@if [ -f "dev.log" ]; then \
		TOTAL_LINES=$$(wc -l < dev.log); \
		ERROR_COUNT=$$(grep -c 'ERROR' dev.log || echo 0); \
		WARNING_COUNT=$$(grep -c 'WARNING' dev.log || echo 0); \
		CRITICAL_COUNT=$$(grep -c 'CRITICAL' dev.log || echo 0); \
		INFO_COUNT=$$(grep -c 'INFO' dev.log || echo 0); \
		\
		echo "📊 MÉTRIQUES GLOBALES:"; \
		echo "---------------------"; \
		echo "📋 Total logs: $$TOTAL_LINES"; \
		echo "ℹ️  Info: $$INFO_COUNT"; \
		echo "⚠️  Warnings: $$WARNING_COUNT"; \
		echo "❌ Erreurs: $$ERROR_COUNT"; \
		echo "🚨 Critiques: $$CRITICAL_COUNT"; \
		echo ""; \
		\
		if [ $$CRITICAL_COUNT -gt 0 ]; then \
			echo "🚨 ÉTAT: CRITIQUE"; \
		elif [ $$ERROR_COUNT -gt 5 ]; then \
			echo "❌ ÉTAT: PROBLÉMATIQUE"; \
		elif [ $$WARNING_COUNT -gt 10 ]; then \
			echo "⚠️  ÉTAT: ATTENTION REQUISE"; \
		else \
			echo "✅ ÉTAT: SAIN"; \
		fi; \
		echo ""; \
		\
		echo "🔧 MODULES LES PLUS ACTIFS:"; \
		echo "---------------------------"; \
		cut -d'-' -f3 dev.log | sort | uniq -c | sort -nr | head -5; \
		echo ""; \
		\
		echo "🕐 DERNIÈRE ACTIVITÉ:"; \
		echo "--------------------"; \
		tail -3 dev.log; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-comparison: ## Compare les logs avant/après (dev.log vs dev.log.old)
	@echo "🔄 COMPARAISON DES LOGS"
	@echo "======================"
	@echo ""
	@if [ -f "dev.log.old" ] && [ -f "dev.log" ]; then \
		OLD_LINES=$$(wc -l < dev.log.old); \
		NEW_LINES=$$(wc -l < dev.log); \
		DIFF_LINES=$$((NEW_LINES - OLD_LINES)); \
		echo "📊 Anciennes logs: $$OLD_LINES lignes"; \
		echo "📊 Nouvelles logs: $$NEW_LINES lignes"; \
		echo "📈 Différence: $$DIFF_LINES nouvelles lignes"; \
		echo ""; \
		if [ $$DIFF_LINES -gt 0 ]; then \
			echo "🆕 NOUVELLES ENTRÉES:"; \
			echo "--------------------"; \
			tail -n $$DIFF_LINES dev.log; \
		else \
			echo "ℹ️  Aucune nouvelle entrée depuis la dernière sauvegarde"; \
		fi; \
	else \
		echo "⚠️  Fichiers de comparaison non disponibles"; \
		echo "💡 Utilisez 'make logs-clean' pour créer dev.log.old"; \
	fi

logs-alerts: ## Alertes automatiques basées sur les patterns
	@echo "🚨 SYSTÈME D'ALERTES AUTOMATIQUES"
	@echo "================================="
	@echo ""
	@if [ -f "dev.log" ]; then \
		echo "🔍 Analyse des patterns dangereux..."; \
		echo ""; \
		\
		FAILED_LOGINS=$$(grep -c "Échec de connexion\|Invalid credentials" dev.log || echo 0); \
		if [ $$FAILED_LOGINS -gt 3 ]; then \
			echo "🚨 ALERTE: $$FAILED_LOGINS tentatives de connexion échouées!"; \
		fi; \
		\
		SMTP_ERRORS=$$(grep -c "ERROR.*SMTP\|ERROR.*email" dev.log || echo 0); \
		if [ $$SMTP_ERRORS -gt 0 ]; then \
			echo "📧 ALERTE: $$SMTP_ERRORS erreurs d'email détectées!"; \
		fi; \
		\
		DB_ERRORS=$$(grep -c "ERROR.*database\|ERROR.*DB" dev.log || echo 0); \
		if [ $$DB_ERRORS -gt 0 ]; then \
			echo "🗃️  ALERTE: $$DB_ERRORS erreurs de base de données!"; \
		fi; \
		\
		RECENT_ERRORS=$$(grep "ERROR" dev.log | tail -10 | wc -l); \
		if [ $$RECENT_ERRORS -gt 5 ]; then \
			echo "⚡ ALERTE: Pic d'erreurs récent ($$RECENT_ERRORS erreurs récentes)!"; \
		fi; \
		\
		PLUGIN_ERRORS=$$(grep -c "ERROR.*plugin\|ERROR.*Plugin" dev.log || echo 0); \
		if [ $$PLUGIN_ERRORS -gt 0 ]; then \
			echo "🔌 ALERTE: $$PLUGIN_ERRORS erreurs de plugins!"; \
		fi; \
		\
		if [ $$FAILED_LOGINS -eq 0 ] && [ $$SMTP_ERRORS -eq 0 ] && [ $$DB_ERRORS -eq 0 ] && [ $$RECENT_ERRORS -lt 5 ] && [ $$PLUGIN_ERRORS -eq 0 ]; then \
			echo "✅ Aucune alerte détectée - Système stable"; \
		fi; \
	else \
		echo "⚠️  Fichier dev.log introuvable"; \
	fi

logs-dashboard: ## Dashboard temps réel avec rafraîchissement automatique
	@echo "📊 DASHBOARD TEMPS RÉEL"
	@echo "======================"
	@echo "🔄 Rafraîchissement toutes les 5 secondes (Ctrl+C pour arrêter)"
	@echo ""
	@while true; do \
		clear; \
		echo "🕐 $$(date '+%Y-%m-%d %H:%M:%S') - Dashboard Logs"; \
		echo "================================================"; \
		if [ -f "dev.log" ]; then \
			echo "📊 STATISTIQUES:"; \
			echo "Total: $$(wc -l < dev.log) | INFO: $$(grep -c 'INFO' dev.log || echo 0) | WARN: $$(grep -c 'WARNING' dev.log || echo 0) | ERROR: $$(grep -c 'ERROR' dev.log || echo 0)"; \
			echo ""; \
			echo "🕐 DERNIERS ÉVÉNEMENTS:"; \
			echo "----------------------"; \
			tail -8 dev.log; \
			echo ""; \
			echo "🚨 DERNIÈRES ERREURS:"; \
			echo "--------------------"; \
			grep "ERROR" dev.log | tail -3 || echo "Aucune erreur récente"; \
		else \
			echo "⚠️  Fichier dev.log introuvable"; \
		fi; \
		sleep 5; \
	done


# ============================================================
# 🏗️  Build & Correction automatique du code
# ============================================================

build: ## Build complet du projet (clean + install + lint-fix + format)
	@echo "🏗️  CONSTRUCTION DU PROJET"
	@echo "==========================="
	@echo ""
	@echo "🧹 1. Nettoyage des fichiers compilés..."
	@$(MAKE) clean
	@echo ""
	@echo "📦 2. Installation des dépendances..."
	@$(MAKE) install
	@echo ""
	@echo "🔧 3. Correction automatique du code..."
	@$(MAKE) lint-fix
	@echo ""
	@echo "✅ Build terminé avec succès!"

build-prod: ## Build pour production (build + tests + validation)
	@echo "🚀 BUILD PRODUCTION"
	@echo "=================="
	@echo ""
	@$(MAKE) build
	@echo ""
	@echo "🧪 5. Exécution des tests..."
	@$(MAKE) test
	@echo ""
	@echo "🔒 6. Validation sécurité..."
	@$(MAKE) security-check
	@echo ""
	@echo "🎉 Build production prêt!"

build-fast: ## Build rapide (clean + install uniquement)
	@echo "⚡ BUILD RAPIDE"
	@echo "=============="
	@$(MAKE) clean
	@$(MAKE) install
	@echo "✅ Build rapide terminé!"

lint-fix: ## Correction automatique des erreurs de linting (SAFE - préserve imports)
	@echo "🔧 Correction automatique du code (mode SAFE)..."
	@echo "📋 1. Correction autopep8 (lignes longues, espaces)..."
	@poetry run autopep8 --in-place --recursive --exclude=alembic,static,__pycache__ .
	@echo "📋 2. Tri des imports avec isort..."
	@poetry run isort . --skip=alembic --skip=static --skip=__pycache__
	@echo "📋 3. Formatage avec black..."
	@poetry run black . --exclude="(alembic|static|__pycache__)"
	@echo "📋 4. Suppression CONSERVATIVE des variables inutiles (préserve imports)..."
	@poetry run autoflake --in-place --recursive --remove-unused-variables --ignore-init-module-imports --exclude=alembic,static,__pycache__ .
	@echo "✅ Correction automatique terminée (imports préservés)!"

auto-fix: ## Alias pour lint-fix (correction automatique sécurisée)
	@$(MAKE) lint-fix

lint-preview: ## Prévisualiser les corrections sans les appliquer
	@echo "👀 Prévisualisation des corrections autopep8:"
	@poetry run autopep8 --diff --recursive --exclude=alembic,static,__pycache__ . | head -50
	@echo ""
	@echo "👀 Prévisualisation du formatage black:"
	@poetry run black --diff . --exclude="(alembic|static|__pycache__)" | head -30

lint-safe: ## Linting avec configuration adaptée à FastHTML
	@echo "🔍 Vérification du code (compatible FastHTML)..."
	@poetry run flake8 .




test: ## Exécution des tests
	@echo "🧪 Exécution des tests..."
	@if [ -d "tests" ]; then \
		poetry run pytest tests/ -v; \
	else \
		echo "⚠️  Dossier tests/ non trouvé"; \
		echo "💡 Créez des tests pour améliorer la qualité"; \
	fi

security-check: ## Vérification de sécurité basique
	@echo "🔒 Vérification de sécurité..."
	@echo "✅ Vérification .env (ne pas commiter)"
	@if git ls-files | grep -q "\.env$$"; then \
		echo "❌ ATTENTION: .env est tracké par git!"; \
	else \
		echo "✅ .env correctement ignoré"; \
	fi
	@echo "✅ Vérification des mots de passe hardcodés..."
	@if grep -r "password\s*=\s*[\"'][^\"']*[\"']" . --exclude-dir=.git --exclude-dir=static --exclude-dir=__pycache__ 2>/dev/null; then \
		echo "❌ ATTENTION: Mots de passe potentiels trouvés!"; \
	else \
		echo "✅ Aucun mot de passe hardcodé détecté"; \
	fi

validate: ## Validation complète du projet
	@echo "✅ VALIDATION DU PROJET"
	@echo "====================="
	@echo ""
	@echo "🔍 1. Syntaxe Python..."
	@poetry run python -m py_compile main.py
	@echo ""
	@echo "📦 2. Dépendances..."
	@poetry check
	@echo ""
	@echo "🔧 3. Configuration..."
	@if [ -f ".env" ]; then \
		echo "✅ Fichier .env présent"; \
	else \
		echo "⚠️  Fichier .env manquant"; \
	fi
	@echo ""
	@echo "✅ Validation terminée!"
