package com.example.urgs_api.user.support;

import com.example.urgs_api.user.model.User;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UserSearchMatcherTest {

    @Test
    void matchesChineseNameByFullPinyinAndInitials() {
        User user = new User();
        user.setName("张三");
        user.setEmpId("1001");

        assertThat(UserSearchMatcher.matches(user, "zhangsan")).isTrue();
        assertThat(UserSearchMatcher.matches(user, "ZS")).isTrue();
        assertThat(UserSearchMatcher.matches(user, "李四")).isFalse();
    }

    @Test
    void keepsExistingNameAndEmployeeIdMatching() {
        User user = new User();
        user.setName("张三");
        user.setEmpId("A1001");

        assertThat(UserSearchMatcher.matches(user, "张")).isTrue();
        assertThat(UserSearchMatcher.matches(user, "a100")).isTrue();
    }
}
