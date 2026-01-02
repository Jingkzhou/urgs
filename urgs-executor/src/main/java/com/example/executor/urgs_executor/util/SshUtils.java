package com.example.executor.urgs_executor.util;

import com.jcraft.jsch.*;
import lombok.extern.slf4j.Slf4j;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.Properties;

@Slf4j
public class SshUtils {

    private static final int TIMEOUT = 30000;

    public static Session connect(String host, int port, String user, String password) throws JSchException {
        JSch jsch = new JSch();
        Session session = jsch.getSession(user, host, port);
        session.setPassword(password);

        Properties config = new Properties();
        config.put("StrictHostKeyChecking", "no");
        session.setConfig(config);
        session.setTimeout(TIMEOUT);
        session.connect();
        return session;
    }

    /**
     * 执行远程命令并获取输出
     */
    public static String exec(Session session, String command) throws Exception {
        if (session == null || !session.isConnected()) {
            throw new IllegalStateException("SSH Session is not connected");
        }

        ChannelExec channel = (ChannelExec) session.openChannel("exec");
        channel.setCommand(command);

        ByteArrayOutputStream responseStream = new ByteArrayOutputStream();
        ByteArrayOutputStream errorStream = new ByteArrayOutputStream();
        channel.setOutputStream(responseStream);
        channel.setErrStream(errorStream);

        channel.connect();

        // 等待命令执行完成
        while (channel.isConnected()) {
            Thread.sleep(100);
        }

        String response = responseStream.toString(StandardCharsets.UTF_8);
        String error = errorStream.toString(StandardCharsets.UTF_8);

        channel.disconnect();

        if (channel.getExitStatus() != 0) {
            throw new RuntimeException(String.format("Execute command failed (Exit Code: %d).\nSTDERR: %s\nSTDOUT: %s",
                    channel.getExitStatus(), error, response));
        }

        return response;
    }

    /**
     * SCP 上传文件内容到远程文件
     */
    public static void scpTo(Session session, String content, String remotePath) throws Exception {
        if (session == null || !session.isConnected()) {
            throw new IllegalStateException("SSH Session is not connected");
        }

        ChannelExec channel = (ChannelExec) session.openChannel("exec");
        String command = "scp -t " + remotePath;
        channel.setCommand(command);

        OutputStream out = channel.getOutputStream();
        InputStream in = channel.getInputStream();

        channel.connect();

        if (checkAck(in) != 0) {
            throw new IOException("SCP CheckAck failed before sending file");
        }

        byte[] bytes = content.getBytes(StandardCharsets.UTF_8);

        // send "C0644 fileSize fileName", where filename should not include '/'
        long filesize = bytes.length;
        command = "C0644 " + filesize + " " + remotePath.substring(remotePath.lastIndexOf('/') + 1) + "\n";
        out.write(command.getBytes());
        out.flush();

        if (checkAck(in) != 0) {
            throw new IOException("SCP CheckAck failed after sending header");
        }

        // send content
        out.write(bytes);
        out.flush();

        // send '\0'
        out.write(0);
        out.flush();

        if (checkAck(in) != 0) {
            throw new IOException("SCP CheckAck failed after sending content");
        }

        out.close();
        channel.disconnect();
    }

    public static int checkAck(InputStream in) throws IOException {
        int b = in.read();
        // b may be 0 for success,
        // 1 for error,
        // 2 for fatal error,
        // -1
        if (b == 0)
            return b;
        if (b == -1)
            return b;

        if (b == 1 || b == 2) {
            StringBuilder sb = new StringBuilder();
            int c;
            do {
                c = in.read();
                sb.append((char) c);
            } while (c != '\n');
            if (b == 1) { // error
                log.error("SCP Remote error: {}", sb.toString());
            }
            if (b == 2) { // fatal error
                log.error("SCP Remote fatal error: {}", sb.toString());
            }
        }
        return b;
    }
}
