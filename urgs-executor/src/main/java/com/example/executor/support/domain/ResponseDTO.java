package com.example.executor.support.domain;

import lombok.Data;

@Data
public class ResponseDTO<T> {
    private boolean success;
    private Integer code;
    private String msg;
    private T data;

    public static <T> ResponseDTO<T> succ() {
        ResponseDTO<T> r = new ResponseDTO<>();
        r.setSuccess(true);
        r.setCode(0);
        r.setMsg("success");
        return r;
    }

    public static <T> ResponseDTO<T> succData(T data) {
        ResponseDTO<T> r = succ();
        r.setData(data);
        return r;
    }

    public static <T> ResponseDTO<T> wrap(Integer code, String msg) {
        ResponseDTO<T> r = new ResponseDTO<>();
        r.setSuccess(false);
        r.setCode(code);
        r.setMsg(msg);
        return r;
    }
}
