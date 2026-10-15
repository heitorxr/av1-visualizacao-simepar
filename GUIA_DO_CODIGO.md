# Guia de leitura do código

## A ideia em uma frase

Cada linha representa **uma estação em um horário**. Usamos os mesmos horários nas cinco estações para contar como temperatura, umidade e vento variaram nesse recorte, sem transformar uma janela de 24 horas em uma conclusão sobre o clima.

## Ordem para estudar

1. **`executar.R`**: descobre a pasta do próprio projeto e escolhe uma etapa. Por isso a pasta pode ser movida ou renomeada sem editar caminhos absolutos.
2. **`R/01_coletar.R`**: baixa as páginas públicas, preserva o HTML e extrai os pares horário–valor embutidos nos gráficos do SIMEPAR. `jsonlite` interpreta esses pares. Não há valores inventados nem captura manual de pontos de uma imagem.
3. **`R/02_analisar.R`**: lê o CSV, interpreta datas, seleciona horários comuns, cria os turnos, calcula resumos e registra exclusões.
4. **`R/03_visualizar.R`**: transforma os resultados em quatro gráficos e escreve o verso. Usa gráficos do R base, sem ggplot2 ou pacote de composição.
5. **`R/04_verificar.R`**: confere regras da AV1, hashes dos HTMLs, cada valor extraído, cálculos e arquivos de saída.

## O que significam os principais objetos?

| Objeto | Conteúdo |
|---|---|
| `dados` | 122 observações realmente publicadas nas cinco páginas |
| `completo` | vetor lógico indicando linhas com as três medidas finitas |
| `horarios_comuns` | 22 horários com medidas nas cinco estações |
| `analise` | 110 observações utilizadas em todos os gráficos |
| `turno` | categoria criada a partir da hora: madrugada, manhã, tarde e noite |
| `grade` | 125 posições estação–hora; 15 têm NA porque não entram no recorte comum |
| `resumo` | uma linha por estação com mínimos, médias, máximos e amplitude |
| `por_turno` | uma linha por combinação estação–turno, com média e quantidade |
| `auditoria` | explica quais posições entraram e quais foram excluídas |

A grade tem 25 horários porque inclui os dois extremos: 19h do dia 14 e 19h do dia 15. Há três horários sem publicação em Maringá: 14/10 às 22h, 15/10 às 05h e 15/10 às 13h. Para a comparação comum, as outras quatro estações também deixam de contribuir nesses três horários. Portanto, **3 lacunas reais + 12 exclusões de alinhamento = 15 posições fora dos gráficos**. Não são 15 falhas do SIMEPAR.

## Como ler os cálculos

- **`mean(x)`**: soma os valores e divide pela quantidade de observações. A média de vento resume os 22 horários comuns de cada estação.
- **`min(x)` e `max(x)`**: menor e maior valor observados no recorte analisado.
- **Amplitude**: máximo menos mínimo de temperatura. Não é desvio-padrão nem amplitude climatológica.
- **`aggregate(..., mean)`**: separa os registros por estação e turno e calcula uma média em cada grupo.
- **`table(...)`**: conta registros por categoria ou por horário.
- **`merge(...)`**: junta tabelas por uma chave, como estação e horário. Não significa preencher dados ausentes.
- **`NA`**: ausência de um valor na grade analítica. Em `lines()`, interrompe a linha, evitando inventar continuidade visual.

## Como os gráficos são desenhados

O R cria um dispositivo de saída: `cairo_pdf()` para PDF vetorial ou `png()` para prévia. A função `frente()` desenha a primeira página e `verso()` desenha a segunda.

- `par(fig=...)` reserva um retângulo da página para um gráfico.
- `plot()` cria o sistema de eixos.
- `lines()` liga somente pontos consecutivos presentes na grade.
- `points()` representa observações ou médias.
- `segments()` mostra o intervalo mínimo–máximo do vento — **não um intervalo de confiança**.
- `rect()` colore cada célula da matriz estação–turno.
- `text()` acrescenta títulos, unidades e valores.
- `dev.off()` fecha e grava o arquivo.

As cores são fixadas por estação e repetidas nos três primeiros gráficos. Os símbolos também diferem para não depender apenas da cor. No quarto gráfico a cor representa **temperatura média**, e não estação; os números nas células dão a leitura exata. Não há eixo duplo nem efeitos 3D.

## Princípios do material aplicados

- **Tufte (seção 2.6)**: dados em primeiro plano; grade discreta; nenhuma moldura, fundo decorativo ou elemento 3D; revisão visual dos arquivos.
- **Gestalt (seção 2.3)**: alinhamento e proximidade deixam clara a separação e a relação entre painéis; cores e símbolos semelhantes indicam a mesma estação.
- **Cores (seção 2.5)**: poucas cores distinguíveis e redundância por símbolos; matriz com luminosidade ordenada para uma variável quantitativa.
- **Erros gráficos (seção 3)**: eixos identificados, unidades explícitas, escalas compartilhadas e ausência de distorções por perspectiva.

## Cuidados para defender o trabalho

1. A segunda variável qualitativa, **turno**, foi derivada, não medida pela estação. O enunciado não proíbe categorias derivadas, mas confirme com o professor se ele exige duas qualitativas originais.
2. A noite mistura horários de duas datas dentro da mesma janela. Não é uma noite completa nem a média de várias noites.
3. A página não declara expressamente o fuso: adotamos Brasília. Essa suposição está no verso.
4. O endereço acessível tem o subdomínio `stage`, dentro de `simepar.br`. A fonte exata e os HTMLs foram preservados; não se trata de dados de outro instituto ou de simulação. O endereço principal retornou 403 e o endpoint histórico anteriormente conhecido não resolveu no DNS; não usamos dados históricos que não conseguimos obter.
5. Correlação visual entre calor e menor umidade não prova causa. Não foi realizado teste estatístico com horas tratadas como independentes.
6. Os resultados representam as estações selecionadas e essa janela; não caracterizam todo o Paraná, a cidade inteira ou o clima.
7. O histórico Git registra as etapas reais, inclusive a correção da leitura de acentos HTML. Não é uma simulação de atividade passada.

## Perguntas para nossa explicação posterior

- Por que 122 observações viraram 110?
- Qual a diferença entre variável quantitativa, qualitativa e categoria derivada?
- Por que não interpolar os horários ausentes?
- O que cada gráfico acrescenta à história?
- Por que o segmento do vento não é uma barra de erro?
- Como trocar a paleta, o título ou o tamanho dos gráficos?

Podemos percorrer os arquivos nessa ordem e executar um bloco de cada vez no R/RStudio.
