package com.example.urgs_api.user.support;

import com.example.urgs_api.user.model.User;
import net.sourceforge.pinyin4j.PinyinHelper;
import net.sourceforge.pinyin4j.format.HanyuPinyinCaseType;
import net.sourceforge.pinyin4j.format.HanyuPinyinOutputFormat;
import net.sourceforge.pinyin4j.format.HanyuPinyinToneType;
import net.sourceforge.pinyin4j.format.HanyuPinyinVCharType;
import net.sourceforge.pinyin4j.format.exception.BadHanyuPinyinOutputFormatCombination;

import java.util.List;
import java.util.Locale;
import java.util.Objects;

public final class UserSearchMatcher {

    private static final HanyuPinyinOutputFormat PINYIN_FORMAT = createPinyinFormat();

    private UserSearchMatcher() {
    }

    public static List<User> filter(List<User> users, String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return users;
        }
        return users.stream()
                .filter(user -> matches(user, keyword))
                .toList();
    }

    public static boolean matches(User user, String keyword) {
        if (user == null || keyword == null || keyword.isBlank()) {
            return keyword == null || keyword.isBlank();
        }

        String normalizedKeyword = normalize(keyword);
        return contains(user.getId() == null ? null : user.getId().toString(), normalizedKeyword)
                || contains(user.getName(), normalizedKeyword)
                || contains(user.getEmpId(), normalizedKeyword)
                || contains(user.getRoleName(), normalizedKeyword)
                || contains(toFullPinyin(user.getName()), normalizedKeyword)
                || contains(toPinyinInitials(user.getName()), normalizedKeyword);
    }

    public static String toFullPinyin(String value) {
        return toPinyin(value, false);
    }

    public static String toPinyinInitials(String value) {
        return toPinyin(value, true);
    }

    private static String toPinyin(String value, boolean initialsOnly) {
        if (value == null || value.isBlank()) {
            return "";
        }

        StringBuilder result = new StringBuilder();
        for (char character : value.toCharArray()) {
            String[] pinyin;
            try {
                pinyin = PinyinHelper.toHanyuPinyinStringArray(character, PINYIN_FORMAT);
            } catch (BadHanyuPinyinOutputFormatCombination exception) {
                throw new IllegalStateException("拼音格式配置无效", exception);
            }
            if (pinyin == null || pinyin.length == 0) {
                if (Character.isLetterOrDigit(character)) {
                    result.append(Character.toLowerCase(character));
                }
                continue;
            }
            result.append(initialsOnly ? pinyin[0].charAt(0) : pinyin[0]);
        }
        return result.toString();
    }

    private static boolean contains(String value, String normalizedKeyword) {
        return value != null && normalize(value).contains(normalizedKeyword);
    }

    private static String normalize(String value) {
        return Objects.requireNonNullElse(value, "")
                .replaceAll("\\s+", "")
                .toLowerCase(Locale.ROOT);
    }

    private static HanyuPinyinOutputFormat createPinyinFormat() {
        HanyuPinyinOutputFormat format = new HanyuPinyinOutputFormat();
        format.setCaseType(HanyuPinyinCaseType.LOWERCASE);
        format.setToneType(HanyuPinyinToneType.WITHOUT_TONE);
        format.setVCharType(HanyuPinyinVCharType.WITH_V);
        return format;
    }
}
