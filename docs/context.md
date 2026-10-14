O **Moodle** é um LMS (*Learning Management System*) modular cuja arquitetura de dados é definida via especificações XMLDB (em `db/install.xml` nos módulos e no core).

Embora uma instalação completa possua centenas de tabelas para acomodar plugins e tipos de atividade, o núcleo do Moodle é estruturado em torno das seguintes **entidades de domínio principais**:

---

### 1. Usuários e Autenticação (`User & Auth`)

* **`User` (`mdl_user`)**: A entidade central de identidade (estudantes, professores, administradores), contendo credenciais, dados cadastrais e status de conta.
* **`User Preferences` (`mdl_user_preferences`)**: Configurações de interface e preferências individuais do usuário.
* **`User Info Field / Data` (`mdl_user_info_field`, `mdl_user_info_data`)**: Campos customizados de perfil definidos pelo administrador.

---

### 2. Cursos e Estrutura Pedagógica (`Course & Category`)

* **`Course Category` (`mdl_course_categories`)**: Organização hierárquica/pastas de cursos (departamentos, semestres, etc.).
* **`Course` (`mdl_course`)**: A unidade curricular/sala de aula virtual, definindo formato (tópicos, semanas), datas de início/fim e configurações gerais.
* **`Course Section` (`mdl_course_sections`)**: Seções, módulos ou semanas que dividem o conteúdo dentro de um curso.
* **`Course Module` (`mdl_course_modules`)**: Instância que conecta uma atividade ou recurso específico a uma seção de um curso.
* **`Modules` (`mdl_modules`)**: Registro dos tipos de módulos instalados no sistema (ex: `assign`, `quiz`, `forum`, `page`).

---

### 3. Contexto, Papéis e Permissões (`RBAC & Context Engine`)

* **`Context` (`mdl_context`)**: O pilar de escopo de segurança do Moodle. Representa o nível onde uma ação ocorre (`SYSTEM`, `COURSECAT`, `COURSE`, `MODULE`, `BLOCK`, `USER`).
* **`Role` (`mdl_role`)**: Papéis definidos no sistema (ex: Estudante, Professor, Moderador).
* **`Role Assignments` (`mdl_role_assignments`)**: Associação de um usuário a um papel dentro de um contexto específico.
* **`Role Capabilities` (`mdl_role_capabilities`)**: Regras granulares de permissão vinculadas a papéis e contextos.

---

### 4. Matrículas e Acesso (`Enrolment`)

* **`Enrol` (`mdl_enrol`)**: Instâncias dos métodos de matrícula ativos para um curso (ex: auto-inscrição, manual, LTI, sincronização externa).
* **`User Enrolments` (`mdl_user_enrolments`)**: Registra a participação ativa do usuário em um curso através de uma instância de matrícula.

---

### 5. Grupos e Turmas (`Groups`)

* **`Group` (`mdl_groups`)**: Subdivisões de alunos dentro de um mesmo curso.
* **`Grouping` (`mdl_groupings`)**: Agrupamentos de múltiplos grupos para restrição de visibilidade de atividades.
* **`Group Members` (`mdl_groups_members`)**: Associação de usuários aos grupos.

---

### 6. Avaliação e Notas (`Gradebook`)

* **`Grade Category` (`mdl_grade_categories`)**: Categorização e pesos para cálculo de médias.
* **`Grade Item` (`mdl_grade_items`)**: Qualquer elemento pontuável (uma prova, uma tarefa, a nota final do curso).
* **`Grade Grade` (`mdl_grade_grades`)**: A nota/conceito obtido por um usuário específico em um `Grade Item`.

---

### 7. Atividades e Conteúdos (Módulos do Core)

* **`Assign` / `Assign Submission` / `Assign Grades` (`mdl_assign_*`)**: Entidades responsáveis por envio de arquivos, tarefas e feedback.
* **`Quiz` / `Question` / `Quiz Attempts` (`mdl_quiz_*`, `mdl_question_*`)**: Questionários, banco de questões parametrizadas e tentativas de resposta.
* **`Forum` / `Forum Discussions` / `Forum Posts` (`mdl_forum_*`)**: Fóruns de discussão, tópicos e respostas.

---

### 8. Arquivos e Logs (`Infrastructure Core`)

* **`Files` (`mdl_files`)**: Sistema de arquivos unificado que mapeia referências lógicas a hashes físicos no diretório `moodledata`.
* **`Log Standard` (`mdl_logstore_standard_log`)**: Rastreabilidade e trilha de auditoria de ações realizadas por usuários no sistema.