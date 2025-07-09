// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:http/http.dart' as http;
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';

// class MapaRutaPage extends StatefulWidget {
//   const MapaRutaPage({super.key});

//   @override
//   _MapaRutaPageState createState() => _MapaRutaPageState();
// }

// class _MapaRutaPageState extends State<MapaRutaPage> {
//   late GoogleMapController mapController;
//   LatLng? clientePosition;
//   LatLng? conductorPosition;
//   Set<Marker> markers = {};
//   List<LatLng> polylineCoordinates = [];
//   late PolylinePoints polylinePoints;
//   final String googleAPIKey = 'AIzaSyD93cR6yO9PolG9FmsPQhRgpNbLQTymgUY';

//   @override
//   void initState() {
//     super.initState();
//     _obtenerUbicacionConductor();
//     polylinePoints = PolylinePoints();
//   }

//   Future<void> _obtenerUbicacionConductor() async {
//     Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       conductorPosition = LatLng(position.latitude, position.longitude);
//       markers.add(Marker(markerId: MarkerId("conductor"), position: conductorPosition!, infoWindow: InfoWindow(title: "Tú")));
//     });
//   }

//   void _marcarCliente(LatLng position) async {
//     setState(() {
//       clientePosition = position;
//       markers.add(Marker(markerId: MarkerId("cliente"), position: position, infoWindow: InfoWindow(title: "Cliente")));
//     });

//     if (conductorPosition != null && clientePosition != null) {
//       await _calcularRuta();
//     }
//   }

//   Future<void> _calcularRuta() async {
//     final origin = '${conductorPosition!.latitude},${conductorPosition!.longitude}';
//     final destination = '${clientePosition!.latitude},${clientePosition!.longitude}';
//     final url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$googleAPIKey';

//     final response = await http.get(Uri.parse(url));
//     final data = json.decode(response.body);

//     if (data['routes'].isNotEmpty) {
//       final points = data['routes'][0]['overview_polyline']['points'];
//       final List<PointLatLng> result = polylinePoints.decodePolyline(points);

//       polylineCoordinates.clear();
//       for (var point in result) {
//         polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       }

//       setState(() {});
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Ruta Cliente - Conductor')),
//       body: conductorPosition == null
//           ? Center(child: CircularProgressIndicator())
//           : GoogleMap(
//               initialCameraPosition: CameraPosition(target: conductorPosition!, zoom: 14),
//               markers: markers,
//               polylines: {
//                 Polyline(
//                   polylineId: PolylineId("ruta"),
//                   points: polylineCoordinates,
//                   color: Colors.blue,
//                   width: 5,
//                 )
//               },
//               onMapCreated: (controller) => mapController = controller,
//               onTap: _marcarCliente, // Tap para simular al cliente
//               myLocationEnabled: true,
//             ),
//     );
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaRutaPage extends StatefulWidget {
  const MapaRutaPage({super.key});

  @override
  _MapaRutaPageState createState() => _MapaRutaPageState();
}

class _MapaRutaPageState extends State<MapaRutaPage> {
  late GoogleMapController mapController;
  LatLng? conductorPosition;
  Set<Marker> markers = {};
  List<LatLng> polylineCoordinates = [];
  List<LatLng> clientes = [];

  late PolylinePoints polylinePoints;
  final String googleAPIKey = 'AIzaSyD93cR6yO9PolG9FmsPQhRgpNbLQTymgUY'; // Cambia esto por tu API KEY

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionConductor().then((_) => _obtenerClientes());
    polylinePoints = PolylinePoints();
  }

  Future<void> _obtenerUbicacionConductor() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      conductorPosition = LatLng(position.latitude, position.longitude);
      markers.add(Marker(
        markerId: MarkerId("conductor"),
        position: conductorPosition!,
        infoWindow: InfoWindow(title: "Tú"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    });
  }

  // Future<void> _obtenerClientes() async {
  //   final snapshot = await FirebaseFirestore.instance.collection('clientes').get();
  //   for (var doc in snapshot.docs) {
  //     final data = doc.data();
  //     final LatLng position = LatLng(data['latitud'], data['longitud']);
  //     clientes.add(position);
  //     markers.add(Marker(
  //       markerId: MarkerId(doc.id),
  //       position: position,
  //       infoWindow: InfoWindow(title: "Cliente"),
  //       icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  //     ));
  //   }
  //   setState(() {});
  // }

  Future<void> _obtenerClientes() async {
  final snapshot = await FirebaseFirestore.instance.collection('clientes').get();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    if (data.containsKey('latitud') && data.containsKey('longitud')) {
      try {
        final double lat = (data['latitud'] as num).toDouble();
        final double lng = (data['longitud'] as num).toDouble();

        final LatLng position = LatLng(lat, lng);
        clientes.add(position);

        markers.add(Marker(
          markerId: MarkerId(doc.id),
          position: position,
          infoWindow: const InfoWindow(title: "Cliente"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      } catch (e) {
        print('Error al convertir coordenadas del documento ${doc.id}: $e');
      }
    }
  }

  setState(() {});
}


  // Future<void> _generarRutaMultipleClientes() async {
  //   if (conductorPosition == null || clientes.isEmpty) return;

  //   String waypoints = clientes.map((p) => '${p.latitude},${p.longitude}').join('|');
  //   final origin = '${conductorPosition!.latitude},${conductorPosition!.longitude}';

  //   final url =
  //       'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$origin&waypoints=optimize:true|$waypoints&key=$googleAPIKey';

  //   final response = await http.get(Uri.parse(url));
  //   final data = json.decode(response.body);

  //   if (data['routes'].isNotEmpty) {
  //     final points = data['routes'][0]['overview_polyline']['points'];
  //     final List<PointLatLng> result = polylinePoints.decodePolyline(points);

  //     polylineCoordinates.clear();
  //     for (var point in result) {
  //       polylineCoordinates.add(LatLng(point.latitude, point.longitude));
  //     }

  //     setState(() {});
  //   }
  // }

  Future<void> _generarRutaMultipleClientes() async {
  if (conductorPosition == null || clientes.isEmpty) return;

  String waypoints = clientes.map((p) => '${p.latitude},${p.longitude}').join('|');
  final origin = '${conductorPosition!.latitude},${conductorPosition!.longitude}';

  final url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$origin&waypoints=optimize:true|$waypoints&key=$googleAPIKey';

  final response = await http.get(Uri.parse(url));
  print('Google Directions API response: ${response.body}');  // Aquí imprimimos la respuesta

  final data = json.decode(response.body);

  if (data['status'] != 'OK') {
    print('Error en la API de rutas: ${data['status']} - ${data['error_message'] ?? ''}');
    return;
  }

  if (data['routes'].isNotEmpty) {
    final points = data['routes'][0]['overview_polyline']['points'];
    final List<PointLatLng> result = polylinePoints.decodePolyline(points);

    polylineCoordinates.clear();
    for (var point in result) {
      polylineCoordinates.add(LatLng(point.latitude, point.longitude));
    }

    setState(() {});
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conductor - Ruta a Clientes')),
      body: conductorPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(target: conductorPosition!, zoom: 14),
              markers: markers,
              polylines: {
                Polyline(
                  polylineId: PolylineId("ruta"),
                  points: polylineCoordinates,
                  color: Colors.blue,
                  width: 5,
                )
              },
              onMapCreated: (controller) => mapController = controller,
              myLocationEnabled: true,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generarRutaMultipleClientes,
        child: Icon(Icons.route),
        tooltip: 'Generar Ruta',
      ),
    );
  }
}

