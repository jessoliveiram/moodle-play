Este é o roteiro completo de reprodução do ambiente local para o Moodle 5.3dev com Docker, PostgreSQL 17, PHP 8.3 e carga de usuários para testes.

---

**1. Estrutura de Arquivos do Projeto**

Organize o diretório raiz `moodle-play`:

```text
moodle-play/
├── Dockerfile
├── docker-compose.yml
├── config.php
├── users.csv
├── public/                 # Core clonado do repositório Moodle
└── ...

```

---

**2. Arquivos de Configuração de Infraestrutura**

* **`Dockerfile`** (PHP 8.3 + Apache + Extensões do Moodle):
```dockerfile
FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libpq-dev \
    unzip \
    git \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    zip \
    intl \
    xml \
    soap \
    opcache \
    pgsql \
    pdo_pgsql

RUN { \
    echo 'max_execution_time = 300'; \
    echo 'memory_limit = 512M'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'max_input_vars = 5000'; \
} > /usr/local/etc/php/conf.d/moodle-custom.ini

RUN a2enmod rewrite
WORKDIR /var/www/html

```


* **`docker-compose.yml`** (PostgreSQL 17 + Web na rede `moodle-net`):


```yaml
services:
  moodle-postgres:
    image: postgres:17
    restart: always
    environment:
      POSTGRES_DB: moodle
      POSTGRES_USER: moodleuser
      POSTGRES_PASSWORD: moodlepassword
    ports:
      - "5432:5432"
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - moodle-net

  moodle-web:
    build: .
    restart: always
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/html
      - ../moodledata:/var/www/moodledata
    depends_on:
      - moodle-postgres
    networks:
      - moodle-net

volumes:
  db_data:

networks:
  moodle-net:
    driver: bridge

```


* **`config.php`** (Raiz do projeto):


```php
<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = 'moodle-postgres';
$CFG->dbname    = 'moodle';
$CFG->dbuser    = 'moodleuser';
$CFG->dbpass    = 'moodlepassword';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport'    => '5432',
  'dbsocket'  => '',
);

$CFG->wwwroot   = 'http://localhost:8080';
$CFG->dataroot  = '/var/www/moodledata';
$CFG->admin     = 'admin';

$CFG->directorypermissions = 0777;

require_once(__DIR__ . '/lib/setup.php');

```


* **`users.csv`** (Carga em lote de usuários de teste):


```csv
username,password,firstname,lastname,email
prof1,ProfPassword123!,Carlos,Docente,prof@local.test
aluno1,AlunoPassword123!,Ana,Estudante,aluno@local.test

```



---

**3. Comandos de Inicialização e Instalação**

Execute a sequência no terminal PowerShell:

```powershell
# 1. Subir os containers e compilar a imagem web
docker compose up -d --build

# 2. Reconfigurar o DocumentRoot do Apache para a pasta /public (exigência Moodle 5.x)
docker compose exec moodle-web bash -c "sed -i 's|DocumentRoot /var/www/html$|DocumentRoot /var/www/html/public|g' /etc/apache2/sites-available/000-default.conf"
docker compose exec moodle-web apache2ctl graceful

# 3. Ajustar permissões da pasta moodledata
docker compose exec moodle-web chown -R www-data:www-data /var/www/moodledata

# 4. Instalar o schema do banco de dados via CLI
docker compose exec moodle-web php admin/cli/install_database.php --lang=pt_br --adminuser=admin --adminpass="AdminPassword123!" --adminemail=admin@example.com --fullname="Moodle OTT MVP" --shortname="OTT-MVP" --agree-license

# 5. Importar os usuários de teste
docker compose exec moodle-web php /var/www/html/public/admin/tool/uploaduser/cli/uploaduser.php --file=/var/www/html/users.csv --delimiter_name=comma --mode=addnew

```

---

**4. Configuração Final no Painel Web**

1. Acesse **`http://localhost:8080`** e faça login com `admin` / `AdminPassword123!`.
2. Vá em **Administração do site** > **Cursos** > **Gerenciar cursos e categorias** > **Criar novo curso**.


3. Na aba **Participantes** do curso:


* Inscreva `prof1` com o papel de **Professor** (*Editing Teacher*).


* Inscreva `aluno1` com o papel de **Estudante** (*Student*).
