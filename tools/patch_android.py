"""Донастраивает Android-часть, созданную `flutter create`:
иконки, разрешения, уведомления, подпись релиза."""
import pathlib
import re
import shutil
import sys

root = pathlib.Path('.')
android = root / 'android'
main = android / 'app' / 'src' / 'main'


def fail(msg):
    print('ОШИБКА ПАТЧА:', msg)
    sys.exit(1)


# 1. Иконки и ресурсы
shutil.copytree(root / 'android_overrides' / 'res', main / 'res', dirs_exist_ok=True)

# 2. AndroidManifest
mf = main / 'AndroidManifest.xml'
s = mf.read_text(encoding='utf-8')
if '<application' not in s or '</application>' not in s:
    fail('в AndroidManifest нет <application>')

perms = '''    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />
'''
receivers = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
'''
s = s.replace('<application', perms + '    <application', 1)
s, n = re.subn(r'android:label="[^"]*"', 'android:label="История ЦТ"', s, count=1)
if n != 1:
    fail('не нашёл android:label')
s = s.replace('</application>', receivers + '    </application>', 1)
mf.write_text(s, encoding='utf-8')

# 3. build.gradle приложения
g = android / 'app' / 'build.gradle'
if not g.exists():
    fail('нет android/app/build.gradle (ожидался Groovy-шаблон Flutter 3.27)')
t = g.read_text(encoding='utf-8')

t, n = re.subn(r'compileOptions\s*\{', 'compileOptions {\n        coreLibraryDesugaringEnabled true', t, count=1)
if n != 1:
    fail('не нашёл compileOptions')

signing = '''signingConfigs {
        release {
            storeFile file("../../keystore/release.jks")
            storePassword "cthistory123"
            keyAlias "cthistory"
            keyPassword "cthistory123"
        }
    }

    buildTypes {'''
t, n = re.subn(r'buildTypes\s*\{', signing, t, count=1)
if n != 1:
    fail('не нашёл buildTypes')

t, n = re.subn(r'signingConfig\s*=?\s*signingConfigs\.debug', 'signingConfig = signingConfigs.release', t)
if n < 1:
    fail('не нашёл signingConfig debug')

t += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
g.write_text(t, encoding='utf-8')
print('Android-патч применён')
