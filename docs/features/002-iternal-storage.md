Este documento descreve uma alternativa descartada para o fluxo OTT. A implementação oficial usa upload direto para MinIO/S3 via Presigned URL; o binário não será armazenado no `moodledata` nem passará pelo PHP do Moodle.

O conteúdo abaixo é mantido apenas como referência histórica da alternativa Moodle File API e não deve ser usado na implementação do `mod_videoplayer`.

---

### Ajustes necessários para suportar upload de arquivos

#### 1. No formulário (`mod_form.php`)

Substitua o campo `videourl` pelo componente `filemanager`:

```php
$mform->addElement('filemanager', 'video_filemanager', get_string('uploadvideo', 'mod_videoplayer'), null, [
    'subdirs' => 0,
    'maxbytes' => $COURSE->maxbytes,
    'maxfiles' => 1,
    'accepted_types' => ['video/mp4', 'video/webm', 'video/quicktime', '.mp4', '.mkv']
]);

```

#### 2. No salvamento de arquivos (`lib.php`)

Salve o rascunho de arquivos (*draft area*) na área definitiva de arquivos do Moodle:

```php
function videoplayer_add_instance($data, $mform = null) {
    global $DB;
    $data->timemodified = time();
    $data->id = $DB->insert_record('videoplayer', $data);

    if ($mform) {
        $context = context_module::instance($data->coursemodule);
        file_save_draft_area_files(
            $data->video_filemanager,
            $context->id,
            'mod_videoplayer',
            'video',
            0,
            ['subdirs' => 0, 'maxfiles' => 1]
        );
    }
    return $data->id;
}

```

#### 3. No servidor de arquivos (`lib.php`)

O Moodle exige o callback `videoplayer_pluginfile` para que o navegador consiga baixar e fazer streaming com controle de acesso:

```php
function videoplayer_pluginfile($course, $cm, $context, $filearea, $args, $forcedownload, array $options=array()) {
    if ($context->contextlevel != CONTEXT_MODULE) {
        return false;
    }
    require_login($course, true, $cm);

    $fs = get_file_storage();
    $file = $fs->get_file($context->id, 'mod_videoplayer', 'video', 0, '/', $args[0]);

    if (!$file || $file->is_directory()) {
        return false;
    }

    send_stored_file($file, null, 0, $forcedownload, $options);
}

```

#### 4. Na visualização (`view.php`)

Gere a URL interna segura do Moodle via `moodle_url`:

```php
$fs = get_file_storage();
$files = $fs->get_area_files($context->id, 'mod_videoplayer', 'video', 0, 'sortorder', false);
$file = reset($files);

if ($file) {
    $video_url = moodle_url::make_pluginfile_url(
        $file->get_contextid(),
        $file->get_component(),
        $file->get_filearea(),
        $file->get_itemid(),
        $file->get_filepath(),
        $file->get_filename()
    );

    echo html_writer::tag('video', '', [
        'src' => $video_url,
        'controls' => 'controls',
        'style' => 'width: 100%; max-width: 800px; height: auto;'
    ]);
}

```

---

### Ativação no Moodle

Assim que esses arquivos estiverem em `public/mod/videoplayer`:

1. Acesse o Moodle logado como administrador em **Administração do Site > Notificações**.
2. O Moodle detectará o novo plugin e rodará o script de criação da tabela `mdl_videoplayer`.
3. Em qualquer curso com a **Edição ativada**, clique em **Adicionar uma atividade ou recurso**. O seu novo recurso aparecerá listado e pronto para uso pelo professor.

Não exatamente. O **`filemanager`** é apenas o componente de interface (UI) e a camada de formulário da **Moodle File API**, mas por baixo dos panos a arquitetura do Moodle funciona como um **Content-Addressable Storage (CAS)** híbrido baseado no sistema de arquivos local (diretório `moodledata`).

A divisão da arquitetura de armazenamento do Moodle opera em duas camadas:

---

### 1. Metadados e Relacionamento (Banco de Dados)

A tabela **`mdl_files`** armazena todas as referências lógicas do arquivo:

* **Contexto e Módulo**: `contextid`, `component` (`mod_videoplayer`), `filearea` (`video`), `itemid`.
* **Identificadores Lógicos**: `filename` (nome exibido ao usuário), `filepath`, `mimetype`, `filesize`.
* **Hash Criptográfico**: `contenthash` (o hash SHA-1 do conteúdo binário do arquivo).

---

### 2. Armazenamento Físico (`moodledata/filedir`)

O Moodle **não** guarda blobs binários diretamente nas colunas do banco de dados (MySQL/PostgreSQL) para evitar inchaço de transações e gargalos de I/O.

* Os arquivos ficam salvos no disco em `moodledata/filedir/`.
* A árvore de diretórios usa os primeiros 4 caracteres do `contenthash` para particionamento.
> *Exemplo*: Um vídeo com hash `3ab7c8...` fica fisicamente no caminho:
> `moodledata/filedir/3a/b7/3ab7c8e5f9920...` (sem extensão).



---

### Deduplicação Nativa (Content-Addressable Storage)

Graças a essa estrutura, se 10 professores subirem exatamente o mesmo arquivo de vídeo de 500 MB em cursos diferentes:

* Serão criados **10 registros** na tabela `mdl_files` (cada um apontando para seu respectivo curso/contexto).
* O arquivo físico será gravado **apenas uma vez** no disco sob o mesmo `contenthash`, economizando armazenamento.

### S3

Para transformar o recurso em um pipeline de vídeo sob demanda (VOD) em padrão OTT (HLS / MPEG-DASH) integrado ao Moodle, a melhor abordagem arquitetural é desacoplar o processamento pesado de transcodificação (ffmpeg) e a entrega de arquivos binários dos servidores web do Moodle.

Arquitetura de Referência
1. Upload: O professor envia o vídeo original (.mp4/.mov). O Moodle gera uma URL pré-assinada (presigned upload URL) direto para o bucket de entrada (S3 / Blob Storage).

2. Pipeline de Transcodificação (ffmpeg): Um webhook / trigger de evento no storage despacha uma task assíncrona (ex: job em container/worker com FFmpeg ou serviço gerenciado como AWS Elemental MediaConvert) para gerar manifestos e segmentos HLS/DASH.

3. Storage & CDN: Os arquivos gerados (.m3u8 / .mpd e segmentos .ts / .m4s) são gravados em um bucket público/protegido com distribuição via CDN.

4. Playback no Moodle: O plugin salva apenas a URI do manifesto HLS/DASH e instancia um player OTT (como Video.js, Hls.js ou Shaka Player) dentro do view.php.