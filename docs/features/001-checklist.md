## Checklist da Feature 001

Verificação do ambiente: a pasta de features ainda não contém o checklist solicitado no workspace atual, então abaixo está o conteúdo completo, pronto para ser salvo no arquivo solicitado e usado como guia de execução do agente.

### Objetivo
Implementar a base do módulo Moodle `mod_videoplayer` com bootstrap do plugin, schema XMLDB, permissões, renderização e fluxo de ingestão direta por Presigned URL para storage de mídia bruto.

---

### Fase 1 — Alinhamento de escopo e arquitetura
- [x] Confirmar que o módulo será um plugin nativo do Moodle em `public/mod/videoplayer`
- [ ] Validar que a solução segue o padrão de módulos do Moodle: `version.php`, `mod_form.php`, `lib.php`, `view.php`, `db/access.php`, `db/install.xml`
- [ ] Confirmar que a ação é de tipo recurso/atividade e não um plugin paralelo fora do core
- [x] Definir que a feature 001 cobre bootstrap e ingestão direta, não a transcodificação completa
- [x] Definir o provedor de storage alvo: MinIO local via API S3 e S3 em produção
- [x] Garantir que o upload direto nunca passe pelo PHP local do Moodle para arquivos grandes

### Fase 2 — Estrutura do módulo
- [ ] Criar a pasta `public/mod/videoplayer`
- [ ] Criar a estrutura:
  - [ ] `public/mod/videoplayer/version.php`
  - [ ] `public/mod/videoplayer/lib.php`
  - [ ] `public/mod/videoplayer/mod_form.php`
  - [ ] `public/mod/videoplayer/view.php`
  - [ ] `public/mod/videoplayer/db/access.php`
  - [ ] `public/mod/videoplayer/db/install.xml`
  - [ ] `public/mod/videoplayer/lang/en/videoplayer.php`
  - [ ] `public/mod/videoplayer/classes/storage_client.php`
  - [ ] `public/mod/videoplayer/classes/external/get_upload_url.php`
  - [ ] `public/mod/videoplayer/amd/src/direct_upload.js`
- [x] Garantir que o nome do componente do plugin seja `mod_videoplayer`
- [ ] Definir a versão do plugin com timestamp de data atual
- [ ] Definir `requires` compatível com a versão do Moodle do projeto

### Fase 3 — Dados do módulo
- [ ] Implementar a tabela `videoplayer` em XMLDB
- [ ] Incluir campos:
  - [ ] `id`
  - [ ] `course`
  - [ ] `name`
  - [ ] `intro`
  - [ ] `introformat`
  - [ ] `storage_key`
  - [ ] `manifest_url`
  - [ ] `status`
  - [ ] `timemodified`
- [x] Definir `status` com valores `PENDING`, `PROCESSING`, `READY`, `ERROR`
- [ ] Garantir chave primária e relacionamento com `course`
- [ ] Validar que `install.xml` atende ao padrão do Moodle XMLDB

### Fase 4 — Permissões e capacidades
- [ ] Definir `mod/videoplayer:addinstance`
- [ ] Definir `mod/videoplayer:view`
- [ ] Permitir que professores/editores adicionem instâncias do módulo
- [ ] Garantir que alunos/visitantes tenham visão condicional conforme contexto do curso
- [ ] Confirmar uso de `CONTEXT_COURSE` e `CONTEXT_MODULE` corretamente
- [ ] Validar que permissions não quebram o RBAC do Moodle

### Fase 5 — Metadados e strings
- [ ] Implementar `version.php` com:
  - [ ] `$plugin->component`
  - [ ] `$plugin->version`
  - [ ] `$plugin->requires`
  - [ ] `$plugin->maturity`
- [ ] Criar strings no idioma principal:
  - [ ] `pluginname`
  - [ ] `modulename`
  - [ ] `modulenameplural`
  - [ ] `videofile`
  - [ ] `uploadprogress`
  - [ ] `status_pending`
- [ ] Adicionar mensagens de erro e status claros para o professor

### Fase 6 — Formulário do módulo
- [ ] Criar `mod_form.php` estendendo `moodleform_mod`
- [ ] Incluir campos padrão:
  - [ ] `name`
  - [ ] `intro`
  - [ ] `coursemodule`
- [ ] Incluir campo específico para upload direto
- [ ] Implementar regras:
  - [ ] nome obrigatório
  - [ ] campo de vídeo obrigatório no fluxo de criação
- [ ] Preparar o formulário para receber `storage_key` e status de ingestão
- [ ] Garantir que o padrão Moodle de `standard_intro_elements()` e `standard_coursemodule_elements()` seja usado
- [ ] Validar que `add_action_buttons()` esteja presente

### Fase 7 — Lógica de ciclo de vida
- [ ] Implementar `videoplayer_supports()`
- [ ] Implementar `videoplayer_add_instance()`
- [ ] Implementar `videoplayer_update_instance()`
- [ ] Implementar `videoplayer_delete_instance()`
- [ ] Garantir uso de `timemodified`
- [ ] Confirmar persistência correta no banco
- [ ] Validar que `instance` e `cm` sejam tratados conforme a convenção do Moodle

### Fase 8 — Presigned URL e integração com storage
- [ ] Criar `classes/storage_client.php`
- [ ] Abstrair cliente do provedor de object storage
- [ ] Implementar geração de `Presigned PUT URL`
- [ ] Gerar chave única de arquivo para o bucket de ingestão
- [ ] Aplicar sanitização do nome do arquivo
- [ ] Garantir controle de expiração da URL
- [ ] Registrar `ContentType` e `Bucket`
- [ ] Evitar passagem de arquivo em memória pelo PHP do servidor
- [ ] Validar CORS do bucket para origem do Moodle

### Fase 9 — Web service / API de geração de URL
- [ ] Criar endpoint para geração da URL pré-assinada
- [ ] Expor operação segura para autenticação do usuário
- [ ] Validar que o usuário tenha permissão para editar o curso / atividade
- [ ] Retornar:
  - [ ] `upload_url`
  - [ ] `storage_key`
  - [ ] `expires_at`
- [ ] Incluir proteção por contexto e capacidade
- [ ] Registrar endpoint em services conforme padrão Moodle

### Fase 10 — Upload direto no browser
- [ ] Criar script do browser em `amd/src/direct_upload.js`
- [ ] Obter `Presigned URL` via chamada segura
- [ ] Realizar `PUT` diretamente ao bucket
- [ ] Atualizar estado da instância após upload (a transição para `PROCESSING` pertence à Feature 002)
- [ ] Definir `storage_key` e status inicial `PENDING`
- [ ] Exibir feedback visual ao professor
- [ ] Tratar erros de rede, timeout e upload inválido
- [ ] Garantir que o navegador não faça upload via form tradicional

### Fase 11 — Renderização do player
- [ ] Implementar `view.php`
- [ ] Recuperar `course_module` e instância do módulo
- [ ] Validar `require_login()`
- [ ] Verificar contexto do módulo
- [ ] Montar page context com `PAGE`
- [ ] Exibir título e nome da atividade
- [ ] Renderizar player HTML5 ou componente de vídeo compatível
- [ ] Resolver URL final baseada em `manifest_url`
- [ ] Tratar estados:
  - [ ] `PENDING`
  - [ ] `PROCESSING`
  - [ ] `READY`
  - [ ] `ERROR`

### Fase 12 — Validação funcional
- [ ] Criar instância do módulo em um curso
- [ ] Confirmar que o módulo aparece no menu de atividades
- [ ] Confirmar que formulário de criação funciona
- [ ] Confirmar que a URL pré-assinada é gerada com sucesso
- [ ] Confirmar que o upload direto funciona para arquivo grande
- [ ] Confirmar que a tabela registra `storage_key` e status inicial
- [ ] Confirmar que a página de visualização carrega corretamente
- [ ] Confirmar que a atividade respeita permissões de professor/aluno

### Fase 13 — Critérios de aceite
- [ ] O módulo existe como plugin nativo do Moodle
- [ ] A tabela de banco foi criada por XMLDB
- [ ] O professor consegue criar a instância no curso
- [ ] O upload do arquivo é enviado diretamente ao storage sem uso de PHP local
- [ ] O status do processamento é gravado corretamente
- [ ] O aluno consegue visualizar o conteúdo da atividade
- [ ] O acesso e as permissões respeitam o RBAC do Moodle

### Definition of Done
- [ ] O módulo `mod_videoplayer` foi criado dentro do padrão oficial do Moodle
- [ ] O plugin compila sem erros de sintaxe
- [ ] O banco de dados foi criado e a tabela principal está funcionando
- [ ] O fluxo de upload direto está funcional com storage externo
- [ ] A UI do professor mostra estado do processamento
- [ ] A view do aluno renderiza o vídeo corretamente
- [ ] O código está em conformidade com a arquitetura do projeto e com o PRD da feature 001

---

### Observações importantes
- O escopo da feature 001 é bootstrap do módulo e ingestão direta; a transcodificação completa deve entrar em fases posteriores.
- A decisão final sobre o provedor de storage deve ser tomada antes da implementação do cliente para evitar acoplamento desnecessário.
- Os requisitos de segurança e CORS do storage devem ser validados antes da etapa de upload direto em ambiente real.
