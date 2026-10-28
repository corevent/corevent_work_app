# Corevent para Equipes

Aplicativo Android para colaboradores de eventos Corevent. O acesso é individual
por evento: somente leitura ou check-in. “Equipes” é o nome do aplicativo; não
existe um agrupamento de eventos por equipe.

## Funcionalidades

- Autenticação: login, cadastro em quatro etapas, verificação de e-mail e recuperação de senha.
- Sessão persistente com armazenamento seguro, refresh compartilhado e logout.
- Perfil: nome e telefone editáveis, foto com recorte/prévia e alteração de senha.
- Eventos vinculados ao colaborador, separados em próximos, em andamento e encerrados.
- Convites: consultar a permissão, aceitar ou recusar.
- Participantes com paginação e detalhes de cada ingresso.
- Check-in por câmera: uma leitura por vez, com confirmação ou motivo de recusa.
- Modo totem com leitura automática, retorno após o resultado e confirmação de encerramento.
- Tratamento de permissão da câmera, retomada do aplicativo e remoção de acesso.

A API confirma cada entrada. O aplicativo não credencia offline. Falhas de rede e
respostas incertas pausam o totem; não há repetição automática de check-in.

## Stack e organização

Flutter/Dart, Riverpod, Dio + Retrofit, Freezed + JSON Serializable, GoRouter,
Flutter Secure Storage, Mobile Scanner, Wakelock Plus e Remix Icons.

Feature-first + MVVM: `lib/features/` contém `auth`, `welcome`, `staff_events`,
`invitations`, `participants`, `checkin`, `account` e `profile`. Cada feature separa dados,
repositórios e apresentação/ViewModels. `lib/core/` reúne rede, armazenamento,
tema e componentes. A identidade visual e a autenticação reaproveitam o app
principal; os fluxos de colaborador seguem o mockup v7.

Plus Jakarta Sans, superfícies brancas, bordas discretas e feedback com cores
semânticas. Sem sombras, gradientes ou brilhos.

## Pré-requisitos

- Flutter 3.47.5 / Dart 3.13.4 ou versão compatível com o pubspec.
- Android SDK e JDK 17+ compatível com o Gradle instalado.
- Emulador ou dispositivo Android; câmera para leitura de QR.
- Conta Corevent e convite aceito para acessar um evento como colaborador.

## Executar

```bash
flutter pub get
dart run build_runner build
flutter run
```

A URL padrão é a mesma do aplicativo principal (`https://api.corevent.site`).
Para outro ambiente:

```bash
flutter run --dart-define=COREVENT_API_URL=https://sua-api
```

No emulador Android, uma API local usa `http://10.0.2.2:3000`. Em um dispositivo
físico, use o IP acessível do computador ou `adb reverse tcp:3000 tcp:3000` com
`http://localhost:3000`. HTTP é permitido apenas no manifesto de debug.
O VS Code inclui configurações de execução para produção e staging.

## Verificar e compilar

```bash
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Os testes desta etapa cobrem regras e widgets. Integração, E2E e validação física
da câmera ficam para a próxima etapa. Nenhum teste unitário usa a API real.

Release exige assinatura própria em `android/key.properties`. Consulte
`android/key.properties.example`; o keystore e as senhas não devem ser commitados.
Depois de configurar:

```bash
flutter build apk --release --split-per-abi
```

O único target do projeto é Android. O scanner e o modo totem precisam ser
conferidos em um dispositivo com câmera antes da distribuição.
