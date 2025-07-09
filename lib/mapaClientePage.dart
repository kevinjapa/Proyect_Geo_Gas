import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaClientePage extends StatefulWidget {
  const MapaClientePage({super.key});

  @override
  _MapaClientePageState createState() => _MapaClientePageState();
}

class _MapaClientePageState extends State<MapaClientePage> {
  GoogleMapController? mapController;
  LatLng? _clienteUbicacion;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _clienteUbicacion = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _guardarUbicacion() async {
    if (_clienteUbicacion != null) {
      await FirebaseFirestore.instance.collection('clientes').add({
        'latitud': _clienteUbicacion!.latitude,
        'longitud': _clienteUbicacion!.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ubicación guardada correctamente.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cliente - Marcar Ubicación')),
      body: _clienteUbicacion == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: _clienteUbicacion!, zoom: 15),
                  myLocationEnabled: true,
                  onMapCreated: (controller) => mapController = controller,
                  markers: {
                    Marker(
                      markerId: MarkerId("cliente"),
                      position: _clienteUbicacion!,
                      infoWindow: InfoWindow(title: "Tu ubicación"),
                    )
                  },
                ),
                Positioned(
                  bottom: 30,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _guardarUbicacion,
                    child: Icon(Icons.add_location_alt),
                    tooltip: 'Guardar Ubicación',
                  ),
                ),
              ],
            ),
    );
  }
}
