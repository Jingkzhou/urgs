package com.example.executor.urgs_executor.util;

import org.quartz.CronExpression;
import java.text.ParseException;
import java.util.Date;

public class CronUtils {

    public static boolean isValid(String cronExpression) {
        return CronExpression.isValidExpression(cronExpression);
    }

    public static Date getNextExecution(String cronExpression, Date lastExecution) {
        try {
            CronExpression cron = new CronExpression(cronExpression);
            return cron.getNextValidTimeAfter(lastExecution != null ? lastExecution : new Date());
        } catch (ParseException e) {
            e.printStackTrace();
            return null;
        }
    }
}
