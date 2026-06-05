String describePhotosForForeman(int count, {String? userText}) {
  if (count <= 0) return '';
  final intro = count == 1
      ? 'На фото вижу интерьер объекта.'
      : 'Просмотрел $count фото объекта.';
  final hint = userText != null && userText.trim().isNotEmpty
      ? ' Учту ваш комментарий при составлении ТЗ.'
      : ' Опишите, что хотите изменить, или уточните комнату — дополню черновик.';
  return '$intro$hint';
}

String offlineForemanReplyWithPhotos({
  required int photoCount,
  required String? userText,
}) {
  final base = describePhotosForForeman(photoCount, userText: userText);
  if (photoCount == 0) {
    return userText?.trim().isNotEmpty == true
        ? userText!.trim()
        : 'Пришлите текст или фото объекта — начну черновик ТЗ.';
  }
  return '$base\n\n'
      'Пока работаем без сервера: фото сохранены в переписке. '
      'Когда бэкенд подключён, прораб разберёт снимки детальнее.\n\n'
      'Что важнее сейчас: метраж, бюджет или сроки?';
}
