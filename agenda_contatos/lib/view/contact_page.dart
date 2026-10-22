import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../database/helper/contact_helper.dart';
import '../database/model/contact_model.dart';
import '../services/cep_service.dart';
import '../utils/email_utils.dart';
import '../utils/photo_storage.dart';

const bool kEmailObrigatorio = true;

class ContactPage extends StatefulWidget {
  final Contact? contact;

  const ContactPage({super.key, this.contact});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  late Contact _editContact;
  late final String _title;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final _numberFocus = FocusNode();

  final ContactHelper _helper = ContactHelper();
  final ImagePicker _picker = ImagePicker();
  final CepService _cepService = CepService();

  bool _loadingCep = false;
  bool _saving = false;
  String? _cepError;
  String _lastSearchedCep = '';

  final phoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();

    if (widget.contact == null) {
      _editContact = Contact(name: '', email: '', phone: '', img: null);
      _title = 'Novo Contato';
    } else {
      _editContact = Contact.fromMap(widget.contact!.toMap());
      _title = _editContact.name.trim().isEmpty ? 'Contato' : _editContact.name;

      _nameController.text = _editContact.name;
      _emailController.text = _editContact.email;
      if (_editContact.phone.isNotEmpty) {
        _phoneController.text = phoneMask
            .maskText(_editContact.phone.replaceAll(RegExp(r'\D'), ''));
      }
      if (_editContact.cep.isNotEmpty) {
        _cepController.text =
            cepMask.maskText(_editContact.cep.replaceAll(RegExp(r'\D'), ''));
        _lastSearchedCep = _editContact.cep.replaceAll(RegExp(r'\D'), '');
      }
      _streetController.text = _editContact.street;
      _numberController.text = _editContact.number;
      _complementController.text = _editContact.complement;
      _neighborhoodController.text = _editContact.neighborhood;
      _cityController.text = _editContact.city;
      _stateController.text = _editContact.state;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _numberFocus.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // FOTO

  Future<void> _selectImage() async {
    final bool hasPhoto = contactPhotoProvider(_editContact.img) != null;

    bool removePhoto = false;
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto com a câmera'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Remover foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    removePhoto = true;
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    );

    if (removePhoto) {
      setState(() => _editContact.img = null);
      return;
    }

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      final savedPath = await persistPhoto(image);
      if (!mounted) return;
      setState(() => _editContact.img = savedPath);
    } catch (_) {
      _showMessage(
        source == ImageSource.camera
            ? 'Não foi possível abrir a câmera. Verifique a permissão do app.'
            : 'Não foi possível carregar a imagem.',
      );
    }
  }

  ImageProvider<Object> _avatarImage() {
    return contactPhotoProvider(_editContact.img) ??
        const AssetImage('assets/imgs/image.png');
  }

  // CEP

  void _onCepChanged(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');

    if (_cepError != null) {
      setState(() => _cepError = null);
    }

    // Consulta automática assim que o 8º dígito é digitado.
    if (digits.length == 8 && digits != _lastSearchedCep) {
      _searchCep();
    }
  }

  Future<void> _searchCep() async {
    final digits = _cepController.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 8) {
      setState(() => _cepError = 'CEP inválido. Informe os 8 dígitos.');
      return;
    }

    setState(() {
      _loadingCep = true;
      _cepError = null;
    });

    try {
      final address = await _cepService.fetchAddress(digits);
      if (!mounted) return;

      // Ignora a resposta se o usuário já trocou o CEP durante a consulta.
      final current = _cepController.text.replaceAll(RegExp(r'\D'), '');
      if (current != digits) return;

      _lastSearchedCep = digits;
      setState(() {
        _streetController.text = address.street;
        _neighborhoodController.text = address.neighborhood;
        _cityController.text = address.city;
        _stateController.text = address.state.toUpperCase();
        if (address.complement.isNotEmpty &&
            _complementController.text.trim().isEmpty) {
          _complementController.text = address.complement;
        }
      });

      if (address.street.isNotEmpty) {
        _numberFocus.requestFocus();
      }
    } on CepException catch (e) {
      if (!mounted) return;
      setState(() => _cepError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cepError = 'Erro inesperado ao consultar o CEP.');
    } finally {
      if (mounted) {
        setState(() => _loadingCep = false);
      }
    }
  }

  // SALVAR

  Future<void> _saveContact() async {
    if (_saving) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showMessage('Corrija os campos destacados antes de salvar.');
      return;
    }

    setState(() => _saving = true);

    _editContact
      ..name = _nameController.text.trim()
      ..email = _emailController.text.trim()
      ..phone = _phoneController.text.trim()
      ..cep = _cepController.text.trim()
      ..street = _streetController.text.trim()
      ..number = _numberController.text.trim()
      ..complement = _complementController.text.trim()
      ..neighborhood = _neighborhoodController.text.trim()
      ..city = _cityController.text.trim()
      ..state = _stateController.text.trim().toUpperCase();

    try {
      if (_editContact.id != null) {
        await _helper.updateContact(_editContact);
      } else {
        await _helper.saveContact(_editContact);
      }

      if (mounted) {
        Navigator.pop(context, _editContact);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showMessage('Não foi possível salvar o contato.');
      }
    }
  }

  // UI

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saving ? null : _saveContact,
        backgroundColor: Colors.blue,
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // ---- Foto
              GestureDetector(
                onTap: _selectImage,
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: _avatarImage(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('Toque na foto para tirar uma foto ou escolher da galeria'),
              const SizedBox(height: 20),

              // Dados pessoais
              _sectionTitle('Dados do contato'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Nome é obrigatório!'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'nome@dominio.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                inputFormatters: [EmailInputFormatter()],
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (!kEmailObrigatorio && (value ?? '').trim().isEmpty) {
                    return null;
                  }
                  return validateEmail(value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [phoneMask],
              ),
              const SizedBox(height: 28),

              // Endereço
              _sectionTitle('Endereço'),
              TextFormField(
                controller: _cepController,
                decoration: InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                  errorText: _cepError,
                  suffixIcon: _loadingCep
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      : IconButton(
                          tooltip: 'Buscar endereço pelo CEP',
                          icon: const Icon(Icons.search),
                          onPressed: _searchCep,
                        ),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                inputFormatters: [cepMask],
                onChanged: _onCepChanged,
                onFieldSubmitted: (_) => _searchCep(),
                validator: (value) {
                  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                  if (digits.isNotEmpty && digits.length != 8) {
                    return 'CEP incompleto. Informe os 8 dígitos.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Logradouro'),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _numberController,
                      focusNode: _numberFocus,
                      decoration: const InputDecoration(labelText: 'Número'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _complementController,
                      decoration:
                          const InputDecoration(labelText: 'Complemento'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _neighborhoodController,
                decoration: const InputDecoration(labelText: 'Bairro'),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'UF'),
                      textInputAction: TextInputAction.done,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(2),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                            text: newValue.text.toUpperCase(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
