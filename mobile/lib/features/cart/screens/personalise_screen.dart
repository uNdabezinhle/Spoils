import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../../shared/utils/currency_formatter.dart';
import '../../../shared/widgets/gift_preview_card.dart';
import '../../../shared/widgets/spoil_text_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../data/cart_repository.dart';
import '../models/cart_models.dart';
import '../models/customisation_options.dart';
import '../providers/cart_provider.dart';

class PersonaliseScreen extends ConsumerStatefulWidget {
  const PersonaliseScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<PersonaliseScreen> createState() => _PersonaliseScreenState();
}

class _PersonaliseScreenState extends ConsumerState<PersonaliseScreen> {
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  CustomisationDetails _customisation = const CustomisationDetails();
  WrappingOptionModel? _selectedWrapping;
  bool _uploadingPhoto = false;
  bool _addingToCart = false;
  String _selectedOccasion = 'birthday';

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (image == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(customisationRepositoryProvider).uploadPhoto(image.path);
      setState(() => _customisation = _customisation.copyWith(photoUrl: url));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not upload photo. Sign in and try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _applyTemplate(MessageTemplateModel template) {
    _messageController.text = template.message;
    setState(() => _customisation = _customisation.copyWith(message: template.message));
  }

  void _selectWrapping(WrappingOptionModel option) {
    setState(() {
      _selectedWrapping = option;
      _customisation = _customisation.copyWith(
        wrappingOptionId: option.id,
        wrappingName: option.name,
        ribbonColor: option.ribbonColor,
        wrappingPrice: option.price,
      );
    });
  }

  Future<void> _addToCart(int productId) async {
    if (!ref.read(authProvider).isAuthenticated) {
      context.push('/auth/login?redirect=${Uri.encodeComponent('/personalise/${widget.slug}')}');
      return;
    }

    setState(() => _addingToCart = true);
    final customisation = _customisation.copyWith(message: _messageController.text.trim());
    try {
      final ok = await ref.read(cartProvider.notifier).addToCart(
            productId: productId,
            customisation: customisation,
          );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart — go on, spoil them!')),
        );
        context.push('/cart');
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add to cart. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));
    final wrappingAsync = ref.watch(wrappingOptionsProvider);
    final templatesAsync = ref.watch(messageTemplatesProvider(_selectedOccasion));

    return Scaffold(
      appBar: AppBar(title: const Text('Personalise your gift')),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (product) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(formatZar(product.basePrice), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: SpoilColors.teal)),
              const SizedBox(height: 20),
              GiftPreviewCard(product: product, customisation: _customisation.copyWith(message: _messageController.text)),
              const SizedBox(height: 24),
              Text('Your message', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SpoilTextField(
                controller: _messageController,
                label: 'Message',
                hint: 'Write something from the heart…',
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedOccasion,
                decoration: const InputDecoration(labelText: 'Message templates'),
                items: const [
                  DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
                  DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
                  DropdownMenuItem(value: 'thank_you', child: Text('Thank you')),
                  DropdownMenuItem(value: 'just_because', child: Text('Just because')),
                ],
                onChanged: (v) => setState(() => _selectedOccasion = v!),
              ),
              templatesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (templates) => templates.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: templates
                              .map(
                                (t) => ActionChip(
                                  label: Text(t.title),
                                  onPressed: () => _applyTemplate(t),
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              Text('Add a photo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _uploadingPhoto ? null : _pickPhoto,
                icon: _uploadingPhoto
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.photo_outlined),
                label: Text(_customisation.photoUrl.isEmpty ? 'Upload a photo' : 'Change photo'),
              ),
              const SizedBox(height: 24),
              Text('Wrapping & ribbon', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              wrappingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Could not load wrapping options'),
                data: (options) => Column(
                  children: options.map((option) {
                    final selected = _selectedWrapping?.id == option.id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: selected ? SpoilColors.blush.withOpacity(0.4) : null,
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: _colorFromHex(option.ribbonColor)),
                        title: Text(option.name),
                        subtitle: Text('+ ${formatZar(option.price)}'),
                        trailing: selected ? const Icon(Icons.check_circle, color: SpoilColors.teal) : null,
                        onTap: () => _selectWrapping(option),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addingToCart ? null : () => _addToCart(product.id),
                child: _addingToCart
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add to cart'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFromHex(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return SpoilColors.gold;
    }
  }
}