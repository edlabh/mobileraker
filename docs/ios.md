# Mobileraker Lite no iOS (Apple ID gratuito)

Este guia mostra como compilar e instalar o app no seu iPhone **sem a conta paga da Apple**
(US$ 99/ano), usando só um Apple ID gratuito. Uso pessoal e não comercial
(Mobileraker License v2). Não distribua o app compilado.

## O que funciona e o que não funciona

Funciona: controle da impressora, painel, câmera, arquivos, gráficos, Spoolman, preview de
G-code, fila de impressão e temas.

Não funciona com Apple ID gratuito:

- Notificações push do Mobileraker Companion (exigem APNs, só na conta paga).
- Widgets e Live Activities (exigem App Groups).
- Compras, App Check e Remote Config (o Firebase roda com valores de desenvolvimento, veja abaixo).

## Limites da conta gratuita

- O app **expira em 7 dias** e precisa ser reinstalado. Os dados do app são mantidos.
- No máximo **3 apps** instalados por esse método.
- No máximo **10 App IDs novos por semana**: escolha o Bundle ID uma vez e mantenha.

## Requisitos

- Um Mac com Xcode (versões novas do iOS exigem um Xcode novo).
- Flutter na versão do `pubspec.yaml` (`flutter: >=3.32.0`) e CocoaPods.
- Um iPhone com cabo e o **Modo Desenvolvedor** ligado
  (Ajustes > Privacidade e Segurança > Modo Desenvolvedor, o aparelho reinicia).

## 1. Baixar o código

```
git clone https://github.com/edlabh/mobileraker
cd mobileraker
flutter pub get
(cd common && flutter pub get && dart run build_runner build --delete-conflicting-outputs)
dart run build_runner build --delete-conflicting-outputs
```

O `mobileraker_pro` já está dentro do repositório, não é preciso clonar mais nada.

## 2. Firebase (valores de desenvolvimento)

O app inicializa o Firebase na abertura. Dois arquivos estão no `.gitignore` e você precisa
criá-los. Sem eles o build falha ou o app fecha logo depois de abrir.

**Importante:** a chave de API precisa ter **exatamente 39 caracteres** (formato `AIza...`).
Uma chave curta, como `local-dev-key`, faz o app fechar na abertura com
`FirebaseInstallations ... API Key length must be 39 characters`.

`mobileraker_pro/lib/firebase_options.dart` (valores falsos):

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Plataforma não suportada neste build local.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIza' 'SyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', // 39 caracteres no total
    appId: '1:000000000000:android:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'mobileraker-local-dev',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIza' 'SyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', // 39 caracteres no total
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'mobileraker-local-dev',
    iosBundleId: 'com.seunome.mobileraker', // o mesmo MOBILERAKER_BUNDLE_ID abaixo
  );
}
```

`ios/Runner/GoogleService-Info.plist` com os mesmos valores falsos (`API_KEY`, `GCM_SENDER_ID`,
`BUNDLE_ID`, `PROJECT_ID`, `GOOGLE_APP_ID`).

Com esses valores o app abre, mas Remote Config, App Check e compras não funcionam de verdade.
Para um Firebase real, crie um projeto gratuito e rode `flutterfire configure` com o seu
Bundle ID. **Nunca faça commit desses arquivos.**

## 3. Assinatura com Apple ID gratuito

1. Copie o exemplo e preencha com os seus valores:

   ```
   cp ios/Flutter/Local.xcconfig.example ios/Flutter/Local.xcconfig
   ```

   | Configuração | Valor |
   |---|---|
   | `MOBILERAKER_BUNDLE_ID` | Um identificador único seu, por exemplo `com.seunome.mobileraker`. O identificador do projeto original pertence ao autor. |
   | `MOBILERAKER_TEAM_ID` | O ID do seu Personal Team (10 caracteres, aparece no Xcode em Signing & Capabilities depois de adicionar o seu Apple ID). |
   | `MOBILERAKER_ENTITLEMENTS` | `Runner/RunnerFree.entitlements` (vazio: um Apple ID gratuito não pode usar Push, App Groups, iCloud etc.). |
   | `MOBILERAKER_FREE_SIGNING` | `YES`: o `pod install` remove do target Runner as extensões Live Activity e Notification Service e a etapa de envio de símbolos do Crashlytics. |

   O `Local.xcconfig` está no `.gitignore`. Os padrões do `Signing.xcconfig` são os valores do
   projeto original, então a build normal (conta paga) não muda se você não criar o
   `Local.xcconfig`.

2. Adicione o seu Apple ID no Xcode: Xcode > Settings > Accounts > **+**.
3. Aplique as configurações:

   ```
   cd ios && pod install
   ```

   Rode de novo toda vez que mudar o `Local.xcconfig`.

4. Não aceite o "Update to recommended settings" do Xcode.

**Para desfazer o modo gratuito:** apague o `Local.xcconfig` (ou use
`MOBILERAKER_FREE_SIGNING = NO`), rode `git checkout ios/Runner.xcodeproj` e `pod install`.

## 4. Compilar e instalar

```
flutter build ios --release
xcrun devicectl list devices
xcrun devicectl device install app --device <ID_DO_APARELHO> build/ios/iphoneos/Runner.app
```

Na primeira vez, o Mac pede a senha do chaveiro para o `codesign`. Depois, no iPhone:
Ajustes > Geral > **VPN e Gerenciamento de Dispositivos** > toque no seu Apple ID > **Confiar**.

Para usar `flutter run --debug`, mantenha o iPhone conectado: um app em debug não abre sozinho
pela tela inicial.

## 5. Renovar a cada 7 dias

Conecte o iPhone e repita o passo 4. Os dados do app são mantidos.

Renovar sem cabo:

- **AltStore**: AltServer no Mac, na mesma rede Wi-Fi. _Não verificado pelo autor deste guia._
- **SideStore**: renova no próprio iPhone, depois de uma configuração inicial que precisa de um
  computador. _Não verificado no iOS 27._

## 6. Instalar sem um Mac (Windows)

Compilar para iOS exige o Xcode, que só roda em macOS. Você **não precisa** de um Mac: um Mac
virtual do GitHub compila o app e gera um `.ipa` **sem assinatura**. Depois você o assina e
instala com o seu próprio Apple ID gratuito. Valem os mesmos limites de 7 dias e de 3 apps, e
as mesmas funções que faltam (push, widgets, Live Activities) da seção "Limites da conta
gratuita".

### 6.1 Obter o `.ipa`

Você precisa de uma conta gratuita no GitHub.

1. Se o mantenedor anexou o `Mobileraker-Lite-unsigned.ipa` a uma release, basta baixá-lo e ir
   para o 6.2.
2. Caso contrário, gere você mesmo:
   1. Faça um fork deste repositório no GitHub (botão **Fork**).
   2. No seu fork, abra a aba **Actions**. Se o GitHub perguntar, clique em
      "I understand my workflows, go ahead and enable them".
   3. Escolha **Build iOS (unsigned IPA)** na lista da esquerda, clique em **Run workflow** e
      confirme (deixe os campos como estão).
   4. Espere uns 20 minutos, até a execução ficar com o ícone verde.
   5. Abra a execução, desça até **Artifacts** e baixe o `Mobileraker-Lite-unsigned-ipa`.
      Descompacte: dentro estão o `Mobileraker-Lite-unsigned.ipa` e o arquivo `.sha256`.

O app é compilado com valores de Firebase de desenvolvimento (veja a seção 2), então Remote
Config, App Check e compras não funcionam de verdade.

### 6.2 Assinar e instalar no Windows (Sideloadly)

1. Instale o **iTunes** pelo site da Apple (a versão da Microsoft Store não é a que essas
   ferramentas esperam). Siga os requisitos atuais listados em https://sideloadly.io.
2. Instale o **Sideloadly**, em https://sideloadly.io.
3. No iPhone: ligue o **Modo Desenvolvedor** (Ajustes > Privacidade e Segurança > Modo
   Desenvolvedor, o aparelho reinicia), conecte-o por cabo USB, desbloqueie e toque em
   **Confiar**.
4. Abra o Sideloadly. Selecione o seu iPhone, arraste o `Mobileraker-Lite-unsigned.ipa` para a
   janela e digite o seu Apple ID. Clique em **Start** e digite a senha (e o código de duas
   etapas, se pedido). Considere usar um Apple ID secundário.
5. No iPhone: Ajustes > Geral > **VPN e Gerenciamento de Dispositivos** > toque no seu Apple ID
   > **Confiar**, e abra o app.

### 6.3 Renovar a cada 7 dias

Repita o 6.2 (os passos 3 a 5 bastam), com o mesmo Apple ID. Os dados do app são mantidos.
O **AltStore** (AltServer para Windows ou macOS, na mesma rede Wi-Fi) e o **SideStore**
podem renovar automaticamente. Siga os guias oficiais de instalação deles:
https://altstore.io e https://sidestore.io.

_O Sideloadly, o AltStore e o SideStore não foram testados pelo autor deste guia, nem no iOS 27.
Se algum passo for diferente, siga a documentação da própria ferramenta._

## 7. Problemas conhecidos

| Sintoma | Causa | Solução |
|---|---|---|
| O app abre e fecha na hora, com `UIScene lifecycle is required on iOS 27 and later` | Falta o ciclo de vida UIScene | Corrigido neste branch (`AppDelegate.swift`, `Info.plist`) |
| O app fecha na abertura, com `API Key length must be 39 characters` | Chave de API falsa curta demais | Use uma chave com 39 caracteres (seção 2) |
| `Build input file cannot be found: GoogleService-Info.plist` | Arquivo ausente | Crie o arquivo (seção 2) |
| `Ambiguous use of init(stringRepresentation:)` no pod RevenueCat | O RevenueCat 5.67 não compila com o Swift do Xcode 27 | Corrigido pelo `purchases_flutter ^10.16.0` (rode `pod update PurchasesHybridCommon RevenueCat` se o CocoaPods acusar conflito de versão) |
| `CocoaPods's specs repository is too out-of-date` | Cache local de especificações antigo | `pod repo update` |
| Aviso amarelo "no devices from which to generate a provisioning profile" | Nenhum iPhone conectado | Conecte o iPhone, confie no Mac e clique em "Try Again" |
| O app parou de abrir depois de alguns dias | Limite de 7 dias do Apple ID gratuito | Reinstale (seção 5) |

## 8. Peça a uma IA para fazer por você

Você pode dar este guia a um assistente de IA (Claude Code, ChatGPT, Gemini, Copilot...) e deixar
que ele o guie, ou que rode os comandos por você quando ele consegue rodar comandos no seu
computador.

### O que a IA pode e não pode fazer

| Ela pode | Ela não pode (você precisa fazer) |
|---|---|
| Ler o `docs/ios.md` e explicar cada passo | Digitar a senha do Apple ID e o código de duas etapas |
| No Mac: clonar, criar os arquivos de Firebase e o `Local.xcconfig` (ignorados pelo git), rodar o `pod install`, compilar e instalar | Conectar o iPhone, tocar em **Confiar** e ligar o **Modo Desenvolvedor** |
| Com o GitHub CLI (`gh`): fazer o fork, rodar o workflow, acompanhar, baixar o `.ipa` e conferir o `.sha256` | Tocar em **Confiar** no certificado, em Ajustes > Geral > VPN e Gerenciamento de Dispositivos |
| Explicar erros de compilação usando a tabela da seção 7 | Clicar dentro do Sideloadly (um programa de desktop) |

### Prompt para Mac

> Leia o `docs/ios.md` deste repositório e instale o Mobileraker no meu iPhone usando um Apple ID
> gratuito, seguindo as seções 1 a 4. Confira se o Xcode, o Flutter e o CocoaPods estão
> instalados. Crie o `ios/Flutter/Local.xcconfig` a partir do exemplo, com o meu Bundle ID
> `com.MEUNOME.mobileraker`, e me peça o ID do meu Personal Team. Crie os arquivos de Firebase
> ignorados pelo git (a chave de API precisa ter exatamente 39 caracteres). Explique cada erro
> antes de contorná-lo, pergunte antes de instalar qualquer coisa globalmente e não faça commit
> nem push de nada. Nunca peça a minha senha do Apple ID: eu mesmo a digito no Xcode.

### Prompt para Windows

> Leia a seção 6 do `docs/ios.md` e me guie, passo a passo, para instalar o Mobileraker no meu
> iPhone a partir do Windows. Use o GitHub CLI (`gh`) para fazer o fork do repositório, rodar o
> workflow **Build iOS (unsigned IPA)**, esperar e baixar o artefato, e então conferir o
> `.sha256`. Depois me diga exatamente onde clicar no Sideloadly. Eu mesmo digito a minha senha
> do Apple ID. Antes de rodar cada comando, me diga o que ele faz.

Comandos que a IA costuma usar (não testados no Windows):

```
gh repo fork edlabh/mobileraker --clone=false
gh workflow run "Build iOS (unsigned IPA)" --repo SEU_USUARIO/mobileraker
gh run list --repo SEU_USUARIO/mobileraker --workflow "Build iOS (unsigned IPA)" --limit 1
gh run watch ID_DA_EXECUCAO --repo SEU_USUARIO/mobileraker
gh run download ID_DA_EXECUCAO --repo SEU_USUARIO/mobileraker --name Mobileraker-Lite-unsigned-ipa
```

### Segurança

- **Nunca cole nem diga a uma IA**: a senha do Apple ID, códigos de duas etapas, tokens do
  GitHub, chaves de assinatura ou arquivos de keystore. Digite as senhas você mesmo, só no
  Xcode ou no Sideloadly. Considere um Apple ID secundário para instalar apps fora da loja.
- Não deixe que ela faça commit ou push do `Local.xcconfig`, `GoogleService-Info.plist`,
  `google-services.json`, `firebase_options.dart`, `key.properties` ou `*.jks`.
- Uma IA pode errar. Leia o comando antes de ele rodar e, se ela discordar deste guia, prefira
  os passos do guia.
