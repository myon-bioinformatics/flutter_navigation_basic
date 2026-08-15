class IronyEntry {
  const IronyEntry({required this.text, required this.tone});

  final String text;
  final String tone;
}

class Ironies {
  static const List<IronyEntry> entries = [
    IronyEntry(text: 'Humans automate everything, then schedule meetings to discuss the automation.', tone: 'Tech'),
    IronyEntry(text: 'The strongest password is usually defeated by the person holding it.', tone: 'Tech'),
    IronyEntry(text: 'We built instant messaging so everyone could wait longer for a reply.', tone: 'Tech'),
    IronyEntry(text: 'Software saves time until the update starts.', tone: 'Tech'),
    IronyEntry(text: 'The cloud is just someone else’s computer with better branding.', tone: 'Tech'),
    IronyEntry(text: 'Everyone values honesty right up until the status report arrives.', tone: 'Work'),
    IronyEntry(text: 'The shortest meeting is the one that was replaced by an email.', tone: 'Work'),
    IronyEntry(text: 'A deadline becomes realistic immediately after it is missed.', tone: 'Work'),
    IronyEntry(text: 'We optimize productivity by adding another productivity tool.', tone: 'Work'),
    IronyEntry(text: 'The busiest calendar often has the least room for actual work.', tone: 'Work'),
    IronyEntry(text: 'People buy smart devices so they can spend more time configuring them.', tone: 'Daily'),
    IronyEntry(text: 'Convenience is carrying five chargers for three devices.', tone: 'Daily'),
    IronyEntry(text: 'The quickest queue is always the one you did not choose.', tone: 'Daily'),
    IronyEntry(text: 'A silent notification is still checked immediately.', tone: 'Daily'),
    IronyEntry(text: 'We save things for later until later needs its own storage plan.', tone: 'Daily'),
    IronyEntry(text: 'Humans invented maps and still ask which way the station is.', tone: 'Human'),
    IronyEntry(text: 'Everyone wants a simple answer to a complicated question.', tone: 'Human'),
    IronyEntry(text: 'Experience is knowing exactly which mistake you are repeating.', tone: 'Human'),
    IronyEntry(text: 'The more choices we have, the longer we spend choosing nothing.', tone: 'Human'),
    IronyEntry(text: 'We dislike uncertainty, so we make confident predictions about it.', tone: 'Human'),
  ];

  static List<String> get tones =>
      entries.map((entry) => entry.tone).toSet().toList(growable: false);
}
