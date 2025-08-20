import os

from typer import Typer


class LintConfigCli:

    def __init__(self, app: Typer, run_cmd, logger):
        self.app = app
        self.run = run_cmd
        self.logger = logger
        self.root_dir = os.curdir
        self.command()
        return

    def command(self):

        @self.app.command(help="Lint code", name="lint-init")
        def lint_init():
            with open(".autoflake.cfg", "w") as f:
                f.write(
                    """[tool.autoflake]
# Configuration autoflake - très conservateur pour préserver les imports
remove-all-unused-imports = false
remove-unused-variables = true
remove-duplicate-keys = true

expand-star-imports = false
ignore-init-module-imports = true

exclude = alembic,static,__pycache__,.git"""
                )

            with open(".autopep8", "w") as f:
                f.write(
                    """[autopep8]
# Configuration autopep8 - conservatrice pour FastHTML
max_line_length = 88
in-place = true
recursive = true
aggressive = 1

# Préserver les imports et la structure FastHTML
ignore = E402,W503,E203,F403,F405
exclude = alembic,static,__pycache__,.git,migrations

# Ne corriger que les problèmes de style sûrs
select = E1,E2,E3,E4,E7,E9,W1,W2,W6
"""
                )
            with open(".flake8", "w") as f:
                f.write(
                    """[flake8]
max-line-length = 88
exclude = 
    alembic,
    static,
    __pycache__,
    .git,
    .env,
    migrations

ignore = 
    F403,
    F405,
    E203,
    W503
"""
                )

            with open(".isort.cfg", "w") as f:
                f.write(
                    """[settings]
combine_as_imports=true
default_section=THIRDPARTY
indent='    '
include_trailing_comma=true
known_first_party=src
known_third_party=flask,flask_login,flask_migrate,flask_sqlalchemy,flask_wtf,sqlalchemy,wtforms
line_length=79
multi_line_output=3
order_by_type=true
"""
                )

            self.logger.info("✅ Configuration lint initiale créee avec successe")

        @self.app.command(help="Lint code fix it", name="lint-fix")
        def lint_fix():
            self.logger.info("🔧 Correction automatique du code (mode SAFE)...")
            self.logger.info("📋 1. Correction autopep8 (lignes longues, espaces)...")
            self.run(
                "poetry run autopep8 --in-place --recursive --exclude=alembic,static,__pycache__ ."
            )
            self.logger.info("📋 2. Tri des imports avec isort...")
            self.run(
                "poetry run isort . --skip=alembic --skip=static --skip=__pycache__"
            )
            self.logger.info("📋 3. Formatage avec black...")
            self.run('poetry run black . --exclude="(alembic|static|__pycache__)"')
            self.logger.info(
                "📋 4. Suppression CONSERVATIVE des variables inutiles (préserve imports)..."
            )
            self.run(
                "poetry run autoflake --in-place --recursive --remove-unused-variables --ignore-init-module-imports --exclude=alembic,static,__pycache__ ."
            )
            self.logger.info("✅ Correction automatique terminée (imports préservés)!")

        @self.app.command(help="Lint code preview", name="lint-preview")
        def lint_preview():
            self.logger.info("👀 Prévisualisation des corrections autopep8:")
            self.run(
                "poetry run autopep8 --diff --recursive --exclude=alembic,static,__pycache__ . | head -50"
            )
            self.logger.info("👀 Prévisualisation du formatage black:")
            self.run(
                'poetry run black --diff . --exclude="(alembic|static|__pycache__)" | head -30'
            )

        @self.app.command(help="Lint code safe", name="lint-safe")
        def lint_safe():
            self.logger.info("🔍 Vérification du code (compatible FastHTML)...")
            self.run("poetry run flake8 .")

        return lint_fix, lint_preview, lint_safe
