class StringUtils {
  static String removeDiacritics(String str) {
    const withDia = 'àáãạảăằắẵặẳâầấẫậẩđèéẽẹẻêềếễệểìíĩịỉòóõọỏôồốỗộổơờớỡợởùúũụủưừứữựửỳýỹỵỷÀÁÃẠẢĂẰẮẴẶẲÂẦẤẪẬẨĐÈÉẼẸẺÊỀẾỄỆỂÌÍĨỊỈÒÓÕỌỎÔỒỐỖỘỔƠỜỚỠỢỞÙÚŨỤỦƯỪỨỮỰỬỲÝỸỴỶ';
    const withoutDia = 'aaaaaaaaaaaaaaaaadeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyAAAAAAAAAAAAAAAAADEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYY';
    
    String result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }
}
