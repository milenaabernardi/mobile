# Agenda de Contatos — Flutter + SQLite

Projeto reconstruído a partir do PDF da aula **Agenda de Contatos com Flutter e SQLite**.

## Funcionalidades implementadas

- SQLite local com `sqflite`.
- CRUD completo: criar, listar, editar e excluir contatos.
- Singleton + lazy initialization no `ContactHelper`.
- Foto do contato pela **câmera** ou pela **galeria** com `image_picker`; a imagem é copiada para a pasta
  de documentos do app (não se perde quando o cache é limpo) e exibida na lista e na tela do contato.
- **E-mail**: formatação em tempo real (minúsculas, sem espaços, só caracteres válidos, um único `@`) e
  validação antes de salvar, com mensagem de erro (`lib/utils/email_utils.dart`).
- **Endereço por CEP** com a API [ViaCEP](https://viacep.com.br): ao digitar os 8 dígitos (ou tocar na lupa)
  preenche Logradouro, Bairro, Cidade e UF; Número e Complemento são digitados pelo usuário
  (`lib/services/cep_service.dart`). Banco migrado para a versão 2 sem perder contatos antigos.
- Ligação pelo discador do aparelho com `url_launcher`.
- Ordenação A-Z e Z-A.
- Máscara de telefone `(##) #####-####`.
- Validação de nome obrigatório.
- BottomSheet com Ligar, Editar e Excluir.
- Interface baseada na estrutura apresentada na aula.

> Sincronização com nuvem e busca continuam fora do escopo desta atividade.

## Como executar

### 1. Verificar o Flutter

```powershell
flutter doctor
```

### 2. Baixar dependências

Na pasta do projeto:

```powershell
flutter pub get
```

### 3. Conectar um celular Android ou iniciar um emulador

```powershell
flutter devices
```

### 4. Executar

```powershell
flutter run
```

### 5. Gerar APK de release

```powershell
flutter build apk --release
```

O APK normalmente será criado em:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Para gerar um APK por ABI:

```powershell
flutter build apk --split-per-abi
```

## Se o projeto vier apenas com `lib/`, `pubspec.yaml` e `assets/`

Caso o Flutter reclame da ausência da pasta Android, dentro da raiz do projeto execute uma vez:

```powershell
flutter create .
```

Depois:

```powershell
flutter pub get
flutter run
```

O comando preserva os arquivos Dart do projeto e cria os arquivos de plataforma necessários.
