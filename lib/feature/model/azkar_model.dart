class AzkarModel {
  final String? aboveContent; // لو ف كلام فوق الذكر 
  final String content; // نص الذكر نفسه
  final int repetition; // عدد مرات التكرار
  final String? fadl; // فضل الذكر لو مكتوب تحته

  AzkarModel({
    this.aboveContent,
    this.fadl,
    required this.content,
    required this.repetition,
  });
}
