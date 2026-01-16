package com.example.executor.urgs_executor.util;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class PlaceholderUtils {

    private static final Pattern DATA_DATE_PATTERN = Pattern.compile("\\$datadate", Pattern.CASE_INSENSITIVE);

    private PlaceholderUtils() {
    }

    public static String replaceDataDate(String input, String dataDate) {
        if (input == null) {
            return null;
        }
        if (dataDate == null) {
            dataDate = "";
        }
        return DATA_DATE_PATTERN.matcher(input).replaceAll(Matcher.quoteReplacement(dataDate));
    }
}
