import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:SombaTeka/data/cubits/location/fetch_paid_api_location_cubit.dart';
import 'package:SombaTeka/ui/screens/home/home_screen.dart';
import 'package:SombaTeka/ui/screens/item/add_item_screen/confirm_location_screen.dart';
import 'package:SombaTeka/ui/screens/location/locationHelperWidget.dart';

import 'package:SombaTeka/ui/theme/theme.dart';
import 'package:SombaTeka/utils/constant.dart';
import 'package:SombaTeka/utils/custom_text.dart';
import 'package:SombaTeka/utils/extensions/extensions.dart';
import 'package:SombaTeka/utils/helper_utils.dart';
import 'package:SombaTeka/utils/hive_utils.dart';
import 'package:SombaTeka/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyLocationScreen extends StatefulWidget {
  final String from;

  const NearbyLocationScreen({
    super.key,
    required this.from,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return MaterialPageRoute(
        builder: (context) => NearbyLocationScreen(
              from: arguments?['from'],
            ));
  }

  @override
  NearbyLocationScreenState createState() => NearbyLocationScreenState();
}

class NearbyLocationScreenState extends State<NearbyLocationScreen>
    with WidgetsBindingObserver {
  double radius = double.parse(Constant.minRadius);
  GoogleMapController? mapController;
  CameraPosition? _cameraPosition;
  final Set<Marker> _markers = Set();
  Set<Circle> circles = Set.from([]);
  var markerMove;
  bool openedAppSettings = false;
  String currentLocation = '';
  double? latitude, longitude;
  AddressComponent? formatedAddress;
  bool isMapControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    int mainRadius =
        HiveUtils.getNearbyRadius() ?? int.parse(Constant.minRadius);
    radius = mainRadius.toDouble();
    _getCurrentLocation();

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

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
        setDefaultLocation();
      } else {
        _getCurrentLocation();
      }
    } else {
      // Permission is granted, proceed to get the current location
      preFillLocationWhileEdit();
    }
  }

  Future<void> setDefaultLocation() async {
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();

    if (latitude != "" &&
        latitude != null &&
        longitude != "" &&
        longitude != null) {
      // Use values from HiveUtils
      latitude = HiveUtils.getLatitude();
      longitude = HiveUtils.getLongitude();
    } else {
      // Use default values from Constant
      latitude = double.parse(Constant.defaultLatitude);
      longitude = double.parse(Constant.defaultLongitude);
    }
    getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
    _cameraPosition = CameraPosition(
      target: LatLng(latitude!, longitude!),
      zoom: 10,
      bearing: 0,
    );
    final marker = await createCommonMarker(LatLng(latitude!, longitude!));
    _markers.add(marker);
    _addCircle(LatLng(latitude!, longitude!), radius);
    setState(() {});
  }

  void preFillLocationWhileEdit() async {
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();
    if (latitude != "" &&
        latitude != null &&
        longitude != "" &&
        longitude != null) {
      final marker = await createCommonMarker(LatLng(latitude!, longitude!));
      _markers.add(marker);
      getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));

      _addCircle(LatLng(latitude!, longitude!), radius);
      _cameraPosition = CameraPosition(
        target: LatLng(latitude!, longitude!),
        zoom: 10,
        bearing: 0,
      );

      setState(() {});
    } else {
      currentLocation = [
        HiveUtils.getCurrentAreaName(),
        HiveUtils.getCurrentCityName(),
        HiveUtils.getCurrentStateName(),
        HiveUtils.getCurrentCountryName()
      ].where((part) => part != null && part.isNotEmpty).join(', ');
      if (currentLocation == "") {
        await _updateCurrentLocation();
      } else {
        formatedAddress = AddressComponent(
            area: HiveUtils.getCurrentAreaName(),
            areaId: null,
            city: HiveUtils.getCurrentCityName(),
            country: HiveUtils.getCurrentCountryName(),
            state: HiveUtils.getCurrentStateName());
        latitude = HiveUtils.getCurrentLatitude();
        longitude = HiveUtils.getCurrentLongitude();

        final marker = await createCommonMarker(LatLng(latitude!, longitude!));
        _addCircle(LatLng(latitude!, longitude!), radius);
        _markers.add(marker);
        _cameraPosition = CameraPosition(
          target: LatLng(latitude!, longitude!),
          zoom: 10,
          bearing: 0,
        );

        getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
      }
    }

    setState(() {});
  }

  void getLocationFromLatitudeLongitude({LatLng? latLng}) async {
    try {
      final newLatitude = latLng?.latitude ?? _cameraPosition!.target.latitude;
      final newLongitude =
          latLng?.longitude ?? _cameraPosition!.target.longitude;

      if (Constant.mapProvider == "free_api") {

        await setLocaleIdentifier("en_US");
        Placemark? placeMark =
            (await placemarkFromCoordinates(newLatitude, newLongitude)).first;

        formatedAddress = AddressComponent(
            area: placeMark.subLocality,
            areaId: null,
            city: placeMark.locality,
            country: placeMark.country,
            state: placeMark.administrativeArea);


        setState(() {});
      } else {
        final paidCubit = context.read<PaidApiLocationDataCubit>();
        await paidCubit.fetchPaidApiLocations(
            lat: newLatitude, lng: newLongitude);

        final state = paidCubit.state;
        if (state is PaidApiLocationSuccess && state.locations.isNotEmpty) {
          final location = state.locations.first;
          formatedAddress = AddressComponent(
            area: location.sublocality,
            areaId: null,
            city: location.locality ?? location.name,
            country: location.country,
            state: location.state,
          );
          setState(() {});
        }
      }
    } catch (e) {
      log(e.toString());
      formatedAddress = null;
      setState(() {});
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
            openedAppSettings = true;
          });
        },
      ),
    );
  }


  void _addCircle(LatLng position, double radiusInKm) {
    if (!mounted || !isMapControllerInitialized) return;

    setState(() {
      circles.clear();
      circles.add(Circle(
        circleId: const CircleId("radius_circle"),
        center: position,
        radius: radiusInKm * 1000,
        fillColor: context.color.territoryColor.withValues(alpha: 0.2),
        strokeColor: context.color.territoryColor,
        strokeWidth: 0,
      ));
    });

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        MapUtils.createBounds(position, radiusInKm * 1000),
        50,
      ),
    );
  }

  Future<void> _updateCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high));

    _markers.clear();
    final marker =
        await createCommonMarker(LatLng(position.latitude, position.longitude));
    _markers.add(marker);

    _cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 10,
      bearing: 0,
    );

    latitude = position.latitude;
    longitude = position.longitude;
    getLocationFromLatitudeLongitude();
    _addCircle(LatLng(position.latitude, position.longitude), radius);
    if (mapController == null) return;
    Future.delayed(const Duration(milliseconds: 500)).then((value) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_cameraPosition!),
      );
    });

    setState(() {});
  }

  Widget bottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          color: context.color.backgroundColor,
          thickness: 1.5,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            spacing: 16,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: UiUtils.buildButton(context, radius: 8, fontSize: 16,
                      onPressed: () {
                setState(() {
                  radius = double.parse(Constant.minRadius);
                  _addCircle(LatLng(latitude!, longitude!), radius);
                });
              },
                      buttonTitle: "reset".translate(context),
                      height: 43,
                      border: BorderSide(color: context.color.territoryColor),
                      textColor: context.color.territoryColor,
                      buttonColor: context.color.secondaryColor)),
              Expanded(
                  child: UiUtils.buildButton(context, radius: 8, fontSize: 16,
                      onPressed: () {
                HiveUtils.setNearbyRadius(radius.toInt());
                applyOnPressed();
              },
                      buttonTitle: "apply".translate(context),
                      height: 43,
                      textColor: context.color.secondaryColor,
                      buttonColor: context.color.territoryColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void applyOnPressed() {
    if (widget.from == "home") {
      LocationHelperWidget().setDataFromHome(
        context,
        cityName: formatedAddress!.city,
        stateName: formatedAddress!.state,
        areaName: formatedAddress!.area,
        countryName: formatedAddress!.country,
        latitude: latitude,
        longitude: longitude,
        radius: radius.toInt(),
        fetchHomeLatitude: latitude,
        fetchHomeLongitude: longitude,
      );
    } else if (widget.from == "location") {
      LocationHelperWidget().setDataFromLocation(context,
          cityName: formatedAddress!.city,
          stateName: formatedAddress!.state,
          areaName: formatedAddress!.area,
          countryName: formatedAddress!.country,
          latitude: latitude,
          longitude: longitude,
          radius: radius.toInt());
    } else {
      LocationHelperWidget().setResult(context,
          cityName: formatedAddress!.city,
          stateName: formatedAddress!.state,
          areaName: formatedAddress!.area,
          countryName: formatedAddress!.country,
          latitude: latitude,
          longitude: longitude,
          radius: radius.toInt(),
          noOfPopBeforeResult: 1);
    }
  }

  Set<Factory<OneSequenceGestureRecognizer>> getMapGestureRecognizers() {
    return <Factory<OneSequenceGestureRecognizer>>{}..add(
        Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer()
              ..onDown = (dragUpdateDetails) {
                if (markerMove == false) {
                } else {
                  setState(() {
                    markerMove = false;
                  });
                }
              }));
  }

  Widget buildGoogleMap() {
    return Stack(
      children: [
        if (_cameraPosition == null)
          Center(
            child: CircularProgressIndicator(
              color: context.color.territoryColor,
            ),
          )
        else
          GoogleMap(
            onCameraMove: (position) {
              _cameraPosition = position;
            },
            onCameraIdle: () async {
              if (markerMove == false) {
                if (LatLng(latitude!, longitude!) !=
                    LatLng(_cameraPosition!.target.latitude,
                        _cameraPosition!.target.longitude)) {
                  getLocationFromLatitudeLongitude();
                }
              }
            },
            initialCameraPosition: _cameraPosition!,
            circles: circles,
            markers: _markers,
            zoomControlsEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
            compassEnabled: false,
            indoorViewEnabled: true,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              Future.delayed(const Duration(milliseconds: 500)).then((value) {
                if (!mounted) return;
                setState(() {
                  mapController = controller;
                  isMapControllerInitialized = true;
                  mapController!.animateCamera(
                    CameraUpdate.newCameraPosition(_cameraPosition!),
                  );
                  // Add initial circle once controller is ready
                  if (latitude != null && longitude != null) {
                    _addCircle(LatLng(latitude!, longitude!), radius);
                  }
                });
              });
            },
            onTap: handleMapTap,
          ),
        if (!isMapControllerInitialized)
          Center(
            child: CircularProgressIndicator(
              color: context.color.territoryColor,
            ),
          ),
      ],
    );
  }

// Add this method to create custom marker
  Future<BitmapDescriptor> createCustomMarkerIcon() async {
    final double size = 150;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()
      ..color = context.color.territoryColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw inner circle
    paint.color = context.color.territoryColor;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 8, paint);

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

// Common method for creating marker
  Future<Marker> createCommonMarker(LatLng position) async {
    final customIcon = await createCustomMarkerIcon();

    return Marker(
      markerId: const MarkerId('currentLocation'),
      position: position,
      icon: customIcon,
      anchor: const Offset(0.5, 0.5),
    );
  }

// Update the handleMapTap method
  void handleMapTap(LatLng latLng) async {
    final marker = await createCommonMarker(latLng);
    setState(() {
      _markers.clear();
      _markers.add(marker);
      latitude = latLng.latitude;
      longitude = latLng.longitude;
      getLocationFromLatitudeLongitude(latLng: latLng);
      _addCircle(LatLng(latitude!, longitude!), radius);
    });
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        extendBody: true,
        backgroundColor: context.color.secondaryColor,
        appBar: UiUtils.buildAppBar(
          context,
          showBackButton: true,
          title: "nearbyListings".translate(context),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [topWidget(), Expanded(child: bottomBar())],
        ),
      ),
    );
  }

  Widget topWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: context.color.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: sidePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Stack(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: context.color.backgroundColor),
                            height: context.screenHeight * 0.55,
                            child: buildGoogleMap())),
                    if (formatedAddress != null)
                      PositionedDirectional(
                        start: 15,
                        top: 15,
                        end: 15,
                        child: LocationDisplay(
                          address: formatedAddress!,
                          territoryColor: context.color.territoryColor,
                        ),
                      ),
                    PositionedDirectional(
                      end: 5,
                      bottom: 5,
                      child: Card(
                        child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(
                              Icons.my_location_sharp,
                              size: 30,
                            ),
                          ),
                          onTap: _updateCurrentLocation,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            children: [
              CustomText(
                'selectAreaRange'.translate(context),
                color: context.color.textDefaultColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              Spacer(),
              CustomText(
                "${radius.toInt().toString()}\t${"km".translate(context)}",
                color: context.color.textDefaultColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              )
            ],
          ),
        ),
        SizedBox(
          height: 15,
        ),
        Slider(
          value: radius,
          min: double.parse(Constant.minRadius),
          activeColor: context.color.textDefaultColor,
          inactiveColor: context.color.textLightColor.withValues(alpha: 0.1),
          max: double.parse(Constant.maxRadius),
          divisions: (double.parse(Constant.maxRadius) -
                  double.parse(Constant.minRadius))
              .toInt(),
          label: '${radius.toInt()}\t${"km".translate(context)}',
          onChanged: (value) {
            setState(() {
              radius = value;
              _addCircle(LatLng(latitude!, longitude!), radius);
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText('${Constant.minRadius}\t${"km".translate(context)}',
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.w500),
              CustomText(
                '${Constant.maxRadius}\t${"km".translate(context)}',
                color: context.color.textDefaultColor,
                fontWeight: FontWeight.w500,
              )
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class MapUtils {
  static LatLngBounds createBounds(LatLng center, double radiusInMeters) {
    final double distanceInDegrees = radiusInMeters / 111320.0;
    return LatLngBounds(
      southwest: LatLng(center.latitude - distanceInDegrees,
          center.longitude - distanceInDegrees),
      northeast: LatLng(center.latitude + distanceInDegrees,
          center.longitude + distanceInDegrees),
    );
  }

  static Circle createCircle({
    required LatLng position,
    required double radiusInKm,
    required Color fillColor,
    required Color strokeColor,
    int strokeWidth = 0,
  }) {
    return Circle(
      circleId: CircleId("radius_circle"),
      center: position,
      radius: radiusInKm * 1000,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
    );
  }
}

class LocationDisplay extends StatelessWidget {
  final AddressComponent address;
  final Color territoryColor;

  const LocationDisplay({
    required this.address,
    required this.territoryColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.color.secondaryColor),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLocationIcon(context),
            const SizedBox(width: 10),
            Expanded(child: _buildAddressText(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationIcon(BuildContext context) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: territoryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Icon(Icons.location_on_outlined, size: 20, color: territoryColor),
    );
  }

  Widget _buildAddressText(BuildContext context) {
    final addressParts = [
      if (address.area?.isNotEmpty ?? false) address.area,
      if (address.city?.isNotEmpty ?? false) address.city,
      if (address.state?.isNotEmpty ?? false) address.state,
      if (address.country?.isNotEmpty ?? false) address.country,
    ];

    return CustomText(
      addressParts.isEmpty ? "____" : addressParts.join(", "),
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      maxLines: 3,
      fontSize: context.font.normal,
      fontWeight: FontWeight.w500,
    );
  }
}
