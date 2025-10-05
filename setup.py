#!/usr/bin/env python3
"""
Setup script for ITL Identity Platform documentation.
"""

import subprocess
import sys
import os
from pathlib import Path

def run_command(cmd, check=True):
    """Run a command and return the result."""
    print(f"Running: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"Error running command: {cmd}")
        print(f"Error output: {result.stderr}")
        sys.exit(1)
    return result

def check_python():
    """Check if Python 3.8+ is available."""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("Python 3.8+ is required")
        sys.exit(1)
    print(f"Python {version.major}.{version.minor}.{version.micro} detected")

def setup_venv():
    """Set up virtual environment."""
    if not Path("venv").exists():
        print("Creating virtual environment...")
        run_command(f"{sys.executable} -m venv venv")
    else:
        print("Virtual environment already exists")

def install_requirements():
    """Install Python requirements."""
    print("Installing requirements...")
    if os.name == 'nt':  # Windows
        pip_cmd = r"venv\Scripts\pip"
    else:  # Unix/Linux/macOS
        pip_cmd = "venv/bin/pip"
    
    run_command(f"{pip_cmd} install --upgrade pip")
    run_command(f"{pip_cmd} install -r requirements.txt")

def serve_docs():
    """Serve the documentation locally."""
    print("Starting MkDocs development server...")
    if os.name == 'nt':  # Windows
        mkdocs_cmd = r"venv\Scripts\mkdocs"
    else:  # Unix/Linux/macOS
        mkdocs_cmd = "venv/bin/mkdocs"
    
    run_command(f"{mkdocs_cmd} serve", check=False)

def main():
    """Main setup function."""
    print("ITL Identity Platform Documentation Setup")
    print("=" * 50)
    
    check_python()
    setup_venv()
    install_requirements()
    
    print("\nSetup complete!")
    print("\nTo start the development server:")
    print("  python setup.py serve")
    print("\nOr manually:")
    if os.name == 'nt':
        print("  venv\\Scripts\\mkdocs serve")
    else:
        print("  venv/bin/mkdocs serve")
    
    # Ask if user wants to start the server
    response = input("\nStart the development server now? (y/N): ")
    if response.lower() in ['y', 'yes']:
        serve_docs()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "serve":
        serve_docs()
    else:
        main()