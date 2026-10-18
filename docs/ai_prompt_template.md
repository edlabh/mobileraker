# Guia de Skills (AAS) e Template de Prompt — Mobileraker

> Referência para pedidos de desenvolvimento assistidos por IA neste projeto.
> Skills do catálogo [agentic-awesome-skills (AAS)](https://github.com/sickn33/agentic-awesome-skills) + template de prompt baseado nos frameworks RTF, RISEN e Chain of Thought.

---

## 1. Skills relevantes para o Mobileraker

O Mobileraker é um app **Flutter/Dart (Android + iOS)** para controlar impressoras 3D via Klipper/Moonraker,
com Riverpod, Freezed, go_router, Firebase, easy_localization (`assets/translations/*.yaml`) e o pacote compartilhado `common/`.

### Núcleo (Flutter/Dart/Mobile)

| Skill (ID) | Para que serve aqui | Risco | Status |
|---|---|---|---|
| `flutter-expert` | Widgets avançados, performance, Riverpod, build Android/iOS | safe | instalar |
| `dart` | Diretrizes específicas da linguagem Dart 3 | safe | instalar |
| `android-dev` | Build, CI/CD, release e performance no Android (pipeline principal do projeto) | safe | instalar |
| `mobile-developer` | Panorama cross-platform (opcional — sobrepõe-se ao flutter-expert) | critical | opcional |

### Qualidade, testes e debug

| Skill (ID) | Para que serve aqui | Risco | Status |
|---|---|---|---|
| `systematic-debugging` | Investigar causa raiz antes de corrigir bugs | critical | já disponível |
| `test-driven-development` | Ciclo red-green-refactor para features/correções | critical | já disponível |
| `code-review-checklist` | Revisão de PRs cobrindo segurança, performance, manutenibilidade | critical | já disponível |
| `unit-testing-test-generate` | Gerar testes unitários com foco em edge cases (test/unit) | critical | instalar |
| `five-axis-code-review` | Revisão estruturada (correção, segurança, leitura, performance, testes) | safe | opcional |
| `error-detective` | Correlacionar stack traces do Crashlytics com o código | safe | instalar |

### i18n, UI e acessibilidade

| Skill (ID) | Para que serve aqui | Risco | Status |
|---|---|---|---|
| `i18n-localization` | Strings hardcoded, gestão de traduções, RTL (projeto usa Crowdin) | safe | instalar |
| `ui-a11y` | Auditar e corrigir acessibilidade em telas/componentes | critical | já disponível |
| `accessibility-compliance-accessibility-audit` | Auditoria WCAG de fluxos (semântica, foco, contraste) | safe | já disponível |
| `frontend-design` | Melhorias visuais mantendo identidade do app | safe | já disponível |

### Performance

| Skill (ID) | Para que serve aqui | Risco | Status |
|---|---|---|---|
| `performance-engineer` | Perfis, gargalos e verificação de latência | critical | já disponível |
| `performance-optimization` | Otimizações guiadas por medição | critical | opcional |

### Git, CI/CD e release

| Skill (ID) | Para que serve aqui | Risco | Status |
|---|---|---|---|
| `git-advanced-workflows` | Rebase, resolução de conflitos, histórico limpo | critical | já disponível |
| `commit` / `git-pushing` | Commits e push seguindo convenções | — | já disponível |
| `changelog-automation` | Notas de versão (docs/changelog.md) a partir de commits/PRs | safe | já disponível |
| `github-actions-debugger` | Diagnosticar falhas no workflow `build-Android.yml` | critical | instalar |
| `github-actions` | Evoluir CI (testes, análise, builds por plataforma) | critical | opcional |
| `app-store-changelog` | Texto de release para Play Store / App Store | safe | opcional |

### Planejamento e prompting

| Skill (ID) | Para que serve aqui | Risco | Status |
|---|---|---|---|
| `prompt-engineer` | Transformar pedidos vagos em prompts otimizados | safe | já disponível |
| `concise-planning` | Planos de tarefa com checklist acionável | safe | já disponível |
| `brainstorming` | Validar ideias/design antes de implementar features | critical | instalar |

### Observação sobre níveis de risco (AAS)

- `safe`/`none`: conteúdo padrão, revisão automatizada suficiente.
- `critical`: a curadoria do AAS marca como "revisar antes de usar" (pode alterar comportamento do agente de forma ampla).
  Leia o `SKILL.md` antes de ativar e use `--dry-run` na instalação.

## 2. Instalação das skills que faltam

```bash
# 1) Pré-visualizar (não instala nada)
npx agentic-awesome-skills --path .agents/skills \
  --skills flutter-expert,dart,android-dev,unit-testing-test-generate,i18n-localization,github-actions-debugger,error-detective,brainstorming \
  --dry-run

# 2) Instalar após revisar o preview (remova --dry-run)
npx agentic-awesome-skills --path .agents/skills \
  --skills flutter-expert,dart,android-dev,unit-testing-test-generate,i18n-localization,github-actions-debugger,error-detective,brainstorming
```

- Para instalar globalmente (disponível em todos os projetos), troque o caminho: `--path ~/.config/opencode/skills`.
- Pin de versão opcional: `--release 19.9.0`.
- Catálogo completo: [`CATALOG.md`](https://github.com/sickn33/agentic-awesome-skills/blob/main/CATALOG.md) ou [aaskills.tech](https://aaskills.tech/).
- No OpenCode, peça explicitamente quando quiser uma skill: "Use a skill `flutter-expert` para ...".

---

## 3. Template de Prompt (padrão do projeto)

Copie o bloco abaixo e preencha os campos `<...>`. As seções fixas podem ser mantidas como estão.
O template já solicita, ao final, uma tentativa de compilação do APK para validar o estado atual do projeto.

```markdown
# PAPEL
Você é um(a) engenheiro(a) de software sênior especialista em Flutter/Dart para apps mobile (Android e iOS),
com domínio de Riverpod, Freezed, go_router e integração com APIs REST/WebSocket.

# CONTEXTO DO PROJETO
- Mobileraker: app Flutter open-source para controlar impressoras 3D (Klipper/Moonraker).
- Stack: Flutter 3.x/Dart 3.x, Riverpod + flutter_hooks, Freezed/json_serializable, go_router,
  Firebase (Analytics/Crashlytics/Remote Config), easy_localization (assets/translations/*.yaml),
  pacote interno common/ (data/network/service).
- Estrutura: telas em lib/ui/screens/<feature>, componentes em lib/ui/components,
  rede/serviços em common/lib/network, testes em test/unit.
- Padrões: seguir o estilo do código existente; rodar flutter analyze + flutter test;
  preservar compatibilidade Android e iOS.
- Build Android: `flutter build apk --release` no CI (.github/workflows/build-Android.yml);
  exige Java 17 + Flutter 3.44.4, pacote local `mobileraker_pro` (repo privado em ../mobileraker_pro)
  e arquivos de ambiente gerados por secrets (google-services.json, key.properties, gps.jks,
  lib/firebase_options.dart, lib/license.dart).
- Áreas afetadas: <arquivos ou pastas que você já conhece>

# TAREFA
<Uma única tarefa clara e verificável. Ex.: "Corrigir...", "Adicionar...", "Refatorar...">

# REQUISITOS E RESTRIÇÕES
- Comportamento esperado: <...>
- <Regras de negócio / detalhes técnicos>
- Não alterar: <o que está fora do escopo>
- Não adicionar dependências novas sem justificar a necessidade
- Textos visíveis ao usuário: atualizar chaves em assets/translations/*.yaml (base: en.yaml)

# PROCESSO
1. Investigue primeiro o código relevante e apresente um plano curto antes de editar.
2. Implemente em passos pequenos; explique decisões não óbvias.
3. Se algo estiver ambíguo, pergunte antes de assumir.
4. (Para bugs) Não proponha correção antes de identificar a causa raiz; apresente evidências (logs, stack trace, teste que reproduz).
5. Antes de finalizar, execute a tentativa de compilação descrita em "# COMPILAÇÃO (validação no estado atual)".

# COMPILAÇÃO (validação no estado atual) — obrigatório
- Faça uma tentativa de compilação no estado atual do projeto para verificar se é possível gerar um APK:
  `flutter build apk --debug` (use `--release` para paridade com o CI).
- Reporte o resultado com evidência:
  - ✅ APK gerado: informe o caminho do artefato (build/app/outputs/flutter-apk/) e o comando usado.
  - ❌ Falha: informe a etapa que falhou (pub get / build_runner / Gradle), a mensagem de erro exata e o que falta
    no ambiente ou no projeto (ex.: pacote mobileraker_pro privado, google-services.json, key.properties).
- Não corrija problemas pré-existentes de build por conta própria: liste o que são e peça confirmação antes.

# CRITÉRIOS DE ACEITE (verificação)
- flutter analyze sem novos issues
- flutter test passando (criar/ajustar testes do comportamento novo quando aplicável)
- Tentativa de compilação executada (flutter build apk) com resultado reportado (sucesso + caminho do APK, ou erro exato + pré-requisitos ausentes)
- <critério específico observável: ex. "tela X reflete o estado Y após o evento Z">

# FORMATO DA RESPOSTA
1. Resumo do que foi feito (curto)
2. Plano executado e decisões/trade-offs
3. Arquivos alterados (lista)
4. Evidência de verificação: comandos executados + resultado (incluindo a tentativa de compilação/APK)
5. Riscos, limitações e pendências

# AUTO-CHECAGEM FINAL
Antes de encerrar, valide: a solução atende aos critérios de aceite? Funciona em Android e iOS?
Segue os padrões do projeto? Algo não foi verificado ou ficou fora do escopo?
```

### Exemplo preenchido (resumido)

```markdown
# TAREFA
Corrigir: ao pausar um trabalho, o botão "Retomar" na tela de overview permanece desabilitado
até o usuário trocar de tela e voltar.

# REQUISITOS E RESTRIÇÕES
- O botão deve refletir o status `paused` recebido do Moonraker via WebSocket, em tempo real.
- Não alterar a lógica de envio de comandos; apenas a atualização de estado da UI.
- Áreas afetadas: lib/ui/screens/overview (estado via Riverpod) e mapeamento em common/lib/data.

# CRITÉRIOS DE ACEITE
- Ao pausar e retomar impressão, o botão habilita/desabilita imediatamente, sem trocar de tela.
- Teste do provider cobrindo a transição printing -> paused -> printing.
- Tentativa de compilação (flutter build apk --debug) executada e resultado reportado.
```

---

## 4. Dicas rápidas

- **Tarefa simples** (ex.: renomear campo, ajustar texto): use só `# TAREFA` + `# CRITÉRIOS DE ACEITE` + `# FORMATO DA RESPOSTA`.
- **Bug**: acrescente a linha 4 do `# PROCESSO` e referencie a skill `systematic-debugging`.
- **Feature nova**: rode antes a skill `brainstorming` e/ou `concise-planning` para validar o design.
- **Antes de merge**: peça revisão com `code-review-checklist` ou `five-axis-code-review`.
- **Traduções**: `i18n-localization` ajuda a detectar strings fora do YAML e chaves órfãs.
- **Compilação**: o template já solicita a tentativa de geração do APK. Se faltar algum pré-requisito (ex.: pacote
  `mobileraker_pro` privado, `google-services.json`), o correto é o agente reportar exatamente o que falta — sem
  "consertar" o build por conta própria.
