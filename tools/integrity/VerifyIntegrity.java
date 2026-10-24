/*
 * VerifyIntegrity.java —— 校验 APK 自洽性
 */
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.Arrays;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class VerifyIntegrity {

    static final String SALT = "heci-toolbox-2026-gcm-v2";
    static final String SMALI = "smali/com/yazi/toolbox/MainActivity.smali";

    static byte[] deriveKey(String pw) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] h = md.digest((pw + "|" + SALT).getBytes(StandardCharsets.UTF_8));
        for (int i = 0; i < 4096; i++) {
            h = md.digest(h);
        }
        return h;
    }

    static String hex(byte[] b) {
        StringBuilder sb = new StringBuilder();
        for (byte x : b) {
            sb.append(String.format("%02x", x));
        }
        return sb.toString();
    }

    static byte[] entry(ZipFile zf, String name) throws Exception {
        ZipEntry e = zf.getEntry(name);
        if (e == null) return null;
        try (InputStream in = zf.getInputStream(e)) {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            byte[] buf = new byte[1 << 16];
            int n;
            while ((n = in.read(buf)) > 0) {
                bos.write(buf, 0, n);
            }
            return bos.toByteArray();
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.out.println("用法: java VerifyIntegrity.java <apk 路径>");
            System.exit(2);
        }
        Path apk = Paths.get(args[0]).toAbsolutePath();
        Path here = Paths.get("").toAbsolutePath();
        Path smali = here.resolve(SMALI);
        if (!Files.isRegularFile(smali)) {
            System.out.println("找不到 " + smali + "（请在工程根目录下运行本工具，或先解包 APK）");
            System.exit(2);
        }
        String src = new String(Files.readAllBytes(smali), StandardCharsets.UTF_8);
        Matcher m = Pattern.compile("\\.method private signSha256\\(\\)Ljava/lang/String;(.*?)\\.end method", Pattern.DOTALL).matcher(src);
        if (!m.find()) {
            System.out.println("在 smali 里找不到 signSha256()");
            System.exit(2);
        }
        Matcher c = Pattern.compile("const-string v0, \"([^\"]+)\"").matcher(m.group(1));
        if (!c.find()) {
            System.out.println("signSha256() 里找不到 const-string");
            System.exit(2);
        }
        String pw = c.group(1);

        String dexHash;
        byte[] blob;
        try (ZipFile zf = new ZipFile(apk.toFile())) {
            byte[] dex = entry(zf, "classes.dex");
            if (dex == null) {
                System.out.println("APK 里���有 classes.dex");
                System.exit(2);
                return;
            }
            dexHash = hex(MessageDigest.getInstance("SHA-256").digest(dex));
            blob = entry(zf, "assets/integrity.bin");
        }
        System.out.println("APK         : " + apk);
        System.out.println("classes.dex : " + dexHash);
        if (blob == null || blob.length < 13) {
            System.out.println("结果        : 包内没有 integrity.bin（或长度不合法）");
            System.exit(1);
        }
        byte[] iv = Arrays.copyOfRange(blob, 0, 12);
        byte[] rest = Arrays.copyOfRange(blob, 12, blob.length);
        String expect;
        try {
            Cipher cp = Cipher.getInstance("AES/GCM/NoPadding");
            cp.init(Cipher.DECRYPT_MODE, new SecretKeySpec(deriveKey(pw), "AES"), new GCMParameterSpec(128, iv));
            expect = new String(cp.doFinal(rest), StandardCharsets.UTF_8).trim();
        } catch (Exception e) {
            System.out.println("结果        : integrity.bin 解密失败（口令与加密时不一致）：" + e);
            System.exit(1);
            return;
        }
        System.out.println("integrity   : " + expect);
        if (expect.equals(dexHash)) {
            System.out.println("结果        : 一致 ✔（期望哈希与本次构建的 dex 对齐）");
            System.exit(0);
        } else {
            System.out.println("结果        : 不一致 ✘（改过 smali 后请重跑 RegenIntegrity.java 再打包）");
            System.exit(1);
        }
    }
}
