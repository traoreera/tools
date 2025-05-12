# === CONFIGURATION ===
PROJECT_NAME=.
PYTHON=python3
VENV=.venv
ACTIVATE=. $(VENV)/bin/activate

# === INSTALLATION ===
install:
	@echo "📁 Création de l’arborescence complète du projet..."
	mkdir -p $(PROJECT_NAME)/app/api/routes
	mkdir -p $(PROJECT_NAME)/app/core
	mkdir -p $(PROJECT_NAME)/app/db/models
	mkdir -p $(PROJECT_NAME)/app/db/schemas
	mkdir -p $(PROJECT_NAME)/app/db/crud
	mkdir -p $(PROJECT_NAME)/app/services
	mkdir -p $(PROJECT_NAME)/app/tasks
	mkdir -p $(PROJECT_NAME)/app/utils
	mkdir -p $(PROJECT_NAME)/app/middleware
	mkdir -p $(PROJECT_NAME)/app/db
	mkdir -p $(PROJECT_NAME)/tests
	mkdir -p $(PROJECT_NAME)/alembic/versions
	touch $(PROJECT_NAME)/app/__init__.py
	touch $(PROJECT_NAME)/app/main.py
	touch $(PROJECT_NAME)/app/api/__init__.py
	touch $(PROJECT_NAME)/app/api/deps.py
	touch $(PROJECT_NAME)/app/api/routes/__init__.py
	touch $(PROJECT_NAME)/app/api/routes/auth.py
	touch $(PROJECT_NAME)/app/api/routes/users.py
	touch $(PROJECT_NAME)/app/api/routes/items.py
	touch $(PROJECT_NAME)/app/core/__init__.py
	touch $(PROJECT_NAME)/app/core/config.py
	touch $(PROJECT_NAME)/app/core/security.py
	touch $(PROJECT_NAME)/app/core/logging.py
	touch $(PROJECT_NAME)/app/db/__init__.py
	touch $(PROJECT_NAME)/app/db/base.py
	touch $(PROJECT_NAME)/app/db/session.py
	touch $(PROJECT_NAME)/app/db/models/__init__.py
	touch $(PROJECT_NAME)/app/db/models/user.py
	touch $(PROJECT_NAME)/app/db/models/item.py
	touch $(PROJECT_NAME)/app/db/schemas/__init__.py
	touch $(PROJECT_NAME)/app/db/schemas/user.py
	touch $(PROJECT_NAME)/app/db/schemas/item.py
	touch $(PROJECT_NAME)/app/db/crud/__init__.py
	touch $(PROJECT_NAME)/app/db/crud/user.py
	touch $(PROJECT_NAME)/app/db/crud/item.py
	touch $(PROJECT_NAME)/app/services/__init__.py
	touch $(PROJECT_NAME)/app/services/email.py
	touch $(PROJECT_NAME)/app/services/notification.py
	touch $(PROJECT_NAME)/app/tasks/__init__.py
	touch $(PROJECT_NAME)/app/tasks/scheduler.py
	touch $(PROJECT_NAME)/app/utils/__init__.py
	touch $(PROJECT_NAME)/app/utils/helpers.py
	touch $(PROJECT_NAME)/app/middleware/__init__.py
	touch $(PROJECT_NAME)/app/middleware/custom_auth.py
	touch $(PROJECT_NAME)/tests/__init__.py
	touch $(PROJECT_NAME)/tests/conftest.py
	touch $(PROJECT_NAME)/tests/test_auth.py
	touch $(PROJECT_NAME)/tests/test_users.py
	touch $(PROJECT_NAME)/.env
	touch $(PROJECT_NAME)/requirements.txt
	touch $(PROJECT_NAME)/.gitignore
	touch $(PROJECT_NAME)/README.md
	touch $(PROJECT_NAME)/alembic/env.py
	touch $(PROJECT_NAME)/alembic.ini
	@echo "✅ Structure complète du projet créée sous $(PROJECT_NAME)/"
	@echo "✅ Vous pouvez maintenant commencer à développer votre application"
	@echo "import os\nfrom dotenv import load_dotenv\n\nload_dotenv()\n\nclass Settings:\n    PROJECT_NAME = \"FastAPI Project\"\n    DATABASE_URL = os.getenv(\"DATABASE_URL\")\n    SECRET_KEY = os.getenv(\"SECRET_KEY\", \"secret\")\n    ALGORITHM = \"HS256\"\n    ACCESS_TOKEN_EXPIRE_MINUTES = 30\n\nsettings = Settings()" > $(PROJECT_NAME)/app/core/config.py
	@echo "from passlib.context import CryptContext\n\npwd_context = CryptContext(schemes=[\"bcrypt\"], deprecated=\"auto\")\n\ndef hash_password(password: str) -> str:\n    return pwd_context.hash(password)\n\ndef verify_password(plain_password: str, hashed_password: str) -> bool:\n    return pwd_context.verify(plain_password, hashed_password)" > $(PROJECT_NAME)/app/core/security.py
	@echo "DATABASE_URL=sqlite:///./app.db\nSECRET_KEY=your_secret_key_here" > $(PROJECT_NAME)/.env
	@echo "from fastapi import FastAPI\nfrom app.api.routes import auth\nfrom app.db.database import Base, engine\n\napp = FastAPI()\n\nBase.metadata.create_all(bind=engine)\n\napp.include_router(auth.router)" > $(PROJECT_NAME)/app/main.py
	@echo "from sqlalchemy import create_engine\nfrom sqlalchemy.ext.declarative import declarative_base\nfrom sqlalchemy.orm import sessionmaker\nimport os\nfrom dotenv import load_dotenv\n\nload_dotenv()\nDATABASE_URL = os.getenv(\"DATABASE_URL\")\nengine = create_engine(DATABASE_URL, connect_args={\"check_same_thread\": False} if \"sqlite\" in DATABASE_URL else {})\nSessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)\nBase = declarative_base()\n\ndef get_db():\n    db = SessionLocal()\n    try:\n        yield db\n    finally:\n        db.close()" > $(PROJECT_NAME)/app/db/database.py
	@echo "from fastapi import APIRouter\n\nrouter = APIRouter()\n\n@router.get('/')\ndef read_root():\n    return {\"message\": \"Hello from auth\"}" > $(PROJECT_NAME)/app/api/routes/auth.py
	@echo "fastapi\nuvicorn[standard]\nsqlalchemy\npsycopg2-binary\npython-dotenv\nalembic\npasslib[bcrypt]\ngunicorn" > $(PROJECT_NAME)/requirements.txt
	@echo "DATABASE_URL=sqlite:///./app.db" > $(PROJECT_NAME)/.env

	@echo "✅ Arborescence et fichiers de base créés dans $(PROJECT_NAME)/"

	@echo "📦 Création de l'environnement virtuel et installation des dépendances..."
	$(PYTHON) -m venv $(VENV)
	$(ACTIVATE) && pip install --upgrade pip
	$(ACTIVATE) && pip install -r $(PROJECT_NAME)/requirements.txt

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
