"""Verifica o PDF entregue: texto conciso, procedencia e motivacao pessoal.

Executar: uv run --with pymupdf python testes/testar_pdf.py
PyMuPDF e ferramenta de revisao, nao dependencia da analise em R.
"""
from pathlib import Path
import pymupdf

raiz = Path(__file__).resolve().parents[1]
with pymupdf.open(raiz / "resultados/AV1_frente_verso_A4.pdf") as pdf:
    assert len(pdf) == 2, "A entrega deve ter frente e verso."
    frente, verso = (" ".join(pagina.get_text().split()) for pagina in pdf)
    assert "Paraná em 24 horas" in frente, "Falta o novo titulo direto."
    assert "Temperatura, umidade e vento em cinco estações do SIMEPAR" in frente
    assert "Escolhi esta base por já ter trabalhado com ela durante meu período no SIMEPAR." in verso
    assert "tracejado" in frente.lower() and "122" in frente and "110" in frente
    assert "Gráficos 2–4" in verso and "22 horários comuns" in verso
    assert len(frente.split()) <= 190, "Enxugar o texto da frente sem retirar unidades."
    assert len(verso.split()) <= 300, "Enxugar o verso sem retirar fonte e metodo."
    for pagina in pdf:
        assert abs(pagina.rect.width * 25.4 / 72 - 210) < 1
        assert abs(pagina.rect.height * 25.4 / 72 - 297) < 1
        for bloco in pagina.get_text("dict")["blocks"]:
            for linha in bloco.get("lines", []):
                for trecho in linha["spans"]:
                    x0, y0, x1, y1 = trecho["bbox"]
                    assert x0 >= 8 and y0 >= 8
                    assert x1 <= pagina.rect.width - 8 and y1 <= pagina.rect.height - 8, trecho["text"]
    print(f"OK: 2 paginas A4; {len(frente.split())} palavras na frente e {len(verso.split())} no verso.")
    print("OK: titulo, motivacao pessoal, recortes distintos e ausencia de textos cortados.")
