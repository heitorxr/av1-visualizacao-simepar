# AV1 — Visualização de dados do SIMEPAR

Projeto da disciplina CE303 (UFPR, 2026.2), baseado em `AV1.pdf` e no material de Anderson Ara e Amanda Zanluca, salvo como `viz2025.pdf`.

## Escopo

- Uma observação: uma estação em um horário publicado pelo SIMEPAR.
- Cinco estações: Curitiba, Paranaguá, Londrina, Maringá e Foz do Iguaçu.
- Quantitativas: temperatura média (°C), umidade relativa (%) e velocidade do vento (km/h).
- Qualitativas: estação (original) e turno (derivado do horário: madrugada 00–05h, manhã 06–11h, tarde 12–17h, noite 18–23h).
- Recorte descritivo curto, sem inferência sobre o clima, causalidade ou independência entre horas consecutivas.
- Entrega: frente com quatro gráficos; verso com identificação, fontes, principais códigos e explicação. Imprimir as duas páginas na mesma folha A4, colorida.

## Histórico

Commits correspondem às etapas reais de organização, coleta, análise e composição; datas e autoria não são simuladas. Projeto desenvolvido com assistência de IA, sujeito à revisão e compreensão do aluno e às regras da disciplina.

## Fontes locais de referência

- `D:/downloads/AV1.pdf` — enunciado, entrega em 19/10/2026.
- `D:/downloads/viz2025.pdf` — material de visualização, especialmente seções 2.3, 2.5, 2.6 e 3.

## Entrega

- `resultados/AV1_frente_verso_A4.pdf`: duas páginas para impressão frente e verso **na mesma folha**, colorida, em A4 retrato. Use tamanho real/100% e virada pela borda longa; não use duas páginas por face. Preencha seu nome no verso.
- `resultados/AV1_frente.png` e `AV1_verso.png`: prévias.
- `GUIA_DO_CODIGO.md`: explicação para estudar antes da apresentação.
- `dados/brutos/`: cinco HTMLs originais, sem alteração ou preenchimento de medidas.
- `dados/entrada/fontes.csv`: endereços exatos, identificadores, instante de coleta e MD5 dos HTMLs.

## Executar

Requer R e o pacote `jsonlite` (usado na coleta e na auditoria da extração). Instale-o, se necessário, no console R com `install.packages("jsonlite", repos="https://cloud.r-project.org")`.

Na pasta do projeto, execute `Rscript executar.R tudo`. Esse comando **não acessa a internet**: refaz a análise e a visualização a partir da coleta preservada e executa os testes. Alternativamente, abra `AV1_Visualizacao_Simepar.Rproj` no RStudio e use `source("executar.R", encoding="UTF-8")`.

Nesta máquina, o executável é `D:/Program Files/R/R-4.5.2/bin/Rscript.exe`; `jsonlite` também está disponível na pasta local ignorada `.biblioteca/`. Os gráficos usam somente R base e Cairo. Os scripts não dependem desse caminho absoluto e o projeto pode ser renomeado/movido.

Etapas isoladas: `analisar`, `renderizar` e `verificar`. `coletar` só funciona em um projeto ainda sem CSV congelado, para impedir sobrescrita acidental. Para outro período, preserve este recorte e crie uma nova cópia/ramo com uma decisão explícita de atualização.

## Recorte e verificação

- Janela preservada: 14/10/2026 às 19h até 15/10/2026 às 19h, extremos incluídos; 25 horários na grade.
- A fonte publicou 122 registros de 125 possíveis. Maringá não aparece às 22h de 14/10, 05h e 13h de 15/10.
- Todos os quatro gráficos usam 110 observações: cinco estações nos mesmos 22 horários. As 12 observações publicadas fora desses horários comuns continuam preservadas e constam na auditoria.
- Não há interpolação ou suavização; a grade dos gráficos conserva NA nos horários excluídos.
- `resultados/verificacoes.txt`: 401 verificações da coleta congelada, incluindo comparação de cada medida com o HTML original e recálculo dos resumos.
- O PDF foi inspecionado visualmente nas duas páginas e validado com PyMuPDF: duas páginas de aproximadamente 210 x 297 mm. PyMuPDF foi ferramenta de revisão, não é dependência para executar o projeto.

**Limites:** o fuso de Brasília foi adotado, pois a página não o declara explicitamente. Turno é uma categoria derivada: confirme com o professor caso ele exija duas qualitativas originais. O recorte é descritivo e não permite conclusões sobre o clima ou causalidade. Dados acessados em endereço público do próprio domínio SIMEPAR com subdomínio `stage`; a procedência exata está documentada, sem apresentá-lo como API histórica oficial.

## Git

Repositório **local**, com commits das etapas efetivas e correções reais. Nenhum remoto foi criado nem houve publicação no GitHub. Antes de alterar código, confira `git status`; preserve a versão anterior e faça um novo commit descritivo depois de executar e verificar a atualização. Não alterar datas ou fabricar uma sequência retrospectiva de commits.
