import os

import typer
from typer import Typer


class PluginCli:

    def __init__(self, app: Typer, run_cmd, logger):
        self.app = app
        self.run = run_cmd
        self.logger = logger
        self.PLUGIN_BASE_DIR = os.path.join(os.getcwd(), "core", "plugins")
        self.BACKGROUND_TASK_DIR = os.path.join(os.getcwd(), "backgroundtask")
        self.PLUGIN_NAME = "myplugin"

        self.command()

    def command(self):
        @self.app.command(help="Enable a plugin")
        def enable_plugin(
            name: str = typer.Option(self.PLUGIN_NAME, "--name", help="Nom du plugin")
        ):
            self.logger.info(f"✅ Enable {name}")

        @self.app.command(help="Disable a plugin")
        def disable_plugin(
            name: str = typer.Option(self.PLUGIN_NAME, "--name", help="Nom du plugin")
        ):
            self.logger.info(f"❌ Disable {name}")

        # ============================================================
        # 📌 Commande: add-plugin
        # ============================================================
        @self.app.command(
            help="Ajouter ou mettre à jour un plugin git et lier les tâches"
        )
        def add_plugin(
            name: str = typer.Option(..., "--name", "-n", help="Nom du plugin"),
            repo: str = typer.Option(None, "--repo", "-r", help="URL du repo git"),
        ):
            """
            Exemple:
                tools-cli add-plugin --name presence
                tools-cli add-plugin --name presence --repo git@github.com:me/presence.git
            """

            if not name:
                self.logger.error("❌ Erreur : veuillez fournir --name")
                raise typer.Exit(code=1)

            # Repo par défaut si non fourni
            if not repo:
                repo = f"git@github.com:trareera01/{name}.git"
                self.logger.warning(
                    f"⚠️ PLUGIN_REPO non défini, utilisation par défaut: {repo}"
                )

            plugin_dir = os.path.join(self.BACKGROUND_TASK_DIR, name)

            # Clonage ou mise à jour
            if not os.path.isdir(plugin_dir):
                self.logger.info(f"📥 Clonage du plugin {name} depuis {repo}...")
                self.run(f"git clone {repo} {plugin_dir}")
            else:
                self.logger.info(f"⬆️ Mise à jour du plugin {name}...")
                self.run("git pull", cwd=plugin_dir)

            # Création du lien symbolique dans backgroundtask
            link_target = os.path.join(self.BACKGROUND_TASK_DIR, f"{name}.py")
            if os.path.islink(link_target) or os.path.exists(link_target):
                self.run(f"rm -f {link_target}")
            self.run(f"ln -s {plugin_dir}/run.py {link_target}")

            self.logger.info(
                f"[green]✔ Plugin {name} prêt et lié dans backgroundtask ![/green]"
            )

        return (
            enable_plugin,
            disable_plugin,
            add_plugin,
        )
