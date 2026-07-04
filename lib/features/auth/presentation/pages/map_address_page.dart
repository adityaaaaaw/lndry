import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

import '../../../../core/network/network.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../models/models.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../config/env.dart';

class MapAddressPage extends ConsumerStatefulWidget {
  const MapAddressPage({super.key});

  @override
  ConsumerState<MapAddressPage> createState() => _MapAddressPageState();
}

class _MapAddressPageState extends ConsumerState<MapAddressPage> {
  static const _initialCamera = gm.CameraPosition(
    target: gm.LatLng(20.5937, 78.9629),
    zoom: 4.8,
  );

  final _searchController = TextEditingController();
  final _addressLineController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  Timer? _searchDebounce;
  gm.GoogleMapController? _mapController;
  gm.LatLng? _pinPosition;
  String _selectedCity = '';
  String _selectedState = '';
  String _formattedAddress = '';
  AddressType _selectedType = AddressType.home;
  bool _isLoading = false;
  bool _isFetchingLocation = false;
  bool _isSearching = false;
  bool _locationPermissionGranted = false;
  List<_PlaceSuggestion> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_moveToCurrentLocation());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _addressLineController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Dio get _dio => ref.read(dioClientProvider);

  Map<String, dynamic> _dataMap(Response<dynamic> response) {
    final body = response.data as Map<String, dynamic>? ?? {};
    return body['data'] as Map<String, dynamic>? ?? {};
  }

  List<dynamic> _dataList(Response<dynamic> response) {
    final body = response.data as Map<String, dynamic>? ?? {};
    return body['data'] as List<dynamic>? ?? const [];
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() => _suggestions = const []);
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_loadSuggestions(query));
    });
  }

  Future<void> _loadSuggestions(String query) async {
    setState(() => _isSearching = true);
    try {
      final response = await _dio.get<dynamic>(
        '/maps/place-autocomplete',
        queryParameters: {
          'query': query,
          if (_pinPosition != null)
            'location_bias':
                '${_pinPosition!.latitude},${_pinPosition!.longitude}',
        },
      );
      final suggestions = _dataList(response)
          .map((e) => _PlaceSuggestion.fromJson(e as Map<String, dynamic>))
          .where((s) => !s.placeId.startsWith('mock_place_'))
          .toList();
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not load address suggestions.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = const [];
      _searchController.text = suggestion.description;
      _isLoading = true;
    });

    try {
      final response =
          await _dio.get<dynamic>('/maps/place-details/${suggestion.placeId}');
      final details = _dataMap(response);
      final lat = (details['lat'] as num?)?.toDouble();
      final lng = (details['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        throw const FormatException('Selected place is missing coordinates.');
      }

      final next = gm.LatLng(lat, lng);
      _formattedAddress =
          details['formatted_address'] as String? ?? suggestion.description;
      final postalCode = details['postal_code'] as String?;
      if (postalCode != null && postalCode.isNotEmpty) {
        _pincodeController.text = postalCode;
      }

      await _setPin(next, zoom: 17);
      await _reverseGeocode(next);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not resolve this address.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppSnackBar.showError(context, 'Please enable location services.');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppSnackBar.showError(
            context,
            'Location permission is required to use current location.',
          );
        }
        return;
      }

      _locationPermissionGranted = true;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final next = gm.LatLng(position.latitude, position.longitude);
      await _setPin(next, zoom: 17);
      await _reverseGeocode(next);
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not fetch current location.');
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _setPin(gm.LatLng position, {double? zoom}) async {
    setState(() => _pinPosition = position);
    final controller = _mapController;
    if (controller != null) {
      await controller.animateCamera(
        gm.CameraUpdate.newCameraPosition(
          gm.CameraPosition(target: position, zoom: zoom ?? 16),
        ),
      );
    }
  }

  Future<void> _reverseGeocode(gm.LatLng position) async {
    try {
      final places = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty || !mounted) return;

      final place = places.first;
      setState(() {
        _selectedCity = place.locality?.isNotEmpty == true
            ? place.locality!
            : (place.subAdministrativeArea ?? '');
        _selectedState = place.administrativeArea ?? '';
        if (_pincodeController.text.trim().isEmpty &&
            place.postalCode?.isNotEmpty == true) {
          _pincodeController.text = place.postalCode!;
        }
        if (_formattedAddress.isEmpty) {
          _formattedAddress = [
            place.name,
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
        }
      });
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, 'Could not read address from map pin.');
      }
    }
  }

  Future<bool> _validateBackendServiceability(gm.LatLng position) async {
    final locationResponse = await _dio.post<dynamic>(
      ApiEndpoints.validateLocation,
      data: {
        'lat': position.latitude,
        'lng': position.longitude,
      },
    );
    final locationData = _dataMap(locationResponse);
    final serviceable = locationData['serviceable'] as bool? ?? false;
    if (!serviceable) return false;

    final pincodeResponse = await _dio.post<dynamic>(
      ApiEndpoints.validatePincode,
      data: {'pincode': _pincodeController.text.trim()},
    );
    final pincodeData = _dataMap(pincodeResponse);
    return pincodeData['available'] as bool? ?? false;
  }

  Future<void> _onSaveAddress() async {
    final line1 = _addressLineController.text.trim();
    final pincode = _pincodeController.text.trim();
    final pin = _pinPosition;

    if (pin == null) {
      AppSnackBar.showError(context, 'Please select your exact map location.');
      return;
    }
    if (line1.isEmpty || pincode.isEmpty) {
      AppSnackBar.showError(context, 'Please complete the address details.');
      return;
    }
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode)) {
      AppSnackBar.showError(context, 'Please enter a valid 6 digit pincode.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (!Env.demoMode) {
        final isServiceable = await _validateBackendServiceability(pin);
        if (!isServiceable) {
          if (mounted) {
            AppSnackBar.showError(
              context,
              'LNDRY is not serviceable at this address yet.',
            );
          }
          return;
        }
      }

      final user = ref.read(currentUserProvider);
      final address = AddressModel(
        id: '',
        userId: user?.id ?? '',
        line1: line1,
        line2: _formattedAddress.isNotEmpty ? _formattedAddress : null,
        city: _selectedCity.isNotEmpty ? _selectedCity : 'Unknown',
        state: _selectedState.isNotEmpty ? _selectedState : 'Unknown',
        pincode: pincode,
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        type: _selectedType,
        isDefault: true,
        coordinates: LatLng(
          latitude: pin.latitude,
          longitude: pin.longitude,
        ),
      );

      await ref.read(authProvider.notifier).completeAddressSelection(address);

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Address saved as default.');
        context.go(AppRoutes.home);
      }
    } on DioException catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          e.response?.data is Map<String, dynamic>
              ? ((e.response!.data as Map<String, dynamic>)['message']
                      as String? ??
                  'Failed to save address.')
              : 'Failed to save address.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save address.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title:
            Text('Select Delivery Location', style: AppTypography.titleLarge),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  gm.GoogleMap(
                    initialCameraPosition: _initialCamera,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: _locationPermissionGranted,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    markers: {
                      if (_pinPosition != null)
                        gm.Marker(
                          markerId: const gm.MarkerId('selected_address'),
                          position: _pinPosition!,
                          draggable: true,
                          onDragEnd: (position) async {
                            await _setPin(position);
                            await _reverseGeocode(position);
                          },
                        ),
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onLongPress: (position) async {
                      await _setPin(position);
                      await _reverseGeocode(position);
                    },
                    onTap: (position) async {
                      await _setPin(position);
                      await _reverseGeocode(position);
                    },
                  ),
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    top: 16.h,
                    child: Column(
                      children: [
                        Material(
                          elevation: 6,
                          borderRadius:
                              BorderRadius.circular(AppRadius.input.r),
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search address, building or area',
                              prefixIcon: const Icon(AppIcons.search),
                              suffixIcon: _isSearching
                                  ? Padding(
                                      padding: EdgeInsets.all(14.r),
                                      child: SizedBox(
                                        width: 16.r,
                                        height: 16.r,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(AppIcons.close),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(
                                          () => _suggestions = const [],
                                        );
                                      },
                                    ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.input.r),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.surface,
                            ),
                          ),
                        ),
                        if (_suggestions.isNotEmpty)
                          Container(
                            margin: EdgeInsets.only(top: 8.h),
                            constraints: BoxConstraints(maxHeight: 220.h),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card.r),
                              boxShadow: AppElevation.medium,
                            ),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final suggestion = _suggestions[index];
                                return ListTile(
                                  leading:
                                      const Icon(AppIcons.locationOutlined),
                                  title: Text(
                                    suggestion.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium,
                                  ),
                                  onTap: () => _selectSuggestion(suggestion),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16.w,
                    bottom: 16.h,
                    child: FloatingActionButton.small(
                      heroTag: 'current_location',
                      onPressed:
                          _isFetchingLocation ? null : _moveToCurrentLocation,
                      backgroundColor:
                          isDark ? AppColors.darkSurface : AppColors.surface,
                      foregroundColor: AppColors.primary,
                      child: _isFetchingLocation
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(AppIcons.location),
                    ),
                  ),
                ],
              ),
            ),
            _AddressForm(
              addressLineController: _addressLineController,
              pincodeController: _pincodeController,
              landmarkController: _landmarkController,
              selectedType: _selectedType,
              formattedAddress: _formattedAddress,
              city: _selectedCity,
              stateName: _selectedState,
              isLoading: _isLoading,
              onTypeChanged: (type) => setState(() => _selectedType = type),
              onSave: _onSaveAddress,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressForm extends StatelessWidget {
  const _AddressForm({
    required this.addressLineController,
    required this.pincodeController,
    required this.landmarkController,
    required this.selectedType,
    required this.formattedAddress,
    required this.city,
    required this.stateName,
    required this.isLoading,
    required this.onTypeChanged,
    required this.onSave,
  });

  final TextEditingController addressLineController;
  final TextEditingController pincodeController;
  final TextEditingController landmarkController;
  final AddressType selectedType;
  final String formattedAddress;
  final String city;
  final String stateName;
  final bool isLoading;
  final ValueChanged<AddressType> onTypeChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePaddingH.w,
        vertical: AppSpacing.pagePaddingV.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.dialog.r),
        ),
        boxShadow: AppElevation.high,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Confirm Location Details', style: AppTypography.titleMedium),
            if (formattedAddress.isNotEmpty) ...[
              const Gap(8),
              Text(
                formattedAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (city.isNotEmpty || stateName.isNotEmpty) ...[
              const Gap(4),
              Text(
                [city, stateName]
                    .where((part) => part.trim().isNotEmpty)
                    .join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const Gap(16),
            AppTextField(
              label: 'Flat / Building / House No.',
              hint: 'Enter your flat/house details',
              controller: addressLineController,
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Pincode',
                    hint: '6 digits',
                    controller: pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: AppTextField(
                    label: 'Landmark',
                    hint: 'Near park',
                    controller: landmarkController,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text('Save Address As', style: AppTypography.labelMedium),
            const Gap(8),
            Row(
              children: [
                _TypeButton(
                  label: 'Home',
                  icon: AppIcons.homeOutlined,
                  isSelected: selectedType == AddressType.home,
                  onTap: () => onTypeChanged(AddressType.home),
                ),
                const Gap(12),
                _TypeButton(
                  label: 'Work',
                  icon: AppIcons.store,
                  isSelected: selectedType == AddressType.work,
                  onTap: () => onTypeChanged(AddressType.work),
                ),
                const Gap(12),
                _TypeButton(
                  label: 'Other',
                  icon: AppIcons.locationOutlined,
                  isSelected: selectedType == AddressType.other,
                  onTap: () => onTypeChanged(AddressType.other),
                ),
              ],
            ),
            const Gap(20),
            AppButton(
              label: 'Save Default Address',
              isLoading: isLoading,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppButton.outlined(
        label: label,
        icon: Icon(
          icon,
          size: 16.r,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        foregroundColor:
            isSelected ? AppColors.primary : AppColors.textSecondary,
        onPressed: onTap,
      ),
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.description,
    required this.placeId,
  });

  factory _PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return _PlaceSuggestion(
      description: json['description'] as String? ?? '',
      placeId: json['place_id'] as String? ?? json['placeId'] as String? ?? '',
    );
  }

  final String description;
  final String placeId;
}
