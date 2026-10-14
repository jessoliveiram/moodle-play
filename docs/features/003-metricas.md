Para telemetria avançada de vídeo OTT (tempo assistido, retenção, taxa de conclusão e mapa de calor), a estratégia padrão combina as APIs nativas do Moodle com uma tabela customizada no plugin via Web Services/AJAX.

---

### Mecanismos Nativos do Moodle

* **Event 2 API (`\core\event\*`)**: O Moodle registra eventos como `course_module_viewed` na tabela `mdl_logstore_standard_log`. Ele sabe *quando* e *quem* abriu a página, mas **não** mede o comportamento dentro do player (ex: pausou aos 2 minutos ou pulou partes).
* **Completion API (`completion_info`)**: Permite marcar a atividade como concluída com base em regras:
* *Manual*: Aluno marca o checkbox.
* *Automática por visualização*: Apenas abrir a página já conclui.
* *Critério Customizado*: O plugin define via código quando considera concluído (ex: disparado via JS apenas quando o aluno atingir 80% do playback).


* **Learning Analytics API**: Motor preditivo do core para prever evasão e engajamento baseado nos logs agregados.
* **xAPI / CMI5 (Sub-padrões via LRS)**: O Moodle suporta integração com Learning Record Stores (LRS) para receber statements xAPI padrão de vídeo (`played`, `paused`, `seeked`, `completed`).

---

### Arquitetura Recomendada: Tabela Customizada + AJAX/Web Service

Para exibir métricas ricas de OTT para o professor (tempo assistido, porcentagem concluída, último segundo reproduzido), implemente um pipeline interno:

```
[ Video.js (Eventos timeupdate/ended) ] 
                 │
                 ▼  AJAX Beacon / Moodle Web Service
[ mod_videoplayer_update_tracking (external API) ]
                 │
                 ▼
[ Tabela: mdl_videoplayer_tracking ] ──► [ Dashboard no view.php do Professor ]

```

---

### 1. Schema do Banco para Rastreamento (`db/install.xml`)

Adicione a tabela `mdl_videoplayer_tracking` para registrar o progresso de cada aluno por instância:

```xml
<TABLE NAME="videoplayer_tracking" COMMENT="Metricas de visualizacao do video por aluno">
  <FIELDS>
    <FIELD NAME="id" TYPE="int" LENGTH="10" NOTNULL="true" SEQUENCE="true"/>
    <FIELD NAME="videoplayerid" TYPE="int" LENGTH="10" NOTNULL="true" SEQUENCE="false"/>
    <FIELD NAME="userid" TYPE="int" LENGTH="10" NOTNULL="true" SEQUENCE="false"/>
    <FIELD NAME="totaltime" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false" COMMENT="Tempo total assistido em segundos"/>
    <FIELD NAME="lastposition" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false" COMMENT="Ultimo segundo onde pausou"/>
    <FIELD NAME="percentcomplete" TYPE="int" LENGTH="3" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
    <FIELD NAME="completed" TYPE="int" LENGTH="1" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
    <FIELD NAME="timemodified" TYPE="int" LENGTH="10" NOTNULL="true" DEFAULT="0" SEQUENCE="false"/>
  </FIELDS>
  <KEYS>
    <KEY NAME="primary" TYPE="primary" FIELDS="id"/>
    <KEY NAME="fk_videoplayer" TYPE="foreign" FIELDS="videoplayerid" REFERENCES="videoplayer" REFS="id"/>
    <KEY NAME="fk_user" TYPE="foreign" FIELDS="userid" REFERENCES="user" REFS="id"/>
  </KEYS>
  <INDEXES>
    <INDEX NAME="user_video_idx" UNIQUE="true" FIELDS="videoplayerid, userid"/>
  </INDEXES>
</TABLE>

```

---

### 2. Captura de Telemetria no Player (`view.php` / JS AMD)

No frontend, escute os eventos do `Video.js` e envie pings periódicos (ex: a cada 10 segundos ou no `pause`/`ended`) usando o cliente AJAX do core (`core/ajax`):

```javascript
// Exemplo em JS (moodle-amd ou inline script)
const player = videojs('moodle-ott-player');

let lastPing = 0;
player.on('timeupdate', function() {
    const currentTime = Math.floor(player.currentTime());
    const duration = Math.floor(player.duration());
    
    // Dispara a cada 10 segundos ou ao final
    if (currentTime - lastPing >= 10 && duration > 0) {
        lastPing = currentTime;
        const percent = Math.min(100, Math.floor((currentTime / duration) * 100));

        require(['core/ajax'], function(ajax) {
            ajax.call([{
                methodname: 'mod_videoplayer_save_progress',
                args: {
                    cmid: cmId,
                    position: currentTime,
                    percent: percent
                }
            }]);
        });
    }
});

```

---

### 3. Disparando a Conclusão do Moodle no Backend

Ao receber o progresso no Web Service, você pode atualizar a tabela customizada e invocar a API de conclusão nativa quando o aluno atingir o threshold desejado (ex: 80% do vídeo assistido):

```php
// Callback no backend da Web Service
if ($percent >= 80) {
    $completion = new completion_info($course);
    if ($completion->is_enabled($cm) && $cm->completion == COMPLETION_TRACKING_AUTOMATIC) {
        $completion->update_state($cm, COMPLETION_COMPLETE, $USER->id);
    }
}

```

---

### 4. Exibição para o Professor

No `view.php`, verifique se o usuário tem permissão de edição/professor (`has_capability('mod/videoplayer:viewreport', $context)`) e renderize um relatório tabular:

```php
if (has_capability('moodle/course:manageactivities', $context)) {
    echo $OUTPUT->heading(get_string('trackingreport', 'mod_videoplayer'), 3);

    $sql = "SELECT t.*, u.firstname, u.lastname, u.email
              FROM {videoplayer_tracking} t
              JOIN {user} u ON u.id = t.userid
             WHERE t.videoplayerid = :vid";
    $records = $DB->get_records_sql($sql, ['vid' => $videoplayer->id]);

    $table = new html_table();
    $table->head = ['Aluno', 'Última Posição', 'Progresso', 'Concluído', 'Último Acesso'];

    foreach ($records as $rec) {
        $table->data[] = [
            fullname($rec),
            gmdate("H:i:s", $rec->lastposition),
            $rec->percentcomplete . '%',
            $rec->completed ? 'Sim' : 'Não',
            userdate($rec->timemodified)
        ];
    }
    echo html_writer::table($table);
}

```