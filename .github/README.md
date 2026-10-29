# GitHub Actions

| Workflow | Branch | Ambiente | API | Download |
| --- | --- | --- | --- | --- |
| Development APK | `develop` | `staging` | Variável `COREVENT_API_URL` | Pré-release em Releases |
| Release APK | `main` | `production` | Padrão do app: produção | Artefato da execução |

O Gitflow parte de `main`, segue para `develop` e depois para uma branch de
trabalho no formato Conventional, como `ci/apk-workflows`. A integração retorna
da branch de trabalho para `develop` e, depois da validação, de `develop` para
`main`.

## APK de desenvolvimento

O workflow **Development APK** (`workflows/development-apk.yml`) executa em pushes
na branch `develop` e permite execução manual nessa mesma branch. Execuções
manuais em outras branches são ignoradas pelo job.

Antes de compilar, instala as dependências, gera o código, executa a análise e os
testes unitários e de widgets. Qualquer falha impede a publicação. O APK usa modo
debug, flavor `development` e Application ID
`com.corevent.corevent_work_app.development`.

### Configuração no GitHub

No repositório `corevent/corevent_work_app`:

1. Abra **Settings → Environments** e crie o ambiente `staging`.
2. Em **Environment variables**, adicione `COREVENT_API_URL` com a URL HTTPS da
   API de testes. O ambiente atual usa
   `https://corevent-staging-api-666040325433.us-central1.run.app`.
3. Configure as branches permitidas desse ambiente para incluir `develop`.
4. Integre a branch de trabalho em `develop`, seguindo o Gitflow do projeto.

O workflow exige uma URL HTTPS e falha antes do build se ela estiver ausente ou
inválida para essa verificação. A URL é passada por `--dart-define` para evitar o
uso da API padrão de produção por falta de configuração. Não são necessários
secrets de assinatura, credenciais GCP ou preparação da API para esse workflow.
A publicação usa o `GITHUB_TOKEN` da própria execução com `contents: write`.

### Execução e download

Pushes na `develop` disparam o workflow automaticamente. Para execução manual,
o arquivo do workflow também deve estar presente na branch padrão do repositório:
abra **Actions → Development APK → Run workflow** e selecione `develop`.

Após o sucesso, baixe os arquivos na seção **Releases** do repositório:

- `corevent-work-development.apk`
- `corevent-work-development.apk.sha256`

Cada execução publica uma pré-release com tag `dev-RUN-ATTEMPT`, apontando para o
commit compilado, sem marcar essa pré-release como a release mais recente.
As notas incluem o commit, o modo de compilação e o identificador do app.
Execuções são serializadas para não cancelar uma publicação em andamento.

O runner gera a chave de assinatura de debug. Atualizações entre builds podem
exigir desinstalar o APK de dev anterior, apagando os dados locais desse app.
O flavor de produção possui outro identificador e pode ficar instalado junto.

Esse workflow não publica na Google Play nem executa testes em aparelho ou
emulador. Câmera e modo totem precisam de validação em um dispositivo físico.

## APK de produção

O workflow **Release APK** (`workflows/release-apk.yml`) executa somente por
disparo manual na branch `main`, usando o ambiente `production`. Em outras
branches, o job é ignorado. As execuções são serializadas, sem cancelar uma
compilação em andamento.

### Configuração da assinatura

Em **Settings → Environments → production**, configure os secrets:

| Secret | Conteúdo |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Conteúdo do keystore de release codificado em Base64 |
| `ANDROID_STORE_PASSWORD` | Senha desse keystore |
| `ANDROID_KEY_ALIAS` | Alias da chave privada dentro desse keystore |
| `ANDROID_KEY_PASSWORD` | Senha da chave privada |

Os quatro valores devem corresponder à mesma chave. Para atualizar um APK já
distribuído, mantenha a chave usada para assiná-lo. Permita somente a branch
`main` nesse ambiente. Keystore e senhas não devem ser commitados no repositório.

Para obter o Base64 no Windows a partir do keystore existente, ajuste o caminho
e execute no PowerShell:

```powershell
$taskKeystorePath = (Resolve-Path './corevent-work-upload.jks').Path
Set-Clipboard -Value ([Convert]::ToBase64String([IO.File]::ReadAllBytes($taskKeystorePath)))
```

Cole o conteúdo no secret `ANDROID_KEYSTORE_BASE64`. Os outros três secrets são
a senha do keystore, o alias e a senha da chave privada desse mesmo arquivo.

O helper `scripts/prepare_android_signing.py` valida a presença dos secrets e o
Base64, grava o keystore em `$RUNNER_TEMP` e cria `android/key.properties` com
escape dos caracteres especiais. O workflow verifica se o keystore pode ser
aberto, se o alias existe e se a senha permite recuperar a chave privada.
As senhas são passadas ao `keytool` por variáveis de ambiente e sua saída é
suprimida. Os arquivos de assinatura são removidos mesmo em caso de falha.

### Compilação e verificações

Antes da assinatura, o workflow verifica os helpers de CI e a formatação dos
fontes, gera código, executa a análise e os testes com cobertura. O helper
`tool/format.dart` exclui os arquivos mantidos pelos geradores. O relatório
`coverage/lcov.info` é disponibilizado por 14 dias; não há limite mínimo de
cobertura configurado nesta etapa.

O build é universal, em modo release com flavor `production`, usando a API padrão
do app: `https://api.corevent.site/`. Não é necessário configurar uma variável de
API no ambiente `production`; o build não passa `COREVENT_API_URL`.

Antes de disponibilizar o APK, o workflow verifica:

- Assinatura válida, rejeitando certificado com `CN=Android Debug`.
- Application ID `com.corevent.corevent_work_app`.
- `versionCode` igual ao `build_number` informado.
- Permissão `android.permission.INTERNET`.

### Execução e download

Após a integração `ci/apk-workflows → develop → main`, abra **Actions → Release
APK → Run workflow**, selecione `main` e informe `build_number`. O workflow precisa
estar na branch padrão do repositório para disponibilizar o disparo manual.

Use um inteiro positivo, maior que o último distribuído, até `2100000000`.
O workflow valida o formato e o intervalo, mas não consulta versões anteriores.
O nome da versão vem de `pubspec.yaml`.

Baixe **Artifacts → production-apk-NÚMERO** na execução bem-sucedida. O artefato
fica disponível por 30 dias e contém:

- `corevent-work-production-NÚMERO.apk`
- `corevent-work-production-NÚMERO.apk.sha256`
- `signature.txt`: informações públicas da assinatura.
- `release.txt`: commit, número do build e identificador do pacote.

O workflow não cria GitHub Release, não publica na Google Play e não acessa a API
para preparar dados. Os arquivos de assinatura não são enviados aos artefatos.

### Verificações locais dos helpers

```bash
python -m unittest discover -s .github/scripts -p 'test_*.py'
dart tool/format.dart --check
```

Os testes de assinatura usam dados fictícios em diretórios temporários e não
exigem a chave de produção.

Para executar as verificações do app com cobertura:

```bash
flutter pub get
dart run build_runner build
flutter analyze --no-pub
flutter test test --no-pub --coverage
```

### Conferir o download

No Windows, descompacte o artefato de produção antes da verificação. Na pasta do
APK e do arquivo `.sha256`, ajuste o nome abaixo e compare os hashes:

```powershell
$taskApkName = 'corevent-work-production-2.apk'
$taskExpectedHash = ((Get-Content -LiteralPath "$taskApkName.sha256") -split '\s+')[0]
$taskActualHash = (Get-FileHash -LiteralPath $taskApkName -Algorithm SHA256).Hash
if ($taskActualHash -ine $taskExpectedHash) { throw 'Checksum do APK não confere.' }
```

Para dev, use `corevent-work-development.apk` no mesmo comando.

### Falhas comuns

| Falha | O que conferir |
| --- | --- |
| Job ignorado | Dev só executa na `develop`; produção só executa na `main`. |
| Ausência do botão Run workflow | O workflow precisa estar na branch padrão do repositório. |
| Validação da API de testes | `COREVENT_API_URL` precisa ser uma variável do ambiente `staging`, com URL HTTPS. |
| Keystore não abre | Base64 e senha devem corresponder ao mesmo keystore. |
| Alias ausente ou chave não recuperada | Confira `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD` para esse keystore. |
| Build number inválido | Informe inteiro entre 1 e 2100000000; escolha um maior que o último distribuído. |
| APK de dev não atualiza | A assinatura de debug pode mudar entre runners; pode ser necessário desinstalar o dev anterior. |

Consulte o [registro de validação](../docs/apk-validation.md) para distinguir as
verificações locais das que precisam de execução no GitHub e no aparelho.
