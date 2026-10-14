O mapeamento do modelo de dados para a sua monografia divide-se entre as **tabelas nativas do Moodle** com as quais a solução se integra e as **tabelas customizadas do módulo (`mod_videoplayer`)**.

---

### 1. Entidades Nativas do Moodle (Core Integrado)

| Entidade / Tabela | Descrição e Papel na Solução | Campos-Chave Relacionados |
| --- | --- | --- |
| **`mdl_user`**<br> | Entidade de usuários (alunos e professores). Identifica quem consome o vídeo e quem gerencia a atividade.

 | `id`, `firstname`, `lastname`, `email`<br> |
| **`mdl_course`**<br> | A unidade curricular onde a atividade de vídeo é instanciada.

 | `id`, `fullname`, `shortname`<br> |
| **`mdl_course_modules`**<br> | Registra a instância da atividade dentro da grade do curso e controla as regras de conclusão nativa.

 | `id`, `course`, `module`, `instance`, `completion`<br> |
| **`mdl_course_completion_criteria`** | Define as regras de conclusão configuradas para o curso/módulo.

 | `id`, `course`, `moduleinstance` |
| **`mdl_course_modules_completion`** | Armazena o estado de conclusão da atividade por aluno (disparado quando $\ge 80\%$).

 | `id`, `coursemoduleid`, `userid`, `completionstate`<br> |
| **`mdl_context`**<br> | Define o escopo de segurança/RBAC no nível do módulo.

 | `id`, `contextlevel`, `instanceid`<br> |

---

### 2. Entidades Customizadas do Plugin (`mod_videoplayer`)

#### A. Configuração da Atividade (`mdl_videoplayer`)

Armazena os parâmetros pedagógicos da instância e o ponteiro direto para o manifesto HLS no Blob Storage.

| Coluna | Tipo | Nulo | Default | Descrição / Papel |
| --- | --- | --- | --- | --- |
| **`id`**<br> | INT(10) PK | Não | *Auto* | Identificador único da instância.

 |
| **`course`**<br> | INT(10) FK | Não | - | Chave estrangeira para `mdl_course.id`.

 |
| **`name`**<br> | VARCHAR(255) | Não | - | Título da videoaula exibido no curso.

 |
| **`intro`**<br> | TEXT | Sim | NULL | Descrição ou orientações pedagógicas.

 |
| **`introformat`**<br> | INT(4) | Não | 0 | Formato do texto da introdução (HTML, Markdown, etc.).

 |
| **`storage_key`**<br> | VARCHAR(255) | Sim | NULL | Identificador/caminho do arquivo bruto original no Bucket de Ingestão.

 |
| **`manifest_url`**<br> | VARCHAR(512) | Sim | NULL | URI/URL direta do manifesto `master.m3u8` no Object Storage.

 |
| **`status`**<br> | VARCHAR(30) | Não | `'PENDING'` | Estado do pipeline (`PENDING`, `PROCESSING`, `READY`, `ERROR`).

 |
| **`timemodified`**<br> | INT(10) | Não | 0 | Timestamp da última alteração de configuração.

 |

#### B. Telemetria e Rastreamento Individual (`mdl_videoplayer_tracking`)

Registra os eventos e métricas de consumo por estudante, validando progresso e prevenindo fraudes (*anti-cheat*).

| Coluna | Tipo | Nulo | Default | Descrição / Papel |
| --- | --- | --- | --- | --- |
| **`id`**<br> | INT(10) PK | Não | *Auto* | Identificador único do registro de telemetria.

 |
| **`videoplayerid`**<br> | INT(10) FK | Não | - | Chave estrangeira para `mdl_videoplayer.id`.

 |
| **`userid`**<br> | INT(10) FK | Não | - | Chave estrangeira para `mdl_user.id`.

 |
| **`lastposition`**<br> | INT(10) | Não | 0 | Último segundo reproduzido (utilizado no *Resume Playback*).

 |
| **`furthestposition`**<br> | INT(10) | Não | 0 | Ponto máximo contínuo assistido (bloqueia fraudes de *seek*).

 |
| **`totaltime`**<br> | INT(10) | Não | 0 | Tempo total líquido assistido (em segundos).

 |
| **`percentcomplete`**<br> | INT(3) | Não | 0 | Porcentagem válida calculada ($0$ a $100$).

 |
| **`completed`**<br> | INT(1) | Não | 0 | Flag indicativa de conclusão ($0$ = Não, $1$ = Sim).

 |
| **`timemodified`**<br> | INT(10) | Não | 0 | Timestamp do último ping/beacon recebido.

 |

* **Restrição de Unicidade / Índice:** `UNIQUE KEY (videoplayerid, userid)`.



---

### 3. Diagrama Entidade-Relacionamento (ERD)

```mermaid
erDiagram
    mdl_course ||--o{ mdl_videoplayer : "contém"
    mdl_course ||--o{ mdl_course_modules : "estrutura"
    mdl_videoplayer ||--|| mdl_course_modules : "instancia"
    mdl_videoplayer ||--o{ mdl_videoplayer_tracking : "registra métricas"
    mdl_user ||--o{ mdl_videoplayer_tracking : "gera telemetria"
    mdl_user ||--o{ mdl_course_modules_completion : "possui status"
    mdl_course_modules ||--o{ mdl_course_modules_completion : "avalia"

    mdl_course {
        int id PK
        string fullname
        string shortname
    }

    mdl_user {
        int id PK
        string firstname
        string lastname
        string email
    }

    mdl_course_modules {
        int id PK
        int course FK
        int module FK
        int instance FK
        int completion
    }

    mdl_videoplayer {
        int id PK
        int course FK
        string name
        text intro
        int introformat
        string storage_key
        string manifest_url
        string status
        int timemodified
    }

    mdl_videoplayer_tracking {
        int id PK
        int videoplayerid FK
        int userid FK
        int lastposition
        int furthestposition
        int totaltime
        int percentcomplete
        int completed
        int timemodified
    }

    mdl_course_modules_completion {
        int id PK
        int coursemoduleid FK
        int userid FK
        int completionstate
    }

```