#!/usr/bin/env bash
set -e

WORKDIR="$HOME/njm_2_ekosustav_01"
cd "$WORKDIR"

echo "================================================================="
echo "  e-spis_RUKE — NATIVNI ANDROID APK GRADITELJ (Zajednica RUKE)"
echo "================================================================="

# 1. Osigurati postojanje najnovije offline HTML aplikacije
if [ ! -f "Zajednica_RUKE_eSpis.html" ]; then
    echo "📦 Generiranje prenosive offline aplikacije..."
    ./napravi_offline_app
fi

# Fleksibilno pronalaženje android.jar bilo gdje u Termuxu
ANDROID_JAR=$(find "$PREFIX" -name "android.jar" | head -n 1)

if [ -z "$ANDROID_JAR" ]; then
    echo "⚠️ [UPOZORENJE] android.jar nije pronađen. Pokušavam preuzeti osnovni SDK paket..."
    pkg install android-platforms -y || true
    ANDROID_JAR=$(find "$PREFIX" -name "android.jar" | head -n 1)
fi

if [ -n "$ANDROID_JAR" ]; then
    echo "📍 Pronađen Android SDK JAR: $ANDROID_JAR"
    JAVAC_BOOT="-bootclasspath $ANDROID_JAR"
    AAPT_JAR="-I $ANDROID_JAR"
else
    echo "⚠️ [UPOZORENJE] android.jar i dalje nije dostupan. Kompajliram u standardnom Java modu..."
    JAVAC_BOOT=""
    AAPT_JAR=""
fi

# 2. Priprema strukture Android projekta
APP_DIR="android_build"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/app/src/main/assets"
mkdir -p "$APP_DIR/app/src/main/java/hr/zajednicaruke/espis"
mkdir -p "$APP_DIR/app/src/main/res/values"

# Prekopirati HTML aplikaciju u assets
cp Zajednica_RUKE_eSpis.html "$APP_DIR/app/src/main/assets/index.html"

# 3. Kreiranje AndroidManifest.xml
cat << 'MANIFEST' > "$APP_DIR/app/src/main/AndroidManifest.xml"
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="hr.zajednicaruke.espis"
    android:versionCode="1"
    android:versionName="1.0">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:label="Zajednica RUKE e-Spis"
        android:supportsRtl="true"
        android:theme="@android:style/Theme.NoTitleBar">

        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST

# 4. Kreiranje MainActivity.java (WebView pokretač)
cat << 'JAVA' > "$APP_DIR/app/src/main/java/hr/zajednicaruke/espis/MainActivity.java"
package hr.zajednicaruke.espis;

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

public class MainActivity extends Activity {
    private WebView myWebView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        myWebView = new WebView(this);
        WebSettings webSettings = myWebView.getSettings();
        webSettings.setJavaScriptEnabled(true);
        webSettings.setDomStorageEnabled(true);
        webSettings.setAllowFileAccess(true);

        myWebView.setWebViewClient(new WebViewClient());
        myWebView.loadUrl("file:///android_asset/index.html");

        setContentView(myWebView);
    }

    @Override
    public void onBackPressed() {
        if (myWebView.canGoBack()) {
            myWebView.goBack();
        } else {
            super.onBackPressed();
        }
    }
}
JAVA

echo "⚙️ Kompajliranje Java izvornog koda..."
cd "$APP_DIR/app/src/main/java"
if [ -n "$ANDROID_JAR" ]; then
    javac -source 1.8 -target 1.8 -bootclasspath "$ANDROID_JAR" hr/zajednicaruke/espis/MainActivity.java
else
    javac -source 1.8 -target 1.8 hr/zajednicaruke/espis/MainActivity.java
fi
cd "$WORKDIR"

echo "⚙️ Pretvaranje u .dex (Dalvik Executable)..."
mkdir -p "$APP_DIR/build"
d8 --output "$APP_DIR/build" "$APP_DIR/app/src/main/java/hr/zajednicaruke/espis/MainActivity.class" 2>/dev/null || \
dx --dex --output="$APP_DIR/build/classes.dex" "$APP_DIR/app/src/main/java/hr/zajednicaruke/espis/MainActivity.class" 2>/dev/null || true

echo "📦 Pakiranje resursa i assetsa preko AAPT..."
aapt package -f -M "$APP_DIR/app/src/main/AndroidManifest.xml" \
    -A "$APP_DIR/app/src/main/assets" \
    $AAPT_JAR \
    -F "$APP_DIR/build/unaligned.apk" 2>/dev/null || \
aapt package -f -M "$APP_DIR/app/src/main/AndroidManifest.xml" \
    -A "$APP_DIR/app/src/main/assets" \
    -F "$APP_DIR/build/unaligned.apk"

# Dodavanje classes.dex u APK
cd "$APP_DIR/build"
zip -u unaligned.apk classes.dex
cd "$WORKDIR"

echo "🔑 Generiranje razvojnog ključa i potpisivanje APK-a..."
if [ ! -f "zajednicaruke.keystore" ]; then
    keytool -genkey -v -keystore zajednicaruke.keystore -alias rukeKey \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Zajednica RUKE, OU=e-Spis, O=Zajednica RUKE, L=Zagreb, C=HR" \
        -storepass ruke1234 -keypass ruke1234 2>/dev/null || true
fi

# Potpisivanje
apksigner sign --ks zajednicaruke.keystore \
    --ks-pass pass:ruke1234 \
    --key-pass pass:ruke1234 \
    --out "Zajednica_RUKE_eSpis.apk" \
    "$APP_DIR/build/unaligned.apk"

echo "================================================================="
echo "✅ ANDROID APK JE USPJEŠNO IZGRAĐEN I POTPISAN!"
echo "   Datoteka: Zajednica_RUKE_eSpis.apk"
echo "   Sada možete instalirati aplikaciju na mobitel ili je poslati članovima!"
echo "================================================================="
