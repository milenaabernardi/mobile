# Cineboxd

Diário de filmes estilo Letterboxd, feito em Flutter. O usuário cria uma conta, busca filmes na TMDB, registra o que assistiu (com nota, data, foto e localização) e vê tudo em lista e em calendário. Funciona **offline**: os registros ficam no SQLite e são enviados ao Firebase quando a internet volta.

## Integrantes
- _Preencher com nome(s) do(s) integrante(s)_

## Objetivo
Trabalho Final de Desenvolvimento de Aplicações Mobile: aplicativo completo com autenticação, nuvem (Firestore), banco local (SQLite), offline-first, GPS, calendário, API externa e seleção de imagem.

## Tecnologias
Flutter, Dart, Firebase Authentication, Cloud Firestore, SQLite, API TMDB, API GIPHY.

## Bibliotecas
| Pacote | Uso |
|---|---|
| firebase_core, firebase_auth, cloud_firestore | Firebase, login e banco na nuvem |
| sqflite, path | Banco local SQLite |
| connectivity_plus | Detectar conexão |
| geolocator | GPS |
| table_calendar | Calendário |
| image_picker | Foto (galeria/câmera) |
| http | Consumo da TMDB e do GIPHY |
| shared_preferences | Favoritos no aparelho |
| intl, flutter_localizations | Datas e textos em português |

## Funcionalidades
- Splash, ícone próprio e tema escuro padronizado.
- Login, cadastro (nome, e-mail, senha e confirmação) e recuperação de senha (Firebase Authentication).
- Tela principal com o usuário logado e botão de sair (aba Perfil).
- **Diário**: CRUD completo (cadastrar, listar, ver detalhes, editar, excluir) com validações.
- **Offline first**: salva no SQLite, envia ao Firestore, marca como sincronizado e limpa o local; exclusões offline também são replicadas; sem duplicar (id único).
- **GPS**: permissão explicada ao usuário, latitude/longitude na tela e salvas no registro.
- **Calendário** (`table_calendar`): dias com registros marcados, registros do dia selecionado e cadastro na data escolhida.
- **API externa** (TMDB + GIPHY): busca, filmes em alta, em cartaz, em breve, detalhes, GIF e troca de pôster/backdrop.
- **Foto** por `image_picker` associada ao registro.
- Botões: FilledButton, OutlinedButton, TextButton, IconButton e FloatingActionButton.

## Estrutura
```
lib/
  main.dart, firebase_options.dart
  models/      registro_model.dart, movie.dart, movie_images.dart
  database/    local_database.dart, registro_helper.dart
  services/    auth_service, firestore_service, sync_service, registro_repository,
               connectivity_service, location_service, tmdb_service, giphy_service
  screens/     splash, login, register, forgot_password, main_shell, diario,
               registro_form, registro_details, calendar, profile, discover, search, detail
  widgets/     componentes reutilizáveis
  theme/, utils/, config/
```

## Como executar
Veja `PASSO_A_PASSO_CONFIGURACAO.md` (Firebase, chaves de API, Android e APK).
Resumo:
1. `flutter pub get`
2. Copiar `lib/config/api_keys.example.dart` para `api_keys.dart` e colocar as chaves da TMDB e do GIPHY.
3. `flutterfire configure` (gera `firebase_options.dart` e `google-services.json`).
4. `flutter run` em um emulador ou celular Android.
5. APK: `flutter build apk --release`.

## Roteiro de teste (para o professor)
1. Abrir o app, 2. criar conta, 3. fechar, 4. abrir e entrar, 5. cadastrar um registro (aba Diário, botão Registrar filme), 6. ver na lista, 7. abrir o Calendário e escolher uma data, 8. ver os registros do dia, 9. obter a localização, 10. salvá-la em um registro, 11. editar, 12. excluir, 13. conferir no Firebase Console (`users/{uid}/registros`), 14. desligar a internet, 15. cadastrar outro registro, 16. fechar e abrir o app, 17. o registro continua lá (ícone laranja), 18. ligar a internet, 19. o registro vai para o Firebase e o ícone fica verde.

## Telas
Adicione aqui os prints em `docs/telas/` (login, cadastro, diário, formulário, calendário, perfil, detalhes).
