// 📄 lib/utils/fare_calculator.dart

// No special imports needed unless you want to extend later.

String calculateFare(String pickupLocation, String destination, String? pickupCampusCategory, String? destinationCampusCategory) {
  pickupLocation = pickupLocation.trim();
  destination = destination.trim();

  // 🔥 CASE 1: Inside campus (Upper to Upper, or Lower to Lower)
  if ((pickupCampusCategory == 'Upper Campus' && destinationCampusCategory == 'Upper Campus') ||
      (pickupCampusCategory == 'Lower Campus' && destinationCampusCategory == 'Lower Campus')) {
    return '10'; // ₱10
  }

  // 🔥 CASE 2: Crossing between Upper and Lower
  if ((pickupCampusCategory == 'Upper Campus' && destinationCampusCategory == 'Lower Campus') ||
      (pickupCampusCategory == 'Lower Campus' && destinationCampusCategory == 'Upper Campus')) {
    return '15'; // ₱15
  }

  // 🔥 CASE 3: From Outside going to Campus
  if (pickupCampusCategory == 'Outside' && 
      (destinationCampusCategory == 'Upper Campus' || destinationCampusCategory == 'Lower Campus')) {
    return _fareFromOutside(pickupLocation);
  }

  // 🔥 CASE 4: From Campus going to Outside
  if ((pickupCampusCategory == 'Upper Campus' || pickupCampusCategory == 'Lower Campus') && 
      destinationCampusCategory == 'Outside') {
    return _fareFromOutside(destination);
  }

  // 🔥 CASE 5: Outside to Outside
  if (pickupCampusCategory == 'Outside' && destinationCampusCategory == 'Outside') {
    return _fareOutsideToOutside(pickupLocation, destination);
  }

  // 🔥 Default fallback (if missing categories)
  return '0';
}

String _fareFromOutside(String place) {
  place = place.toLowerCase();

  if (place.contains('vsu market')) return '20';
  if (place.contains('upper utod')) return '20';
  if (place.contains('lower utod')) return '25';
  if (place.contains('lower oval')) return '20';
  if (place.contains('gabas')) return '30';
  if (place.contains('bunga')) return '50';
  if (place.contains('marcos')) return '30';
  if (place.contains('patag')) return '25';
  if (place.contains('pangasugan')) return '20';
  if (place.contains('baybay proper')) return '80';
  if (place.contains('kilim')) return '40';
  if (place.contains('san agustin')) return '40';
  if (place.contains('candadam')) return '60';
  if (place.contains('sta. cruz')) return '50';

  return '0'; // unknown place
}

String _fareOutsideToOutside(String pickup, String destination) {
  pickup = pickup.toLowerCase();
  destination = destination.toLowerCase();

  if (pickup.contains('baybay') || destination.contains('baybay')) return '80';
  if (pickup.contains('patag') || destination.contains('patag')) return '25';
  if (pickup.contains('pangasugan') || destination.contains('pangasugan')) return '20';
  if (pickup.contains('gabas') || destination.contains('gabas')) return '30';
  if (pickup.contains('kilim') || destination.contains('kilim')) return '40';
  if (pickup.contains('san agustin') || destination.contains('san agustin')) return '40';
  if (pickup.contains('candadam') || destination.contains('candadam')) return '60';
  if (pickup.contains('sta. cruz') || destination.contains('sta. cruz')) return '50';

  return '0';
}
