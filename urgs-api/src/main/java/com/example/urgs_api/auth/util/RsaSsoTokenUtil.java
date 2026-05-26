package com.example.urgs_api.auth.util;

import javax.crypto.Cipher;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;

public final class RsaSsoTokenUtil {

    private static final String RSA_TRANSFORMATION = "RSA/ECB/PKCS1Padding";
    private static final int RSA_BLOCK_LENGTH = 256;

    private RsaSsoTokenUtil() {
    }

    public static String decryptFromBase64(String encryptedText, String privateKeyText) {
        if (encryptedText == null || encryptedText.isBlank()) {
            throw new IllegalArgumentException("ssoToken 不能为空");
        }
        if (privateKeyText == null || privateKeyText.isBlank()) {
            throw new IllegalArgumentException("RSA 私钥未配置");
        }

        try {
            PrivateKey privateKey = parsePrivateKey(privateKeyText);
            Cipher cipher = Cipher.getInstance(RSA_TRANSFORMATION);
            cipher.init(Cipher.DECRYPT_MODE, privateKey);
            byte[] encryptedBytes = Base64.getDecoder().decode(encryptedText);
            return new String(decryptByFragment(encryptedBytes, cipher), StandardCharsets.UTF_8).trim();
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("RSA 免登录 Token 解密失败", e);
        }
    }

    private static PrivateKey parsePrivateKey(String privateKeyText) throws Exception {
        String normalized = privateKeyText
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] keyBytes = Base64.getDecoder().decode(normalized);
        PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(keyBytes);
        return KeyFactory.getInstance("RSA").generatePrivate(keySpec);
    }

    private static byte[] decryptByFragment(byte[] data, Cipher cipher) throws Exception {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        for (int offset = 0; offset < data.length; offset += RSA_BLOCK_LENGTH) {
            int length = Math.min(RSA_BLOCK_LENGTH, data.length - offset);
            output.write(cipher.doFinal(data, offset, length));
        }
        return output.toByteArray();
    }
}
