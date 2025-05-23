my\_fastapi\_project/ <br>
├── .env <br>
├── requirements.txt <br>
├── app/<br>
│   ├── main.py<br>
│   ├── api/<br>
│   │   ├── **init**.py<br>
│   │   └── routes/<br>
│   │       ├── **init**.py<br>
│   │       └── auth.py<br>
│   ├── db/<br>
│       ├── **init**.py<br>
│       ├── database.py<br>
│       ├── crud/<br>
│       │   └── **init**.py<br>
│       ├── models/<br>
│       │   └── **init**.py<br>
│       └── schemas/<br>
│           └── **init**.py<br>
├── alembic/ (si Alembic est initialisé)<br>
└── Makefile<br>

````

---

## 🛠️ Installation

```bash
make install
````

Cette commande :

* Crée l’arborescence
* Génère les fichiers de base
* Crée un environnement virtuel `.venv`
* Installe les dépendances dans `requirements.txt`

---

## ▶️ Démarrer l'application

* En développement :

  ```bash
  make run-dev
  ```
* En production (via Gunicorn) :

  ```bash
  make run-deploy
  ```

---

## ⚙️ Commandes utiles

| Commande                        | Description                                              |
| ------------------------------- | -------------------------------------------------------- |
| `make install`                  | Création de la structure, des fichiers et installation   |
| `make run-dev`                  | Lancer FastAPI avec `uvicorn --reload`                   |
| `make run-deploy`               | Lancer avec `gunicorn`                                   |
| `make init-alembic`             | Initialiser Alembic (une seule fois)                     |
| `make db-init`                  | Appliquer les migrations Alembic                         |
| `make db-migrate msg="message"` | Créer une migration avec Alembic                         |
| `make refresh-db`               | Supprimer et recréer la base de données                  |
| `make test`                     | Lancer les tests `pytest` (si `tests/` existe)           |
| `make lint`                     | Vérifier la qualité du code avec `flake8`                |
| `make freeze`                   | Geler les dépendances dans `requirements.txt`            |
| `make clean`                    | Nettoyage de l’environnement et des fichiers temporaires |

---

## 🔐 Authentification

Une route d’exemple est définie dans `auth.py`. Tu peux y ajouter :

* inscription
* login
* génération de JWT
* protection des routes avec `Depends(get_current_user)`

---

## 📦 Technologies utilisées

* [FastAPI](https://fastapi.tiangolo.com)
* [Uvicorn](https://www.uvicorn.org)
* [SQLAlchemy](https://www.sqlalchemy.org)
* [Alembic](https://alembic.sqlalchemy.org)
* [Gunicorn](https://gunicorn.org)
* [Python-dotenv](https://pypi.org/project/python-dotenv)
* [Passlib](https://passlib.readthedocs.io)
* [Pytest](https://docs.pytest.org)
* [Flake8](https://flake8.pycqa.org)

---

## 📌 À faire

* Ajouter les modèles utilisateur
* Ajouter les routes `register` et `login`
* Protéger certaines routes avec des `Depends`

---

## 🧪 Exemple rapide

```bash
curl http://localhost:8000/
# {"message": "Hello from auth"}
```

---

## ❓ Questions
traoreeera [traoreera@gmail.com] [@traoreera]
