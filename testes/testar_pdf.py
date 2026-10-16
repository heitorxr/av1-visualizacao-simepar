"""Verifica o PDF entregue: texto conciso, procedencia e motivacao pessoal.

Executar: uv run --with pymupdf python testes/testar_pdf.py
PyMuPDF e ferramenta de revisao, nao dependencia da analise em R.
"""
from pathlib import Path
import csv
import math
import statistics
import pymupdf

raiz = Path(__file__).resolve().parents[1]
with (raiz / "resultados/dados_analisados.csv").open(encoding="utf-8", newline="") as arquivo:
    pares = list(csv.DictReader(arquivo))
r_esperado = statistics.correlation(
    [float(x["temperatura_c"]) for x in pares],
    [float(x["umidade_pct"]) for x in pares],
)
rotulo_correlacao = f"Correlação global de Pearson: {r_esperado:.3f}".replace(".", ",").replace("-", "−")
with pymupdf.open(raiz / "resultados/AV1_frente_verso_A4.pdf") as pdf:
    assert len(pdf) == 2, "A entrega deve ter frente e verso."
    frente, verso = (" ".join(pagina.get_text().split()) for pagina in pdf)
    assert "Paraná em 24 horas" in frente, "Falta o novo titulo direto."
    assert "Temperatura, umidade e vento em cinco estações do SIMEPAR" in frente
    assert "Heitor Cardoso Fernandes" in verso, "Falta o nome completo."
    assert rotulo_correlacao in frente, "Falta a correlacao calculada com os pares do grafico 2."
    assert f"{len(pares)} pares das cinco estações" in frente
    assert "Escolhi esta base porque já a utilizava quando trabalhava no SIMEPAR." in verso
    assert "tracejado" in frente.lower() and "122" in frente and "110" in frente
    assert "gráficos 2–4" in verso.lower() and "22 horários comuns" in verso
    assert "Maringá tem três horários sem dados." in verso, "Falta o relato da organizacao dos dados."
    assert "A base e o recorte" in verso and "Como montei os gráficos" in verso
    assert len(frente.split()) <= 190, "Enxugar o texto da frente sem retirar unidades."
    assert len(verso.split()) <= 300, "Enxugar o verso sem retirar fonte e metodo."
    codigo = verso[verso.index("Principais comandos R"):verso.index("Fontes e reprodução")]
    assert "..." not in codigo, "O verso deve mostrar codigo real, sem placeholders."
    assert "horarios_comuns <- names(contagens)[" in codigo
    assert 'analise[c("estacao", "turno")], mean)' in codigo
    assert "correlacao <- cor(pares_correlacao$temperatura_c," in codigo
    spans_frente = [s for b in pdf[0].get_text("dict")["blocks"]
                    for l in b.get("lines", []) for s in l["spans"]]
    titulo_temporal = next(s for s in spans_frente if "Temperatura horária" in s["text"])
    assert titulo_temporal["bbox"][1] < 165, "Compactar cabecalho para ampliar o grafico temporal."
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
with (raiz / "resultados/correlacao_temperatura_umidade.csv").open(encoding="utf-8", newline="") as arquivo:
    resumo = list(csv.DictReader(arquivo))
assert len(resumo) == 1 and int(resumo[0]["n"]) == len(pares)
assert math.isclose(float(resumo[0]["r_pearson"]), r_esperado, rel_tol=1e-12)
print(f"OK: nome completo e Pearson verificado independentemente: {r_esperado:.8f}.")
with pymupdf.open(raiz / "resultados/AV1_frente_verso_A4.pdf") as pdf:
    pagina = pdf[1].get_text()
    explicacao = pagina[pagina.index("A base e o recorte"):pagina.index("Principais comandos R")]
amostra = (raiz / "resultados/texto_para_verificacao.txt").read_text(encoding="utf-8")
assert "".join(explicacao.split()) == "".join(amostra.split()), "Amostra deve reproduzir o texto do PDF."
print("OK: amostra textual sincronizada com a explicacao do verso.")
