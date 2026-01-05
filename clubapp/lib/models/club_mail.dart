class ClubMail {
  final String link;
  final String sender;
  final String msgId;
  final String title;
  final String venue;
  final String date;
  final String time;
  final String? recipient;
  final String? bannerUrl;

  ClubMail({
    required this.link,
    required this.sender,
    required this.msgId,
    required this.title,
    required this.venue,
    required this.date,
    required this.time,
    this.recipient,
    this.bannerUrl,
  });

  /// Create ClubMail from JSON with proper null-safety handling
  factory ClubMail.fromJson(Map<String, dynamic> json) {
    return ClubMail(
      link: (json['link'] as String?) ?? '',
      sender: (json['sender'] as String?) ?? 'Unknown',
      msgId: (json['msg_id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Club Mail',
      venue: (json['venue'] as String?) ?? 'N/A',
      date: (json['date'] as String?) ?? 'N/A',
      time: (json['time'] as String?) ?? 'N/A',
      recipient: json['recipient'] as String?,
      bannerUrl: json['banner_url'] as String?,
    );
  }

  /// Convert ClubMail to JSON
  Map<String, dynamic> toJson() {
    return {
      'link': link,
      'sender': sender,
      'msg_id': msgId,
      'title': title,
      'venue': venue,
      'date': date,
      'time': time,
      'recipient': recipient,
      'banner_url': bannerUrl,
    };
  }

  /// Copy with modifications
  ClubMail copyWith({
    String? link,
    String? sender,
    String? msgId,
    String? title,
    String? venue,
    String? date,
    String? time,
    String? recipient,
    String? bannerUrl,
  }) {
    return ClubMail(
      link: link ?? this.link,
      sender: sender ?? this.sender,
      msgId: msgId ?? this.msgId,
      title: title ?? this.title,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      time: time ?? this.time,
      recipient: recipient ?? this.recipient,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  @override
  String toString() {
    return 'ClubMail(title: $title, sender: $sender, date: $date, venue: $venue)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClubMail &&
          runtimeType == other.runtimeType &&
          link == other.link &&
          msgId == other.msgId;

  @override
  int get hashCode => link.hashCode ^ msgId.hashCode;
}
