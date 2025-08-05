import 'dart:io';

import 'package:SombaTeka/app/routes.dart';
import 'package:SombaTeka/data/cubits/location/fetch_paid_api_location_cubit.dart';
import 'package:SombaTeka/data/helper/widgets.dart';
import 'package:SombaTeka/ui/screens/home/home_screen.dart';

import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/app_icon.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  LocationPermissionScreenState createState() =>
      LocationPermissionScreenState();

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(builder: (_) => const LocationPermissionScreen());
  }
}

class LocationPermissionScreenState extends State<LocationPermissionScreen>
    with WidgetsBindingObserver {
  bool _openedAppSettings = false;

  @override
  void initState() {
    // _checkLocationPermission();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _openedAppSettings) {
      _openedAppSettings = false;

      // Reset the flag
      _getCurrentLocation();
      setState(() {}); // Call the method to fetch the current location
    }
  }

  Future<void> _getCurrentLocation() async {
    Widgets.showLoader(context);
    LocationPermission permission;
    try {
      // Check location permission status
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.deniedForever) {
        if (Platform.isAndroid) {
          await Geolocator.openLocationSettings();
          _getCurrentLocation();
        }
        _showLocationServiceInstructions();
      } else if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          // Handle permission not granted for while in use or always
          setDefaultLocationAndNavigate();
        } else {
          _getCurrentLocation();
        }
      } else {
        _getCurrentLocationAndNavigate();
      }
    } catch (e) {
      // Handle or log error if necessary
    }
  }

  Future<void> setDefaultLocationAndNavigate() async {
    try {
      double latitude = double.parse(Constant.defaultLatitude);
      double longitude = double.parse(Constant.defaultLongitude);


      if (Constant.mapProvider == "free_api") {

        await setLocaleIdentifier("en_US");

        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];
          if (Constant.isDemoModeOn) {
            UiUtils.setDefaultLocationValue(
                isCurrent: false, isHomeUpdate: false, context: context);
          } else {
            HiveUtils.setLocation(
              area: placemark.subLocality,
              city: placemark.locality!,
              state: placemark.administrativeArea!,
              country: placemark.country!,
              latitude: latitude,
              longitude: longitude,
            );
          }
          Widgets.hideLoder(context);
          HelperUtils.killPreviousPages(
              context, Routes.main, {"from": "login"});
        }
      } else {
        final paidCubit = context.read<PaidApiLocationDataCubit>();
        await paidCubit.fetchPaidApiLocations(lat: latitude, lng: longitude);

        final state = paidCubit.state;
        if (state is PaidApiLocationSuccess && state.locations.isNotEmpty) {
          final location = state.locations.first;

          if (Constant.isDemoModeOn) {
            UiUtils.setDefaultLocationValue(
                isCurrent: false, isHomeUpdate: false, context: context);
          } else {
            HiveUtils.setLocation(
              area: location.sublocality ?? '',
              city: location.locality ?? location.name,
              state: location.state ?? '',
              country: location.country ?? '',
              latitude: latitude,
              longitude: longitude,
            );
          }
          Widgets.hideLoder(context);
          HelperUtils.killPreviousPages(
              context, Routes.main, {"from": "login"});
        }
      }
    } catch (e) {
      // Optionally handle errors, log or show snackbar
    }
  }

  void _showLocationServiceInstructions() {
    HelperUtils.showSnackBarMessage(
      context,
      'pleaseEnableLocationServicesManually'.translate(context),
      snackBarAction: SnackBarAction(
        label: 'ok'.translate(context),
        textColor: context.color.secondaryColor,
        onPressed: () {
          openAppSettings();
          setState(() {
            _openedAppSettings = true;
          });

          // Optionally handle action button press
        },
      ),
    );
  }

  Future<void> _getCurrentLocationAndNavigate() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (Constant.mapProvider == "free_api") {
        await setLocaleIdentifier("en_US");

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks[0];
          if (Constant.isDemoModeOn) {
            UiUtils.setDefaultLocationValue(
                isCurrent: false, isHomeUpdate: false, context: context);
          } else {
            HiveUtils.setLocation(
              area: placemark.subLocality,
              city: placemark.locality!,
              state: placemark.administrativeArea!,
              country: placemark.country!,
              latitude: position.latitude,
              longitude: position.longitude,
            );
          }

          HelperUtils.killPreviousPages(
              context, Routes.main, {"from": "login"});
        }
      } else {
        final paidCubit = context.read<PaidApiLocationDataCubit>();
        await paidCubit.fetchPaidApiLocations(
            lat: position.latitude, lng: position.longitude);

        final state = paidCubit.state;
        if (state is PaidApiLocationSuccess && state.locations.isNotEmpty) {
          final location = state.locations.first;

          if (Constant.isDemoModeOn) {
            UiUtils.setDefaultLocationValue(
              isCurrent: false,
              isHomeUpdate: false,
              context: context,
            );
          } else {
            HiveUtils.setLocation(
              area: location.sublocality ?? '',
              city: location.locality ?? location.name,
              state: location.state ?? '',
              country: location.country ?? '',
              latitude: position.latitude,
              longitude: position.longitude,
            );
          }

          HelperUtils.killPreviousPages(
              context, Routes.main, {"from": "login"});
          return;
        }
      }
    } catch (e) {
      // Handle or log error if necessary
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.backgroundColor,
      ),
      child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          body: Stack(
            children: [
              // Skip button at the top-right
              Positioned(
                top: MediaQuery.of(context).padding.top,
                right: sidePadding,
                child: FittedBox(
                  fit: BoxFit.none,
                  child: MaterialButton(
                    onPressed: () {
                      HelperUtils.killPreviousPages(
                          context, Routes.main, {"from": "login"});
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    color: context.color.forthColor.withValues(alpha: 0.102),
                    elevation: 0,
                    height: 28,
                    minWidth: 64,
                    child: CustomText(
                      "skip".translate(context),
                      color: context.color.forthColor,
                    ),
                  ),
                ),
              ),

              // Centered content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 25),
                    UiUtils.getSvg(AppIcons.locationAccessIcon),
                    const SizedBox(height: 19),
                    CustomText(
                      "whatsYourLocation".translate(context),
                      fontSize: context.font.extraLarge,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomText(
                        'enjoyPersonalizedSellingAndBuyingLocationLbl'
                            .translate(context),
                        fontSize: context.font.larger,
                        color: context.color.textDefaultColor
                            .withValues(alpha: 0.65),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 58),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 12),
                      child: UiUtils.buildButton(
                        context,
                        showElevation: false,
                        buttonColor: context.color.territoryColor,
                        textColor: context.color.secondaryColor,
                        onPressed: _getCurrentLocation,
                        radius: 8,
                        height: 46,
                        buttonTitle: "findMyLocation".translate(context),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 12),
                      child: UiUtils.buildButton(
                        context,
                        showElevation: false,
                        buttonColor: context.color.backgroundColor,
                        border: BorderSide(color: context.color.territoryColor),
                        textColor: context.color.territoryColor,
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.countriesScreen,
                              arguments: {"from": "location"});
                        },
                        radius: 8,
                        height: 46,
                        buttonTitle: "otherLocation".translate(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
