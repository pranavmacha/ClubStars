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

  factory ClubMail.fromJson(Map<String, dynamic> json) {
    return ClubMail(
      link: json['link'] as String,
      sender: json['sender'] as String,
      msgId: json['msg_id'] as String,
      title: json['title'] ?? 'Club Mail',
      venue: json['venue'] ?? 'N/A',
      date: json['date'] ?? 'N/A',
      time: json['time'] ?? 'N/A',
      recipient: json['recipient'] as String?,
      bannerUrl: json['banner_url'] as String?,
    );
  }
}
