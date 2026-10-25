enum PlaceCategory {
  all,
  favorites,
  museum,
  church,
  park,
  viewpoint,
  restaurant,
  hotel,
}

class FilterOption {
  final PlaceCategory id;
  final String label;
  final String icon;

  const FilterOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const List<FilterOption> filterOptions = [
  FilterOption(id: PlaceCategory.all, label: 'Todos', icon: '🗺️'),
  FilterOption(id: PlaceCategory.favorites, label: 'Mis Favoritos', icon: '❤️'),
  FilterOption(id: PlaceCategory.museum, label: 'Museos', icon: '🏛️'),
  FilterOption(id: PlaceCategory.church, label: 'Templos', icon: '⛪'),
  FilterOption(id: PlaceCategory.park, label: 'Parques', icon: '🌳'),
  FilterOption(id: PlaceCategory.viewpoint, label: 'Miradores', icon: '📸'),
  FilterOption(id: PlaceCategory.restaurant, label: 'Comida', icon: '🌮'),
  FilterOption(id: PlaceCategory.hotel, label: 'Hospedaje', icon: '🏨'),
];