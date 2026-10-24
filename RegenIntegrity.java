/*
 * RegenIntegrity.java —— 重新生成 assets/integrity.bin
 *
 * 背景：MainActivity 里的「完整性校验」用 integrity.bin 存一份「期望的 classes.dex SHA-256」，
 * 密文用 AES-GCM 加密，密钥 = 迭代 SHA-256(口令 + "|" + KEY_SALT)。
 * 口令来自 MainActivity.signSha256() 的常量（注意：它的名字有误导性，实际不是证书指纹）。
 *
 * 由于 apktool 重打包是确定性的，只要 smali 不变，classes.dex 的哈希就不变；
 * 因此每次改完 smali、重新打包之后，用本工具把 integrity.bin 重新生成一次，
 * 即可让「期望哈希」与当前构建一致（否则一旦启用 tampered() 真实比较，App 会自锁）。
 *
 * 用法（JDK 11+，单文件直接运行）：
 *     java RegenIntegrity.java <apk 路径> [输出 integrity.bin 路径]
 * 默认输出：与本脚本同目录的 assets/integrity.bin
 */
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class RegenIntegrity {

    static final String SALT = "heci-toolbox-2026-gcm-v2";
    static final String SMALI = "smali/com/yazi/toolbox/MainActivity.smali";

    /** 复刻 deriveKey()：SHA-256(pw + "|" + SALT) 之后再迭代 4096 次（共 4097 次） */
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

    /** 从 smali 里取 signSha256() 的常量，保证口令与代码同步 */
    static String readPassphrase(Path smali) throws Exception {
        String src = new String(Files.readAllBytes(smali), StandardCharsets.UTF_8);
        Matcher m = Pattern.compile(
                "\\.method private signSha256\\(\\)Ljava/lang/String;(.*?)\\.end method",
                Pattern.DOTALL).matcher(src);
        if (!m.find()) {
            throw new IllegalStateException("在 " + smali + " 里找不到 signSha256()");
        }
        Matcher c = Pattern.compile("const-string v0, \"([^\"]+)\"").matcher(m.group(1));
        if (!c.find()) {
            throw new IllegalStateException("signSha256() 里找不到 const-string");
        }
        return c.group(1);
    }

    static String dexSha256(Path apk) throws Exception {
        try (ZipFile zf = new ZipFile(apk.toFile())) {
            ZipEntry e = zf.getEntry("classes.dex");
            if (e == null) {
                throw new IllegalStateException("APK 里没有 classes.dex: " + apk);
            }
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (InputStream in = zf.getInputStream(e)) {
                byte[] buf = new byte[1 << 16];
                int n;
                while ((n = in.read(buf)) > 0) {
                    md.update(buf, 0, n);
                }
            }
            return hex(md.digest());
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 1) {
            System.out.println("用法: java RegenIntegrity.java <apk 路径> [输出 integrity.bin 路径]");
            System.exit(2);
        }
        Path here = Paths.get("").toAbsolutePath();
        Path apk = Paths.get(args[0]).toAbsolutePath();
        Path out = args.length > 1 ? Paths.get(args[1]).toAbsolutePath()
                                   : here.resolve("assets/integrity.bin");
        Path smali = here.resolve(SMALI);

        String pw = readPassphrase(smali);
        String dexHash = dexSha256(apk);
        System.out.println("APK          : " + apk);
        System.out.println("classes.dex  : " + dexHash);
        System.out.println("口令来源      : signSha256() = " + pw);
        System.out.println("输出          : " + out);

        byte[] key = deriveKey(pw);
        byte[] iv = new byte[12];
        new SecureRandom().nextBytes(iv);
        Cipher c = Cipher.getInstance("AES/GCM/NoPadding");
        c.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(128, iv));
        byte[] ct = c.doFinal(dexHash.getBytes(StandardCharsets.UTF_8));

        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        bos.write(iv);
        bos.write(ct);
        byte[] blob = bos.toByteArray();

        Files.createDirectories(out.getParent());
        Files.write(out, blob);
        System.out.println("已写入 " + blob.length + " 字节（12 字节 IV + " + ct.length + " 字节密文+tag）");
        System.out.println("提示：改完 smali 重新打包后请再跑一次本工具，然后重新打包以把新的 integrity.bin 装进 APK。");
    }
}
