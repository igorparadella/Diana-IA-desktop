import asyncio
import edge_tts
import subprocess

VOZ = "pt-BR-FranciscaNeural"


async def falar(texto: str, arquivo: str = "fala.ogg"):
    mp3 = "temp.mp3"

    communicate = edge_tts.Communicate(
        text=texto,
        voice=VOZ,
    )

    await communicate.save(mp3)

    subprocess.run([
        "ffmpeg",
        "-y",
        "-i",
        mp3,
        arquivo
    ])

    print("Áudio criado:", arquivo)
