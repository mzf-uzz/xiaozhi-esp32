"""Test all dependencies import"""
import fastapi
import uvicorn
import websockets
import langchain
import langchain_openai
import openai
import opuslib
import numpy
import dotenv
import pydantic
import httpx
print("All imports OK!")
print(f"  fastapi={fastapi.__version__}")
print(f"  langchain={langchain.__version__}")
print(f"  openai={openai.__version__}")
print(f"  numpy={numpy.__version__}")
print(f"  opuslib={opuslib.__version__}")
