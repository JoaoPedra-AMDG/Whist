/// Seats are listed in the direction the dealer moves: the next seat is left.
List<int> callingOrder(List<int> seats, int dealer) {
  final dealerSeat = seats.indexOf(dealer);
  if (dealerSeat < 0) {
    throw ArgumentError.value(dealer, 'dealer', 'Dealer must have a seat');
  }
  return [
    for (var offset = 1; offset <= seats.length; offset++)
      seats[(dealerSeat + offset) % seats.length],
  ];
}

int nextDealer(List<int> seats, int dealer) =>
    callingOrder(seats, dealer).first;
