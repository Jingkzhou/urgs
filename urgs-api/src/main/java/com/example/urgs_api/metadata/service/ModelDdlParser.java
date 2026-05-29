package com.example.urgs_api.metadata.service;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * 解析物理表 DDL。当前先支持星环 Inceptor/Hive 风格 CREATE TABLE。
 */
@Component
public class ModelDdlParser {

    private static final Pattern CREATE_TABLE_PATTERN = Pattern.compile(
            "(?is)\\bCREATE\\s+(?:EXTERNAL\\s+)?TABLE\\s+(?:IF\\s+NOT\\s+EXISTS\\s+)?([^\\s(]+)\\s*\\(");
    private static final Pattern TABLE_COMMENT_PATTERN = Pattern.compile("(?is)\\)\\s*COMMENT\\s+('(?:''|[^'])*'|\"(?:\"\"|[^\"])*\")");
    private static final Pattern COLUMN_COMMENT_PATTERN = Pattern.compile("(?is)\\bCOMMENT\\s+('(?:''|[^'])*'|\"(?:\"\"|[^\"])*\")");
    private static final Pattern PARTITIONED_BY_PATTERN = Pattern.compile("(?is)\\bPARTITIONED\\s+BY\\s*\\(");
    private static final Pattern PRIMARY_KEY_PATTERN = Pattern.compile("(?is)\\bPRIMARY\\s+KEY\\s*\\(([^)]*)\\)");

    public List<DdlTable> parse(String ddl, String defaultOwner, String language) {
        if (ddl == null || ddl.isBlank()) {
            throw new IllegalArgumentException("DDL 内容不能为空");
        }
        if (!isInceptorLanguage(language)) {
            throw new IllegalArgumentException("当前仅支持星环 Inceptor DDL 导入");
        }

        String normalized = removeComments(ddl);
        List<String> statements = splitStatements(normalized);
        List<DdlTable> tables = new ArrayList<>();
        for (String statement : statements) {
            DdlTable table = parseCreateTable(statement, defaultOwner);
            if (table != null) {
                tables.add(table);
            }
        }
        if (tables.isEmpty()) {
            throw new IllegalArgumentException("未识别到 CREATE TABLE 语句");
        }
        return tables;
    }

    private boolean isInceptorLanguage(String language) {
        return language != null && language.toLowerCase(Locale.ROOT).contains("inceptor");
    }

    private DdlTable parseCreateTable(String statement, String defaultOwner) {
        Matcher matcher = CREATE_TABLE_PATTERN.matcher(statement);
        if (!matcher.find()) {
            return null;
        }

        String qualifiedName = cleanIdentifier(matcher.group(1));
        String[] nameParts = splitQualifiedName(qualifiedName);
        String owner = nameParts.length > 1 ? nameParts[nameParts.length - 2] : defaultOwner;
        String tableName = nameParts[nameParts.length - 1];
        if (owner == null || owner.isBlank()) {
            owner = "default";
        }

        int columnStart = statement.indexOf('(', matcher.end() - 1);
        int columnEnd = findMatchingParen(statement, columnStart);
        if (columnStart < 0 || columnEnd < 0) {
            throw new IllegalArgumentException("表 " + tableName + " 的字段括号不完整");
        }

        DdlTable table = new DdlTable();
        table.setName(tableName);
        table.setOwner(cleanIdentifier(owner));
        table.setComment(parseTableComment(statement.substring(columnEnd)));

        String columnBlock = statement.substring(columnStart + 1, columnEnd);
        Set<String> pkColumns = collectPrimaryKeys(columnBlock);
        table.getFields().addAll(parseColumns(columnBlock, pkColumns, false));

        Matcher partitionMatcher = PARTITIONED_BY_PATTERN.matcher(statement);
        if (partitionMatcher.find(columnEnd)) {
            int partitionStart = statement.indexOf('(', partitionMatcher.end() - 1);
            int partitionEnd = findMatchingParen(statement, partitionStart);
            if (partitionStart >= 0 && partitionEnd > partitionStart) {
                table.getFields().addAll(parseColumns(statement.substring(partitionStart + 1, partitionEnd), pkColumns, true));
            }
        }

        return table;
    }

    private String parseTableComment(String tail) {
        Matcher matcher = TABLE_COMMENT_PATTERN.matcher(tail);
        return matcher.find() ? unquote(matcher.group(1)) : null;
    }

    private Set<String> collectPrimaryKeys(String columnBlock) {
        Set<String> pkColumns = new HashSet<>();
        Matcher matcher = PRIMARY_KEY_PATTERN.matcher(columnBlock);
        while (matcher.find()) {
            for (String name : splitTopLevel(matcher.group(1), ',')) {
                String cleaned = cleanIdentifier(name.trim());
                if (!cleaned.isBlank()) {
                    pkColumns.add(cleaned.toLowerCase(Locale.ROOT));
                }
            }
        }
        return pkColumns;
    }

    private List<DdlField> parseColumns(String columnBlock, Set<String> pkColumns, boolean partitionField) {
        List<DdlField> fields = new ArrayList<>();
        for (String rawDefinition : splitTopLevel(columnBlock, ',')) {
            String definition = rawDefinition.trim();
            if (definition.isBlank() || isConstraintDefinition(definition)) {
                continue;
            }
            DdlField field = parseColumnDefinition(definition, pkColumns, partitionField);
            if (field != null) {
                field.setSortOrder(fields.size() + 1);
                fields.add(field);
            }
        }
        return fields;
    }

    private DdlField parseColumnDefinition(String definition, Set<String> pkColumns, boolean partitionField) {
        int nameEnd = readIdentifierEnd(definition, 0);
        if (nameEnd <= 0) {
            return null;
        }
        String name = cleanIdentifier(definition.substring(0, nameEnd));
        String rest = definition.substring(nameEnd).trim();
        if (name.isBlank() || rest.isBlank()) {
            return null;
        }

        Matcher commentMatcher = COLUMN_COMMENT_PATTERN.matcher(rest);
        int typeEnd = commentMatcher.find() ? commentMatcher.start() : rest.length();
        String beforeComment = rest.substring(0, typeEnd).trim();
        String comment = commentMatcher.find(0) ? unquote(commentMatcher.group(1)) : null;

        String type = extractType(beforeComment);
        if (type.isBlank()) {
            return null;
        }

        DdlField field = new DdlField();
        field.setName(name);
        field.setType(type);
        field.setComment(comment);
        field.setPrimaryKey(pkColumns.contains(name.toLowerCase(Locale.ROOT)));
        field.setNullable(!beforeComment.toLowerCase(Locale.ROOT).contains("not null"));
        field.setPartitionField(partitionField);
        return field;
    }

    private String extractType(String definitionWithoutComment) {
        String lower = definitionWithoutComment.toLowerCase(Locale.ROOT);
        int end = definitionWithoutComment.length();
        for (String marker : List.of(" not null", " null", " default ", " primary key", " constraint ", " encode ", " compress ")) {
            int index = lower.indexOf(marker);
            if (index >= 0) {
                end = Math.min(end, index);
            }
        }
        return definitionWithoutComment.substring(0, end).trim();
    }

    private boolean isConstraintDefinition(String definition) {
        String lower = definition.toLowerCase(Locale.ROOT);
        return lower.startsWith("primary key")
                || lower.startsWith("constraint ")
                || lower.startsWith("unique ")
                || lower.startsWith("key ")
                || lower.startsWith("index ");
    }

    private int readIdentifierEnd(String text, int start) {
        int index = start;
        if (index < text.length() && (text.charAt(index) == '`' || text.charAt(index) == '"' || text.charAt(index) == '\'')) {
            char quote = text.charAt(index++);
            while (index < text.length() && text.charAt(index) != quote) {
                index++;
            }
            return index < text.length() ? index + 1 : index;
        }
        while (index < text.length() && !Character.isWhitespace(text.charAt(index))) {
            index++;
        }
        return index;
    }

    private int findMatchingParen(String text, int openIndex) {
        if (openIndex < 0 || openIndex >= text.length() || text.charAt(openIndex) != '(') {
            return -1;
        }
        int depth = 0;
        Character quote = null;
        for (int i = openIndex; i < text.length(); i++) {
            char c = text.charAt(i);
            if (quote != null) {
                if (c == quote) {
                    if (i + 1 < text.length() && text.charAt(i + 1) == quote) {
                        i++;
                    } else {
                        quote = null;
                    }
                }
                continue;
            }
            if (c == '\'' || c == '"' || c == '`') {
                quote = c;
                continue;
            }
            if (c == '(') {
                depth++;
            } else if (c == ')') {
                depth--;
                if (depth == 0) {
                    return i;
                }
            }
        }
        return -1;
    }

    private List<String> splitStatements(String ddl) {
        return splitTopLevel(ddl, ';').stream()
                .map(String::trim)
                .filter(item -> !item.isBlank())
                .toList();
    }

    private List<String> splitTopLevel(String text, char delimiter) {
        List<String> parts = new ArrayList<>();
        int start = 0;
        int parenDepth = 0;
        int angleDepth = 0;
        Character quote = null;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (quote != null) {
                if (c == quote) {
                    if (i + 1 < text.length() && text.charAt(i + 1) == quote) {
                        i++;
                    } else {
                        quote = null;
                    }
                }
                continue;
            }
            if (c == '\'' || c == '"' || c == '`') {
                quote = c;
                continue;
            }
            if (c == '(') {
                parenDepth++;
            } else if (c == ')' && parenDepth > 0) {
                parenDepth--;
            } else if (c == '<') {
                angleDepth++;
            } else if (c == '>' && angleDepth > 0) {
                angleDepth--;
            } else if (c == delimiter && parenDepth == 0 && angleDepth == 0) {
                parts.add(text.substring(start, i));
                start = i + 1;
            }
        }
        parts.add(text.substring(start));
        return parts;
    }

    private String removeComments(String ddl) {
        StringBuilder builder = new StringBuilder();
        Character quote = null;
        for (int i = 0; i < ddl.length(); i++) {
            char c = ddl.charAt(i);
            if (quote != null) {
                builder.append(c);
                if (c == quote) {
                    if (i + 1 < ddl.length() && ddl.charAt(i + 1) == quote) {
                        builder.append(ddl.charAt(++i));
                    } else {
                        quote = null;
                    }
                }
                continue;
            }
            if (c == '\'' || c == '"' || c == '`') {
                quote = c;
                builder.append(c);
                continue;
            }
            if (c == '-' && i + 1 < ddl.length() && ddl.charAt(i + 1) == '-') {
                while (i < ddl.length() && ddl.charAt(i) != '\n') {
                    i++;
                }
                builder.append('\n');
                continue;
            }
            if (c == '/' && i + 1 < ddl.length() && ddl.charAt(i + 1) == '*') {
                i += 2;
                while (i + 1 < ddl.length() && !(ddl.charAt(i) == '*' && ddl.charAt(i + 1) == '/')) {
                    i++;
                }
                i++;
                builder.append(' ');
                continue;
            }
            builder.append(c);
        }
        return builder.toString();
    }

    private String[] splitQualifiedName(String qualifiedName) {
        List<String> parts = splitTopLevel(qualifiedName, '.').stream()
                .map(this::cleanIdentifier)
                .filter(item -> !item.isBlank())
                .toList();
        return parts.toArray(new String[0]);
    }

    private String cleanIdentifier(String identifier) {
        String value = identifier == null ? "" : identifier.trim();
        if (value.length() >= 2) {
            char first = value.charAt(0);
            char last = value.charAt(value.length() - 1);
            if ((first == '`' && last == '`') || (first == '"' && last == '"') || (first == '\'' && last == '\'')) {
                value = value.substring(1, value.length() - 1);
            }
        }
        return value.trim();
    }

    private String unquote(String text) {
        String value = cleanIdentifier(text);
        return value.replace("''", "'").replace("\"\"", "\"");
    }

    public static class DdlTable {
        private String owner;
        private String name;
        private String comment;
        private final List<DdlField> fields = new ArrayList<>();

        public String getOwner() {
            return owner;
        }

        public void setOwner(String owner) {
            this.owner = owner;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getComment() {
            return comment;
        }

        public void setComment(String comment) {
            this.comment = comment;
        }

        public List<DdlField> getFields() {
            return fields;
        }
    }

    public static class DdlField {
        private String name;
        private String type;
        private String comment;
        private boolean primaryKey;
        private boolean nullable;
        private boolean partitionField;
        private int sortOrder;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        public String getComment() {
            return comment;
        }

        public void setComment(String comment) {
            this.comment = comment;
        }

        public boolean isPrimaryKey() {
            return primaryKey;
        }

        public void setPrimaryKey(boolean primaryKey) {
            this.primaryKey = primaryKey;
        }

        public boolean isNullable() {
            return nullable;
        }

        public void setNullable(boolean nullable) {
            this.nullable = nullable;
        }

        public boolean isPartitionField() {
            return partitionField;
        }

        public void setPartitionField(boolean partitionField) {
            this.partitionField = partitionField;
        }

        public int getSortOrder() {
            return sortOrder;
        }

        public void setSortOrder(int sortOrder) {
            this.sortOrder = sortOrder;
        }
    }
}
