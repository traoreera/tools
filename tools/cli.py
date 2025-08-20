import subprocess
from logging import getLogger

import rich.highlighter
import typer
from rich.console import Console
from rich.logging import RichHandler

from .lint import LintConfigCli
from .plugins import PluginCli

# ============================================================
# 📌 Logger configuration
# ============================================================
console = Console()
logger = getLogger(__name__)
logger.addHandler(
    RichHandler(
        markup=True,
        show_time=False,
        console=console,
        highlighter=rich.highlighter.ReprHighlighter(),
        show_path=False,
        show_level=False,
        level="INFO",
    )
)
logger.setLevel("INFO")


# ============================================================
# 📌 CLI app
# ============================================================
app = typer.Typer(help="🚀 CLI Tool to manage the project (Makefile replacement)")


# ============================================================
# 📌 Utility function
# ============================================================
def run_command(
    command: str, cwd: str = None, spinner: bool = True, live: bool = False
):
    """
    Run a shell command with optional spinner and live output.

    Args:
        command (str): Command to execute
        cwd (str): Directory to run command in
        spinner (bool): Show spinner during execution
        live (bool): Stream output live instead of waiting
    """
    logger.info(f"[cyan]$ {command}[/cyan]")

    try:
        if live:
            # Stream output live
            process = subprocess.Popen(
                command,
                shell=True,
                cwd=cwd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
            )
            for line in process.stdout:
                console.print(f"[white]{line.strip()}[/white]")
            process.wait()
            if process.returncode != 0:
                error = process.stderr.read().strip()
                logger.error(f"[red]✘ Command failed:[/red] {error}")
                raise typer.Exit(code=1)

        else:
            # Run with spinner (wait until done)
            if spinner:
                with console.status(
                    "[bold green]⏳ Processing...[/bold green]", spinner="dots"
                ):
                    subprocess.run(command, shell=True, check=True, cwd=cwd)
            else:
                subprocess.run(command, shell=True, check=True, cwd=cwd)

        logger.info("[green]✔ Done[/green]")

    except subprocess.CalledProcessError as e:
        logger.error(f"[red]✘ Command failed with code {e.returncode}[/red]")
        raise typer.Exit(code=e.returncode)
    except Exception as e:
        logger.error(f"[red]✘ Unexpected error:[/red] {e}")
        raise typer.Exit(code=1)


pluginCli = PluginCli(app, run_command, logger)
lintConfigCli = LintConfigCli(app, run_command, logger)


def main():
    app()
