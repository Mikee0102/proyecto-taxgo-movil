import 'package:latlong2/latlong.dart';
import 'filter_option.dart';

class _MunicipalityCoord {
  final String name;
  final double lat;
  final double lon;

  const _MunicipalityCoord(this.name, this.lat, this.lon);
}

const List<_MunicipalityCoord> _tlaxcalaMunicipalities = [
  _MunicipalityCoord('Acuamanala de Miguel Hidalgo', 19.2225, -98.2014),
  _MunicipalityCoord('Amaxac de Guerrero', 19.3497, -98.1694),
  _MunicipalityCoord('Apetatitlán de Antonio Carvajal', 19.3458, -98.1917),
  _MunicipalityCoord('Apizaco', 19.4167, -98.1375),
  _MunicipalityCoord('Atlangatepec', 19.5389, -98.1986),
  _MunicipalityCoord('Atltzayanca', 19.4314, -97.7958),
  _MunicipalityCoord('Benito Juárez', 19.5889, -98.4236),
  _MunicipalityCoord('Calpulalpan', 19.5881, -98.5686),
  _MunicipalityCoord('Chiautempan', 19.3136, -98.2206),
  _MunicipalityCoord('Contla de Juan Cuamatzi', 19.3333, -98.1667),
  _MunicipalityCoord('Cuapiaxtla', 19.2972, -97.7681),
  _MunicipalityCoord('Cuaxomulco', 19.3542, -98.1014),
  _MunicipalityCoord('El Carmen Tequexquitla', 19.3250, -97.6542),
  _MunicipalityCoord('Emiliano Zapata', 19.5583, -97.9167),
  _MunicipalityCoord('Españita', 19.4625, -98.4236),
  _MunicipalityCoord('Huamantla', 19.3139, -97.9236),
  _MunicipalityCoord('Hueyotlipan', 19.4722, -98.3472),
  _MunicipalityCoord('Ixtacuixtla de Mariano Matamoros', 19.3278, -98.3778),
  _MunicipalityCoord('Ixtenco', 19.2528, -97.8958),
  _MunicipalityCoord('La Magdalena Tlaltelulco', 19.2750, -98.1972),
  _MunicipalityCoord('Lázaro Cárdenas', 19.5361, -97.9833),
  _MunicipalityCoord('Mazatecochco de José María Morelos', 19.1806, -98.1875),
  _MunicipalityCoord('Muñoz de Domingo Arenas', 19.4750, -98.2083),
  _MunicipalityCoord('Nanacamilpa de Mariano Arista', 19.4931, -98.5361),
  _MunicipalityCoord('Natívitas', 19.2333, -98.3167),
  _MunicipalityCoord('Panotla', 19.3153, -98.2736),
  _MunicipalityCoord('Papalotla de Xicohténcatl', 19.1667, -98.2000),
  _MunicipalityCoord('San Damián Texóloc', 19.2778, -98.2833),
  _MunicipalityCoord('San Francisco Tetlanohcan', 19.2611, -98.1639),
  _MunicipalityCoord('San Jerónimo Zacualpan', 19.2417, -98.2583),
  _MunicipalityCoord('San José Teacalco', 19.3361, -98.0639),
  _MunicipalityCoord('San Juan Huactzinco', 19.2333, -98.2500),
  _MunicipalityCoord('San Lorenzo Axocomanitla', 19.2222, -98.2472),
  _MunicipalityCoord('San Lucas Tecopilco', 19.4778, -98.2611),
  _MunicipalityCoord('San Pablo del Monte', 19.1167, -98.1667),
  _MunicipalityCoord('Sanctórum de Lázaro Cárdenas', 19.4917, -98.4722),
  _MunicipalityCoord('Santa Ana Nopalucan', 19.2972, -98.3389),
  _MunicipalityCoord('Santa Apolonia Teacalco', 19.2417, -98.3083),
  _MunicipalityCoord('Santa Catarina Ayometla', 19.1972, -98.2083),
  _MunicipalityCoord('Santa Cruz Quilehtla', 19.2056, -98.2167),
  _MunicipalityCoord('Santa Cruz Tlaxcala', 19.3556, -98.1500),
  _MunicipalityCoord('Santa Isabel Xiloxoxtla', 19.2639, -98.2139),
  _MunicipalityCoord('Tenancingo', 19.1472, -98.2000),
  _MunicipalityCoord('Teolocholco', 19.2389, -98.1861),
  _MunicipalityCoord('Tepetitla de Lardizábal', 19.2667, -98.3750),
  _MunicipalityCoord('Tepeyanco', 19.2472, -98.2306),
  _MunicipalityCoord('Terrenate', 19.4778, -97.9194),
  _MunicipalityCoord('Tetla de la Solidaridad', 19.4333, -98.1000),
  _MunicipalityCoord('Tetlatlahuca', 19.2222, -98.2944),
  _MunicipalityCoord('Tlaxcala', 19.3182, -98.2375),
  _MunicipalityCoord('Tlaxco', 19.6139, -98.1194),
  _MunicipalityCoord('Tocatlán', 19.3889, -98.0278),
  _MunicipalityCoord('Totolac', 19.3278, -98.2583),
  _MunicipalityCoord('Tzompantepec', 19.3750, -98.0917),
  _MunicipalityCoord('Xaloztoc', 19.4056, -98.0472),
  _MunicipalityCoord('Xaltocan', 19.4194, -98.2083),
  _MunicipalityCoord('Xicohtzinco', 19.1750, -98.2333),
  _MunicipalityCoord('Yauhquemehcan', 19.4056, -98.1750),
  _MunicipalityCoord('Zacatelco', 19.2167, -98.2417),
  _MunicipalityCoord('Ziltlaltépec de Trinidad Sánchez Santos', 19.2028, -97.9083),
];

String resolveClosestMunicipality(LatLng location) {
  var closest = _tlaxcalaMunicipalities.first;
  var minDist = double.infinity;

  for (final mun in _tlaxcalaMunicipalities) {
    final dLat = location.latitude - mun.lat;
    final dLon = location.longitude - mun.lon;
    final dist = dLat * dLat + dLon * dLon;
    if (dist < minDist) {
      minDist = dist;
      closest = mun;
    }
  }

  return closest.name;
}

class Place {
  final String id;
  final String name;
  final PlaceCategory category;
  final LatLng location;
  final String? municipality;
  final bool isFavorite;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.municipality,
    this.isFavorite = false,
  });

  String get resolvedMunicipality =>
      (municipality != null && municipality!.trim().isNotEmpty)
          ? municipality!.trim()
          : resolveClosestMunicipality(location);
}