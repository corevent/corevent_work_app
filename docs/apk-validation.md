# Validação dos workflows de APK

Data: 29/10/2026. Branch de trabalho: `ci/apk-workflows`.

## Verificações locais

| Verificação | Resultado |
| --- | --- |
| Estrutura e expressões dos dois workflows | Aprovadas pelo actionlint 1.7.12 |
| Formatação dos fontes | 110 arquivos conferidos; nenhuma alteração necessária |
| Análise do app e ferramentas | `flutter analyze --no-pub` sem problemas |
| Testes do app com cobertura | 109 testes passaram |
| Relatório de cobertura | `coverage/lcov.info` gerado, com 68 registros |
| Preparo dos arquivos de assinatura | 5 testes passaram, incluindo secrets ausentes, Base64 inválido e caracteres especiais |
| Builds debug dos dois flavors | Aprovados na fase 2; identificadores conferidos nos APKs |
| Release com chave temporária de teste | APK universal compilado e assinatura validada pelo apksigner |
| Identificador e versão do release local | `com.corevent.corevent_work_app`, `versionCode=2`, `versionName=0.1.0` |
| Permissão de internet | Presente no APK release |
| Checksum | SHA-256 gerado e conferido na cópia local do APK |
| Limpeza da assinatura temporária | `android/key.properties` removido e diretório temporário descartado |

A validação de formatação exclui `.g.dart` e `.freezed.dart`, mantidos pelos
geradores. A revisão dos workflows incluiu branches, ambientes, seleção de API,
nomes dos arquivos, assinatura, limpeza dos arquivos privados e caminhos enviados
aos artefatos. O actionlint foi executado sem as integrações externas ShellCheck
e Pyflakes; a aprovação desse comando não equivale à execução dos scripts no
runner Linux do GitHub.

Os testes usam serviços simulados. Não foi necessário executar o app nem acessar
a API de produção para validar os comandos de build.

## Ambientes e entrega

| Destino | Configuração | Entrega esperada |
| --- | --- | --- |
| Dev | `develop`, ambiente `staging`, variável `COREVENT_API_URL` | Pré-release com `corevent-work-development.apk` e checksum |
| Produção | `main`, ambiente `production`, quatro secrets de assinatura | Artefato `production-apk-NÚMERO`, retido por 30 dias |

O flavor `development` usa o sufixo `.development` no identificador. A URL de
testes precisa ser passada por `--dart-define`; o código mantém a API de produção
como padrão quando esse parâmetro está ausente. O workflow de dev exige uma URL
começando com `https://` antes da compilação. Essa verificação não confirma a
disponibilidade da API nem identifica se uma URL configurada pertence a staging.

## Validação de release

O teste local usa um keystore descartável e senhas fictícias. Ele exercita o
helper de preparo, a recuperação da chave privada e o build
`flutter build apk --release --flavor production --no-pub --build-number=2`.

O build foi concluído em Windows com Android Build Tools 36.0.0. Após a compilação,
o `apksigner` confirmou uma assinatura válida com certificado
`CN=Corevent Local Validation`, diferente do certificado Android Debug. O `aapt`
confirmou o identificador, a versão e a permissão de internet esperados.

As evidências locais ficam em `build/validation/`, fora do versionamento:

- `corevent-work-local-validation.apk`: APK assinado somente para teste local.
- `corevent-work-local-validation.apk.sha256`: checksum desse arquivo.
- `signature.txt`: informações públicas do certificado de teste.
- `release-validation.json`: verificações e hash do APK local.

Esse APK usa uma chave descartável e não deve ser distribuído como APK oficial.
O helper temporário e os arquivos privados não fazem parte das alterações a
integrar no Git.

A chave de teste não substitui a chave de produção. A assinatura com os secrets
reais e a execução completa do workflow precisam ser verificadas no GitHub.

## Pendências da fase 6

1. Configurar `staging`, sua variável `COREVENT_API_URL` e a permissão para
   `develop` no repositório do app de equipes.
2. Integrar a branch de trabalho em `develop` e validar a execução automática,
   a pré-release, o download e o checksum do APK de dev.
3. Configurar o ambiente `production`, restringir a `main` e cadastrar os quatro
   secrets correspondentes à chave de release existente.
4. Promover `develop` para `main` e executar **Release APK** com um `build_number`
   maior que o último distribuído.
5. Baixar o artefato, conferir o checksum e a assinatura da chave real e validar
   instalação ou atualização no aparelho.
6. Conferir login, eventos, permissões de câmera, leitura de QR e modo totem nos
   ambientes correspondentes. Esses fluxos não foram validados em aparelho nesta
   etapa.

Nenhum comando `gh`, alteração de ambiente remoto, integração de branches ou
publicação foi executado nesta validação local.

O passo a passo de configuração e download está no [guia das actions](../.github/README.md).
