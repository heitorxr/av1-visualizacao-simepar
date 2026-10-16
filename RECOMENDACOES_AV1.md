# Revisão da AV1: evidências públicas e recomendações

Consulta: 15/10/2026. **A versão atual do PDF foi mantida.** A última proposta com sinônimos ficou somente na conversa; não foi aplicada ao projeto. Esta revisão não estima uma nota nem atribui ao professor preferências que ele não documentou.

## O que consegui confirmar

1. A página de ensino de Anderson Ara disponibiliza o material de Visualização de Dados Aplicada da CE303, assinado com Amanda Zanluca e identificado como de 2025.[1] A versão HTML informa fevereiro de 2025 e apresenta o mesmo título do PDF local `viz2025.pdf`.[2]
2. O capítulo 3 contém análises e propostas de melhoria de gráficos. Nas seções 3.8 e 3.9 há exemplos indicados por alunos da disciplina na UFPR. São comentários didáticos, **não provas corrigidas com notas**. O material aponta problemas de cores pouco distinguíveis, referências/eixos ausentes, inversão de eixo e decoração que dificulta a leitura.[2]
3. Em mensagem de 12/02/2025, o próprio Ara divulgou o livro e um vídeo de apresentação de uma aluna em uma avaliação final. Ele descreveu foco aplicado e computacional, com dashboards ao final da disciplina. Isso não transforma dashboards em exigência da sua AV1 A4.[3]
4. Uma notícia da UFPR de **29/04/2025** documenta o segundo lugar nacional do pôster **“Definindo o Amor”**, orientado por Ara, na ISLP Poster Competition 2024/25. A matéria relaciona a experiência à disciplina.[4] O pôster tem uma questão central, objetivos, gráficos relacionados à questão e comentários finais.[5] Isso é um exemplo concreto de trabalho orientado, mas não revela a nota recebida na disciplina nem os critérios de uma AV1.

**Limite da busca:** não encontrei, nas páginas públicas consultadas e nas buscas dirigidas à CE303/AV1, avaliações de 2026 corrigidas individualmente por Ara, com notas e justificativas. Não afirmo que elas não existam; não estavam disponíveis nas fontes que consegui confirmar. Os exemplos públicos mais recentes pertinentes que confirmei são de 2025. Também não usei notas ou documentos de outros professores como se fossem correções dele.

## O critério mais forte continua sendo o seu enunciado

Fonte: `D:/downloads/AV1.pdf`, CE303, 2026.2, fornecido pelo aluno:

| Critério | Peso informado |
|---|---:|
| Identificação e interpretação dos padrões estatísticos | 20% |
| Escolha dos gráficos | 20% |
| Princípios de excelência gráfica de Tufte | 50% |
| Explicação da construção no verso | 10% |

O enunciado exige pelo menos 80 observações, três quantitativas, duas qualitativas e quatro gráficos, em uma folha A4 com explicação no verso. Também adverte sobre entregas significativamente semelhantes. Não menciona pontuação de detector de IA como critério. Isso não dispensa outras regras da disciplina sobre uso de IA.

## Auditoria do trabalho atual

- Foram preservados os 122 registros publicados. Os gráficos comparativos usam 110 observações nos 22 horários comuns às cinco estações; o gráfico temporal mostra as temperaturas disponíveis e sinaliza as três lacunas de Maringá.
- Há três medidas quantitativas, quatro gráficos, nome completo, fonte e explicação. **Turno é uma categoria criada a partir do horário**, não uma variável qualitativa originalmente medida. O enunciado não proíbe essa transformação, mas não consigo confirmar como Ara interpreta esse ponto.
- A figura já apresenta unidades, cores e símbolos consistentes, ausência de 3D/eixo duplo e médias da tarde superiores às dos demais turnos nas cinco estações. Minha avaliação é que convém aprimorar a leitura, não substituir toda a composição.

## Recomendações, por prioridade

As propostas abaixo são **minhas inferências**, confrontando a rubrica e o material com a figura atual; não são instruções privadas nem preferências pessoais comprovadas do professor.

### 1. Fazer os títulos contar a história

Os títulos “Temperatura horária” e “Vento entre estações” dizem o que foi desenhado, mas não antecipam o principal resultado. Eu testaria “Curitiba teve maior amplitude térmica” e “Maringá teve o maior vento médio”, mantendo unidades e período nas posições atuais. O título do gráfico 4 já faz isso. O ganho esperado é na comunicação dos padrões, não em complexidade estatística. O material diferencia mostrar dados de comunicar informações de modo claro; o pôster orientado também organiza gráficos em torno de uma questão.[2][5]

No gráfico 2, “Temperatura e umidade” identifica a medida com mais precisão do que “Calor e umidade”. Se couber sem apertar o painel, uma conclusão curta sobre a associação negativa pode cumprir o papel narrativo. Não acrescentaria uma frase longa a todos os gráficos.

### 2. Colocar trechos reais do R no verso

Os comandos atuais contêm `...`, nomes genéricos e argumentos resumidos. O enunciado pede os principais códigos usados. Para reduzir a margem de interpretação, eu mostraria dois ou três trechos curtos retirados literalmente do projeto: seleção dos horários comuns, cálculo de Pearson e resumo por turno. Não é necessário imprimir o script inteiro. Essa é uma recomendação baseada no enunciado local, não em um gosto presumido de Ara.

### 3. Esclarecer que a correlação é global

Manteria o valor −0,767, mas nomearia **“Pearson global, n = 110”**. Ele reúne estações diferentes e não equivale à média das correlações de cada cidade. Não acrescentaria p-valor: as horas sucessivas são dependentes e o objetivo é descritivo.

Conferência adicional executada em R sobre os mesmos dados, somente para esta auditoria:

| Estação | Pares | Pearson dentro da estação |
|---|---:|---:|
| Curitiba | 22 | −0,991 |
| Foz do Iguaçu | 22 | −0,920 |
| Londrina | 22 | −0,988 |
| Maringá | 22 | −0,975 |
| Paranaguá | 22 | −0,967 |

Esses resultados mostram por que é útil identificar o escopo do número global. Não recomendo colocar toda essa tabela no A4 nem fazer novos testes para parecer mais sofisticado.

### 4. Confirmar a segunda qualitativa antes de mexer na base

Pergunta objetiva ao professor: **“Posso usar estação e turno do dia, sendo turno derivado do horário, como as duas variáveis qualitativas?”** É a principal dúvida formal que não posso resolver por pesquisa pública. Não recomendo trocar turno por identificador da estação, pois isso apenas duplicaria a mesma classificação. Se ele aceitar a derivação, a base atual atende a esse aspecto sem precisar de outra coleta.

### 5. Fazer a última revisão em tamanho de impressão

O material enfatiza percepção, distinção de cores e redução de tinta sem função.[2] Eu conferiria a folha impressa a 100%, sobretudo os símbolos pequenos, os rótulos do vento e a separação entre as curvas laranja e marrom do gráfico 1. Ajustaria somente o que realmente prejudicar a leitura. Não adicionaria ícones meteorológicos, molduras ou gráficos avançados apenas porque aparecem em outro trabalho premiado: o contexto e o formato da competição são diferentes da AV1.[4][5]

## O que eu manteria

Manteria o tema ligado à experiência do aluno, os quatro tipos de gráfico, a indicação das lacunas, o uso de horários comuns para os resumos, o nome completo e a explicação anterior. Não copiaria o layout do pôster premiado nem trataria o uso de R como preferência exclusiva do professor; o enunciado permite outras ferramentas.

**Decisão recomendada:** se o aluno quiser uma nova versão, começar pelos títulos e pelos códigos reais no verso; acrescentar apenas a palavra “global” à correlação. A confirmação sobre turno deve vir do professor. Nenhuma dessas propostas foi aplicada ao PDF nesta consulta.

## Sources

[1] https://leg.ufpr.br/~ara/teach
[2] https://leg.ufpr.br/~ara/teach/viz2025.html
[3] https://lists.ime.usp.br/archives/abe/2025-February/011213.html
[4] https://ufpr.br/equipe-de-estatistica-da-ufpr-se-destaca-em-concurso-de-visualizacao-de-dados-do-ibge
[5] https://ufpr.br/wp-content/uploads/2025/04/poster_m-scaled.jpg
