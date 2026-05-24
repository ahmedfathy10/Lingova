param(
  [string]$ApiBaseUrl = "https://lingova-production.up.railway.app",
  [string]$InstallerName = "LingovaSetup.exe"
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$ReleaseDir = Join-Path $Root "build\windows\x64\runner\Release"
$DistDir = Join-Path $Root "dist"
$StageDir = Join-Path $env:TEMP "lingova_windows_installer"
$PayloadZip = Join-Path $StageDir "lingova_payload.zip"
$InstallerSource = Join-Path $StageDir "LingovaSetup.cs"
$TargetInstaller = Join-Path $DistDir $InstallerName

if (Test-Path $StageDir) {
  Remove-Item -LiteralPath $StageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $DistDir, $StageDir | Out-Null

$runningApps = Get-Process -Name "lingova_app" -ErrorAction SilentlyContinue
if ($runningApps) {
  $runningApps | Stop-Process -Force
  Start-Sleep -Seconds 1
}

$runningInstallers = Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($InstallerName)) -ErrorAction SilentlyContinue
if ($runningInstallers) {
  $runningInstallers | Stop-Process -Force
  Start-Sleep -Seconds 1
}

Push-Location $Root
try {
  flutter build windows --release -t lib/main_app.dart --dart-define="API_BASE_URL=$ApiBaseUrl"
  if ($LASTEXITCODE -ne 0) {
    throw "flutter build failed with exit code $LASTEXITCODE"
  }
} finally {
  Pop-Location
}

if (Test-Path $PayloadZip) {
  Remove-Item -LiteralPath $PayloadZip -Force
}

Compress-Archive -Path (Join-Path $ReleaseDir "*") -DestinationPath $PayloadZip -Force

@'
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;

internal static class LingovaSetup
{
    [STAThread]
    private static int Main()
    {
        try
        {
            string installDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Programs",
                "Lingova");
            string startMenuDir = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "Microsoft",
                "Windows",
                "Start Menu",
                "Programs",
                "Lingova");
            string desktopLink = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),
                "Lingova.lnk");
            string startMenuLink = Path.Combine(startMenuDir, "Lingova.lnk");
            string exePath = Path.Combine(installDir, "lingova_app.exe");
            string tempZip = Path.Combine(Path.GetTempPath(), "lingova_payload_" + Guid.NewGuid().ToString("N") + ".zip");

            foreach (Process process in Process.GetProcessesByName("lingova_app"))
            {
                try
                {
                    process.Kill();
                    process.WaitForExit(5000);
                }
                catch
                {
                }
            }

            Directory.CreateDirectory(installDir);
            Directory.CreateDirectory(startMenuDir);

            using (Stream payload = Assembly.GetExecutingAssembly().GetManifestResourceStream("LingovaPayload"))
            {
                if (payload == null)
                {
                    throw new InvalidOperationException("Installer payload is missing.");
                }

                using (FileStream output = File.Create(tempZip))
                {
                    payload.CopyTo(output);
                }
            }

            if (Directory.Exists(installDir))
            {
                Directory.Delete(installDir, true);
            }

            Directory.CreateDirectory(installDir);
            ZipFile.ExtractToDirectory(tempZip, installDir);
            File.Delete(tempZip);

            CreateShortcut(desktopLink, exePath, installDir);
            CreateShortcut(startMenuLink, exePath, installDir);

            Process.Start(exePath);
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "Lingova could not be installed.\r\n\r\n" + ex.Message,
                "Lingova Setup",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
    }

    private static void CreateShortcut(string shortcutPath, string targetPath, string workingDirectory)
    {
        Type shellType = Type.GetTypeFromProgID("WScript.Shell");
        object shell = Activator.CreateInstance(shellType);
        object shortcut = shellType.InvokeMember(
            "CreateShortcut",
            BindingFlags.InvokeMethod,
            null,
            shell,
            new object[] { shortcutPath });
        Type shortcutType = shortcut.GetType();

        shortcutType.InvokeMember("TargetPath", BindingFlags.SetProperty, null, shortcut, new object[] { targetPath });
        shortcutType.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, shortcut, new object[] { workingDirectory });
        shortcutType.InvokeMember("IconLocation", BindingFlags.SetProperty, null, shortcut, new object[] { targetPath + ",0" });
        shortcutType.InvokeMember("Save", BindingFlags.InvokeMethod, null, shortcut, null);
    }
}
'@ | Set-Content -Path $InstallerSource -Encoding UTF8

$csc = Get-ChildItem "$env:WINDIR\Microsoft.NET\Framework64" -Recurse -Filter csc.exe -ErrorAction SilentlyContinue |
  Sort-Object FullName -Descending |
  Select-Object -First 1
if (-not $csc) {
  $csc = Get-ChildItem "$env:WINDIR\Microsoft.NET\Framework" -Recurse -Filter csc.exe -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending |
    Select-Object -First 1
}
if (-not $csc) {
  throw "Could not find csc.exe to build the installer."
}

if (Test-Path $TargetInstaller) {
  Remove-Item -LiteralPath $TargetInstaller -Force
}

& $csc.FullName `
  /nologo `
  /target:winexe `
  /optimize+ `
  /platform:anycpu `
  "/win32icon:$(Join-Path $Root 'windows\runner\resources\app_icon.ico')" `
  "/out:$TargetInstaller" `
  "/resource:$PayloadZip,LingovaPayload" `
  /reference:System.IO.Compression.dll `
  /reference:System.IO.Compression.FileSystem.dll `
  /reference:System.Windows.Forms.dll `
  $InstallerSource
if ($LASTEXITCODE -ne 0) {
  throw "Installer compile failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path $TargetInstaller)) {
  throw "Installer was not created: $TargetInstaller"
  }
Write-Host "Created installer: $TargetInstaller"
