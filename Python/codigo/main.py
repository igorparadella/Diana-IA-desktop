from fastapi import FastAPI
from pydantic import BaseModel
import asyncio
import os
import signal

from fala import falar

app = FastAPI()


class Mensagem(BaseModel):
    texto: str


@app.get("/")
def inicio():
    return {
        "status": "online",
        "mensagem": "Servidor da Diana funcionando!"
    }


@app.post("/chat")
def chat(msg: Mensagem):
    asyncio.run(falar(msg.texto))

    return {
        "resposta": msg.texto
    }


@app.post("/desligar")
def desligar():
    os.kill(os.getpid(), signal.SIGTERM)

    return {
        "status": "servidor desligado"
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8000,
        reload=False
    )
