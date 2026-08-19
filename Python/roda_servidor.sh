#!/bin/bash

cd "$(dirname "$0")/codigo" || exit

source .venv/bin/activate

python main.py
