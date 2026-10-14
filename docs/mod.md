No repositório do Moodle, os tipos de atividades e recursos são gerenciados como sub-plugins dentro do diretório `/mod`.

A distinção conceitual do Moodle divide esses itens entre **Atividades** (elementos interativos com submissão, resposta ou avaliação) e **Recursos** (conteúdos estáticos para visualização).

---

### Atividades Interativas e Avaliativas (Core)

| Tipo (`mod/`) | Nome no Sistema | Descrição / Função Principal |
| --- | --- | --- |
| `assign` | **Tarefa** (*Assignment*) | Envio de trabalhos, redações online ou arquivos, com suporte a rubricas e correção. |
| `quiz` | **Questionário** | Provas e testes automatizados com múltiplos tipos de questões (múltipla escolha, V/F, numéricas). |
| `forum` | **Fórum** | Discussões assíncronas em tópicos, com avaliação de postagens e moderação. |
| `workshop` | **Laboratório de Avaliação** | Avaliação por pares (*peer assessment*), onde alunos revisam trabalhos uns dos outros. |
| `lesson` | **Lição** | Conteúdo pedagógico adaptativo em árvore, com caminhos condicionais baseados em respostas. |
| `h5pactivity` | **Atividade H5P** | Execução de pacotes interativos multimídia (vídeos interativos, jogos de memória, apresentações). |
| `choice` | **Escolha** (*Poll*) | Enquete rápida de questão única para votação ou tomada de decisão. |
| `feedback` | **Pesquisa de Opinião** | Coleta estruturada de feedback e formulários anônimos ou identificados. |
| `survey` | **Pesquisa Pré-definida** | Instrumentos padronizados de pesquisa psicopedagógica (COLLES, ATTLS). |
| `glossary` | **Glossário** | Criação colaborativa ou instrutiva de dicionários de termos e conceitos. |
| `wiki` | **Wiki** | Páginas colaborativas editáveis pelos próprios alunos em grupo ou individualmente. |
| `database` | **Base de Dados** | Criação de repositórios estruturados de registros e arquivos alimentados pelos usuários. |
| `chat` | **Chat** | Comunicação textual síncrona em tempo real. |
| `scorm` | **Pacote SCORM** | Execução e integração de pacotes de e-learning externos padronizados. |
| `lti` | **Ferramenta Externa (LTI)** | Conexão com serviços de aprendizagem externos compatíveis com Learning Tools Interoperability. |
| `bigbluebuttonbn` | **BigBlueButton** | Sala de webconferência e aulas ao vivo integrada nativamente. |

---

### Recursos de Conteúdo (Estáticos)

Embora também residam no diretório `/mod`, servem para disponibilização de material didático:

* **`resource` (Arquivo)**: Download ou visualização direta de PDFs, slides, documentos.
* **`folder` (Pasta)**: Agrupamento estruturado de múltiplos arquivos para download.
* **`page` (Página)**: Conteúdo web criado com o editor de texto rico dentro do ambiente.
* **`book` (Livro)**: Conteúdo estruturado em formato de capítulos e subcapítulos.
* **`url` (Link/URL)**: Redirecionamento para endereços web externos.
* **`label` (Rótulo/Área de Texto)**: Inserção de texto, imagens ou divisores diretamente no corpo da página do curso.