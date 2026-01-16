package com.example.urgs_api.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan({
                "com.example.urgs_api.**.mapper",
                "com.example.urgs_api.ai.repository",
                "com.example.urgs_api.workflow.repository",
                "com.example.urgs_api.datasource.repository",
                "com.example.urgs_api.version.audit.mapper"
})
public class MybatisConfig {

        @Bean
        public com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor mybatisPlusInterceptor() {
                com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor interceptor = new com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor();
                interceptor.addInnerInterceptor(
                                new com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor(
                                                com.baomidou.mybatisplus.annotation.DbType.MYSQL));
                return interceptor;
        }

        @Bean
        public org.apache.ibatis.session.SqlSessionFactory sqlSessionFactory(javax.sql.DataSource dataSource,
                        com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor mybatisPlusInterceptor)
                        throws Exception {
                com.baomidou.mybatisplus.extension.spring.MybatisSqlSessionFactoryBean factoryBean = new com.baomidou.mybatisplus.extension.spring.MybatisSqlSessionFactoryBean();
                factoryBean.setDataSource(dataSource);
                factoryBean.setPlugins(mybatisPlusInterceptor);
                factoryBean.setMapperLocations(
                                new org.springframework.core.io.support.PathMatchingResourcePatternResolver()
                                                .getResources("classpath:mapper/*.xml"));
                return factoryBean.getObject();
        }

}
