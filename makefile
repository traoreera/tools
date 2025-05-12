# === CONFIGURATION ===
PROJECT_NAME=my_fastapi_project
PYTHON=python3
VENV=.venv
ACTIVATE=. $(VENV)/bin/activate

# === INSTALLATION ===

install:
	@echo "📁 Création de l’arborescence du projet..."
	mkdir -p $(PROJECT_NAME)/app/api/routes
	mkdir -p $(PROJECT_NAME)/app/db/crud
	mkdir -p $(PROJECT_NAME)/app/db/models
	mkdir -p $(PROJECT_NAME)/app/db/schemas
	touch $(PROJECT_NAME)/.env
	touch $(PROJECT_NAME)/requirements.txt
	touch $(PROJECT_NAME)/app/__init__.py
	touch $(PROJECT_NAME)/app/api/__init__.py
	touch $(PROJECT_NAME)/app/api/routes/__init__.py
	touch $(PROJECT_NAME)/app/db/__init__.py
	touch $(PROJECT_NAME)/app/db/crud/__init__.py
	touch $(PROJECT_NAME)/app/db/models/__init__.py
	touch $(PROJECT_NAME)/app/db/schemas/__init__.py
	@echo "from fastapi import FastAPI\nfrom app.api.routes import auth\nfrom app.db.database import Base, engine\n\napp = FastAPI()\n\nBase.metadata.create_all(bind=engine)\n\napp.include_router(auth.router)" > $(PROJECT_NAME)/app/main.py
	@echo "from sqlalchemy import create_engine\nfrom sqlalchemy.ext.declarative import declarative_base\nfrom sqlalchemy.orm import sessionmaker\nimport os\nfrom dotenv import load_dotenv\n\nload_dotenv()\nDATABASE_URL = os.getenv(\"DATABASE_URL\")\nengine = create_engine(DATABASE_URL, connect_args={\"check_same_thread\": False} if \"sqlite\" in DATABASE_URL else {})\nSessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)\nBase = declarative_base()\n\ndef get_db():\n    db = SessionLocal()\n    try:\n        yield db\n    finally:\n        db.close()" > $(PROJECT_NAME)/app/db/database.py
	@echo "from fastapi import APIRouter\n\nrouter = APIRouter()\n\n@router.get('/')\ndef read_root():\n    return {\"message\": \"Hello from auth\"}" > $(PROJECT_NAME)/app/api/routes/auth.py
	@echo "fastapi\nuvicorn[standard]\nsqlalchemy\npsycopg2-binary\npython-dotenv\nalembic\npasslib[bcrypt]\ngunicorn\npytest\nflake8" > $(PROJECT_NAME)/requirements.txt
	@echo "DATABASE_URL=sqlite:///./app.db" > $(PROJECT_NAME)/.env

	@echo "📦 Création de l'environnement virtuel et installation des dépendances..."
	$(PYTHON) -m venv $(VENV)
	$(ACTIVATE) && pip install --upgrade pip
	$(ACTIVATE) && pip install -r $(PROJECT_NAME)/requirements.txt

	@echo "✅ Installation terminée."

# === DÉVELOPPEMENT ===

run-dev:
	@echo "🚀 Lancement en mode développement..."
	$(ACTIVATE) && uvicorn $(PROJECT_NAME).app.main:app --reload

run-deploy:
	@echo "🚀 Lancement en mode production avec Gunicorn..."
	$(ACTIVATE) && gunicorn -k uvicorn.workers.UvicornWorker $(PROJECT_NAME).app.main:app --bind 0.0.0.0:8000

# === ALEMBIC ===

init-alembic:
	@echo "🏗️ Initialisation d’Alembic..."
	$(ACTIVATE) && alembic init alembic

db-init:
	@echo "🗃️ Initialisation de la base de données avec Alembic..."
	$(ACTIVATE) && alembic upgrade head

db-migrate:
ifndef msg
	$(error ❌ Veuillez fournir un message : make db-migrate msg="votre message")
endif
	@echo "📜 Création d'une migration Alembic..."
	$(ACTIVATE) && alembic revision --autogenerate -m "$(msg)"

# === BASE DE DONNÉES ===

refresh-db:
	@echo "⚠️ Suppression et recréation de la base de données..."
	rm -f $(PROJECT_NAME)/app.db
	$(ACTIVATE) && alembic upgrade head

# === TESTS & QUALITÉ ===

test:
	@echo "🧪 Lancement des tests..."
	$(ACTIVATE) && pytest tests/

lint:
	@echo "🔍 Vérification du code avec flake8..."
	$(ACTIVATE) && flake8 $(PROJECT_NAME)/app

freeze:
	@echo "📄 Mise à jour du fichier requirements.txt"
	$(ACTIVATE) && pip freeze > $(PROJECT_NAME)/requirements.txt

# === NETTOYAGE ===

clean:
	@echo "🧹 Nettoyage..."
	rm -rf $(VENV) __pycache__ */__pycache__ .pytest_cache .mypy_cache *.pyc *.pyo *.pyd

# === AIDE ===

help:
	@echo "Commandes disponibles :"
	@echo "  make install              - Crée les dossiers, fichiers, venv, et installe les dépendances"
	@echo "  make run-dev              - Lance FastAPI avec rechargement automatique"
	@echo "  make run-deploy           - Lance avec Gunicorn pour production"
	@echo "  make init-alembic         - Initialise Alembic (1 fois)"
	@echo "  make db-init              - Applique les migrations Alembic"
	@echo "  make db-migrate msg=\"...\" - Crée une migration Alembic"
	@echo "  make refresh-db           - Supprime et recrée la base de données"
	@echo "  make test                 - Lance les tests avec pytest"
	@echo "  make lint                 - Vérifie le style de code (flake8)"
	@echo "  make freeze               - Gèle les dépendances dans requirements.txt"
	@echo "  make clean                - Supprime les fichiers temporaires"
